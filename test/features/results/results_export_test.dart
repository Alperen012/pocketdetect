import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/export/share_service.dart';
import 'package:mobile_yolo/core/models/detected_object.dart';
import 'package:mobile_yolo/core/models/installed_model.dart';
import 'package:mobile_yolo/core/models/resolution_profile.dart';
import 'package:mobile_yolo/core/services/detection_history_service.dart';
import 'package:mobile_yolo/core/services/detection_service.dart';
import 'package:mobile_yolo/core/services/model_library_service.dart';
import 'package:mobile_yolo/core/services/settings_controller.dart';
import 'package:mobile_yolo/features/results/results_screen.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations.dart';
import '../../test_helpers/surface.dart';

/// Detection service that skips the native interpreter.
class FakeDetectionService extends DetectionService {
  FakeDetectionService(this.canned);

  final List<DetectedObject> canned;

  @override
  Future<void> reloadIfNeeded(InstalledModel model) async {}

  @override
  Future<List<DetectedObject>> detectObjects({
    required File imageFile,
    required ResolutionProfile profile,
    required double confidence,
    required double iou,
    required bool useNms,
    required int maxDetections,
    required Set<String> selectedLabels,
    bool filterBySelectedLabels = true,
  }) async => canned;

  @override
  int get lastInferenceMs => 33;
}

class RecordingShare extends ShareService {
  final List<({String name, String mime, Uint8List bytes})> shared = [];

  @override
  Future<void> shareBytes(
    Uint8List bytes, {
    required String fileName,
    required String mimeType,
    String? subject,
  }) async {
    shared.add((name: fileName, mime: mimeType, bytes: bytes));
  }
}

void main() {
  late Directory tmp;
  late File picture;
  late ModelLibraryService library;
  late SettingsController settings;
  late DetectionHistoryService history;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    tmp = await Directory.systemTemp.createTemp('results_export_test');
    picture = File(p.join(tmp.path, 'street.png'))
      ..writeAsBytesSync(img.encodePng(img.Image(width: 8, height: 4)));
    library = await ModelLibraryService.create(
      prefs,
      modelsDir: () async => Directory(p.join(tmp.path, 'library')),
    );
    settings = SettingsController(prefs);
    history = DetectionHistoryService(prefs);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Widget app(List<DetectedObject> detections, RecordingShare share) {
    return MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<ModelLibraryService>.value(value: library),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<DetectionHistoryService>.value(value: history),
        ChangeNotifierProvider<DetectionService>(
          create: (_) => FakeDetectionService(detections),
        ),
      ],
      child: MaterialApp(
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        locale: const Locale('en'),
        home: ResultsScreen(imageFile: picture, share: share),
      ),
    );
  }

  const person = DetectedObject(
    label: 'person',
    confidence: 0.9,
    boundingBox: Rect.fromLTWH(0.1, 0.2, 0.3, 0.4),
  );

  Future<void> finishDetection(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300)); // start delay
    await tester.pump();
    await tester.pump();
  }

  testWidgets('no export menu before detection has produced a result', (
    tester,
  ) async {
    usePortraitSurface(tester);
    await tester.pumpWidget(app(<DetectedObject>[person], RecordingShare()));

    expect(find.byTooltip('Export'), findsNothing);

    // Let the screen's start-up delay elapse so no timer outlives the test.
    await finishDetection(tester);
  });

  testWidgets('shares the detections as JSON with the model name', (
    tester,
  ) async {
    usePortraitSurface(tester);
    final share = RecordingShare();
    await tester.pumpWidget(app(<DetectedObject>[person], share));
    await finishDetection(tester);

    await tester.tap(find.byTooltip('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share as JSON'));
    await tester.pump();

    expect(share.shared, hasLength(1));
    final out = share.shared.single;
    expect(out.name, 'street.json');
    expect(out.mime, 'application/json');
    final json = jsonDecode(utf8.decode(out.bytes)) as Map<String, dynamic>;
    expect(json['model'], 'YOLO26 Nano (INT8)');
    expect(json['inferenceMs'], 33);
    expect(json['count'], 1);
    expect((json['detections'] as List).single['label'], 'person');
  });

  testWidgets('shares the detections as CSV', (tester) async {
    usePortraitSurface(tester);
    final share = RecordingShare();
    await tester.pumpWidget(app(<DetectedObject>[person], share));
    await finishDetection(tester);

    await tester.tap(find.byTooltip('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share as CSV'));
    await tester.pump();

    final out = share.shared.single;
    expect(out.name, 'street.csv');
    expect(out.mime, 'text/csv');
    final lines = utf8.decode(out.bytes).trimRight().split('\r\n');
    expect(lines.first, startsWith('label,confidence,x,y,width,height'));
    expect(lines[1], startsWith('person,0.9,0.1,0.2,0.3,0.4'));
  });

  testWidgets('an empty result can still be exported', (tester) async {
    usePortraitSurface(tester);
    final share = RecordingShare();
    await tester.pumpWidget(app(const <DetectedObject>[], share));
    await finishDetection(tester);

    expect(find.byTooltip('Export'), findsOneWidget);
    await tester.tap(find.byTooltip('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share as JSON'));
    await tester.pump();

    final json =
        jsonDecode(utf8.decode(share.shared.single.bytes))
            as Map<String, dynamic>;
    expect(json['count'], 0);
  });

  group('zoom and orientation', () {
    testWidgets('the photo can be pinch-zoomed in portrait', (tester) async {
      usePortraitSurface(tester);
      await tester.pumpWidget(app(<DetectedObject>[person], RecordingShare()));
      await finishDetection(tester);

      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(viewer.maxScale, greaterThan(1));
      expect(find.text('Share as JSON'), findsNothing);
    });

    testWidgets('landscape keeps the photo and the summary side by side', (
      tester,
    ) async {
      useLandscapeSurface(tester);
      await tester.pumpWidget(app(<DetectedObject>[person], RecordingShare()));
      await finishDetection(tester);

      expect(find.byType(InteractiveViewer), findsOneWidget);
      final photo = tester.getRect(find.byType(InteractiveViewer));
      final summary = tester.getRect(find.text('Analysis Summary'));
      expect(summary.left, greaterThanOrEqualTo(photo.right));
      expect(tester.takeException(), isNull);
    });
  });
}
