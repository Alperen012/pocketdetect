import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile_yolo/core/models/detected_object.dart';
import 'package:mobile_yolo/core/models/detection_history_entry.dart';
import 'package:mobile_yolo/core/services/detection_history_service.dart';
import 'package:mobile_yolo/features/history/history_screen.dart';
import 'package:mobile_yolo/l10n/generated/app_localizations.dart';

Widget _buildTestApp(DetectionHistoryService service) {
  return ChangeNotifierProvider<DetectionHistoryService>.value(
    value: service,
    child: MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: const Locale('en'),
      home: const HistoryScreen(),
    ),
  );
}

DetectionHistoryEntry _makeEntry(String id) {
  return DetectionHistoryEntry(
    id: id,
    imagePath: '/tmp/$id.jpg',
    detections: const [
      DetectedObject(
        label: 'person',
        confidence: 0.9,
        boundingBox: Rect.fromLTWH(0, 0, 100, 200),
      ),
    ],
    timestamp: DateTime.utc(2026, 3, 11),
    inferenceMs: 30,
    modelName: 'YOLOv8n',
  );
}

void main() {
  group('HistoryScreen', () {
    late SharedPreferences prefs;
    late DetectionHistoryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = DetectionHistoryService(prefs);
    });

    testWidgets('shows empty state when no history entries', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      // Should display the empty state text
      expect(find.text('No detections yet'), findsOneWidget);
    });

    testWidgets('renders list of entries when data exists', (
      WidgetTester tester,
    ) async {
      await service.addEntry(_makeEntry('entry-1'));
      await service.addEntry(_makeEntry('entry-2'));

      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      // Should show entries, not empty state
      expect(find.text('No detections yet'), findsNothing);

      // Should show model info for each entry
      expect(find.text('YOLOv8n'), findsNWidgets(2));
    });

    testWidgets('shows detection count in entries', (
      WidgetTester tester,
    ) async {
      await service.addEntry(_makeEntry('entry-1'));

      await tester.pumpWidget(_buildTestApp(service));
      await tester.pumpAndSettle();

      // 1 object detected → "1 objects" text
      expect(find.text('1 objects'), findsOneWidget);
    });
  });
}
