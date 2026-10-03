import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sizes the test surface to a phone held upright. The default 800x600 surface
/// is landscape, which switches screens to their landscape layouts.
void usePortraitSurface(WidgetTester tester) => _useSurface(tester, 800, 1600);

/// Sizes the test surface to a phone held sideways.
void useLandscapeSurface(WidgetTester tester) => _useSurface(tester, 1600, 800);

void _useSurface(WidgetTester tester, double width, double height) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.reset);
}
