import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ability_link/widgets/app_bottom_nav.dart';

/// Stands in for MainShell: registers with [AppShellNav] the same way.
class _FakeShell extends StatefulWidget {
  const _FakeShell();

  @override
  State<_FakeShell> createState() => _FakeShellState();
}

class _FakeShellState extends State<_FakeShell> {
  int index = 0;

  @override
  void initState() {
    super.initState();
    AppShellNav.instance.attach(this, index: index, onSelect: _goTab);
  }

  @override
  void dispose() {
    AppShellNav.instance.detach(this);
    super.dispose();
  }

  void _goTab(int i) {
    if (!mounted) return;
    setState(() => index = i);
    AppShellNav.instance.syncIndex(i);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Text('shell tab $index')),
  );
}

Widget _pushedScreen(String title) => Scaffold(
  body: SafeArea(
    bottom: false,
    child: Center(child: Text(title)),
  ),
);

void main() {
  Future<void> pumpApp(WidgetTester tester, {required Widget home}) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppShellNav.navigatorKey,
        builder: (context, child) =>
            PersistentNavHost(child: child ?? const SizedBox.shrink()),
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no bar before the shell opens', (tester) async {
    await pumpApp(tester, home: _pushedScreen('splash'));

    expect(find.byType(AppBottomNavBar), findsNothing);
  });

  testWidgets('bar shows once the shell is open', (tester) async {
    await pumpApp(tester, home: const _FakeShell());

    expect(find.byType(AppBottomNavBar), findsOneWidget);
  });

  testWidgets('bar stays on pushed feature screens, pinned to the bottom', (
    tester,
  ) async {
    await pumpApp(tester, home: const _FakeShell());

    for (final title in ['Tele-Rehabilitation', 'Telehealth', 'Caregiver']) {
      AppShellNav.navigatorKey.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => _pushedScreen(title)),
      );
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget, reason: title);
      expect(find.byType(AppBottomNavBar), findsOneWidget, reason: title);

      final bar = tester.getRect(find.byType(AppBottomNavBar));
      final screen = tester.getSize(find.byType(MaterialApp));
      expect(bar.bottom, screen.height, reason: title);

      final page = tester.getRect(find.text(title));
      expect(page.bottom, lessThanOrEqualTo(bar.top), reason: title);
    }
  });

  testWidgets('tapping a tab from a pushed screen returns to the shell', (
    tester,
  ) async {
    await pumpApp(tester, home: const _FakeShell());

    AppShellNav.navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => _pushedScreen('Tele-Rehab')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tele-Rehab'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Tele-Rehab'), findsNothing);
    expect(find.text('shell tab 4'), findsOneWidget);
    expect(find.byType(AppBottomNavBar), findsOneWidget);
  });
}
