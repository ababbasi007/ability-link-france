import 'package:ability_link/screens/tele_rehab/tele_rehab_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<List<int>> pumpTools(WidgetTester tester) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RehabRecoveryTools(onTool: taps.add),
          ),
        ),
      ),
    );
    return taps;
  }

  testWidgets('lists the three recovery tools', (tester) async {
    await pumpTools(tester);

    expect(find.text('Recovery Tools'), findsOneWidget);
    expect(find.text('Health & recovery log'), findsOneWidget);
    expect(find.text('Rehab reminders'), findsOneWidget);
    expect(find.text('Session notes'), findsOneWidget);
  });

  testWidgets('each row reports its own index', (tester) async {
    final taps = await pumpTools(tester);

    // The hub maps these indexes to the health, reminders and notes screens,
    // so a shifted index would silently open the wrong one.
    await tester.tap(find.text('Health & recovery log'));
    await tester.tap(find.text('Rehab reminders'));
    await tester.tap(find.text('Session notes'));

    expect(taps, [0, 1, 2]);
  });
}
