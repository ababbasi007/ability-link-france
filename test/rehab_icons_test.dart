import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ability_link/screens/tele_rehab/tele_rehab_chrome.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(
    body: SizedBox(width: 390, child: child),
  ),
);

List<String> _assetPaths(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => (image.image as AssetImage).assetName)
    .toList();

void main() {
  testWidgets('quick actions use the mockup illustrations', (tester) async {
    await tester.pumpWidget(_host(RehabQuickActions(onAction: (_) {})));
    await tester.pumpAndSettle();

    expect(_assetPaths(tester), [
      'assets/images/rehab/qa_live.png',
      'assets/images/rehab/qa_book.png',
      'assets/images/rehab/qa_exercises.png',
      'assets/images/rehab/qa_reports.png',
      'assets/images/rehab/qa_message.png',
      'assets/images/rehab/qa_upload.png',
    ]);
    // Fallback icons only appear when an asset fails to load.
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('exercise library categories use the mockup illustrations', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(RehabExerciseLibrary(onViewAll: () {}, onCategory: (_) {})),
    );
    await tester.pumpAndSettle();

    expect(_assetPaths(tester), [
      'assets/images/rehab/lib_upper.png',
      'assets/images/rehab/lib_lower.png',
      'assets/images/rehab/lib_flex.png',
      'assets/images/rehab/lib_strength.png',
      'assets/images/rehab/lib_breath.png',
    ]);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('cards render without overflowing a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(RehabQuickActions(onAction: (_) {})));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
