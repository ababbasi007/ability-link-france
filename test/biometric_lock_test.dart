import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ability_link/screens/profile/security_screen.dart';
import 'package:ability_link/services/biometric_lock_service.dart';

/// Mirrors how [BiometricLockGate] is installed in main.dart: above the
/// navigator, via MaterialApp.builder.
Widget _app({required bool lockEnabled, required GlobalKey<NavigatorState> nav}) {
  return MaterialApp(
    navigatorKey: nav,
    builder: (context, child) => BiometricLockGate(
      enabled: lockEnabled,
      child: child ?? const SizedBox.shrink(),
    ),
    home: const Scaffold(body: Center(child: Text('home screen'))),
  );
}

void main() {
  setUp(() => BiometricLockService.sessionUnlocked = false);
  tearDown(() => BiometricLockService.sessionUnlocked = false);

  testWidgets('passes content through when the lock is off', (tester) async {
    await tester.pumpWidget(
      _app(lockEnabled: false, nav: GlobalKey<NavigatorState>()),
    );

    expect(find.text('home screen'), findsOneWidget);
    expect(find.text('Ability Link is locked'), findsNothing);
  });

  testWidgets('hides content while locked', (tester) async {
    await tester.pumpWidget(
      _app(lockEnabled: true, nav: GlobalKey<NavigatorState>()),
    );

    expect(find.text('Ability Link is locked'), findsOneWidget);
    expect(find.text('home screen'), findsNothing);
  });

  testWidgets('passes content through once the session is unlocked', (
    tester,
  ) async {
    BiometricLockService.sessionUnlocked = true;
    await tester.pumpWidget(
      _app(lockEnabled: true, nav: GlobalKey<NavigatorState>()),
    );

    expect(find.text('home screen'), findsOneWidget);
    expect(find.text('Ability Link is locked'), findsNothing);
  });

  testWidgets('covers a pushed screen, not just the shell', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    BiometricLockService.sessionUnlocked = true;
    await tester.pumpWidget(_app(lockEnabled: true, nav: nav));

    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          body: Center(child: Text('medical records')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('medical records'), findsOneWidget);

    // Coming back from the background after the timeout locks the session.
    BiometricLockService().lockSession();
    await tester.pumpWidget(_app(lockEnabled: true, nav: nav));
    await tester.pumpAndSettle();

    expect(find.text('Ability Link is locked'), findsOneWidget);
    expect(find.text('medical records'), findsNothing);
  });

  testWidgets('covers an open bottom sheet', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    BiometricLockService.sessionUnlocked = true;
    await tester.pumpWidget(_app(lockEnabled: true, nav: nav));

    showModalBottomSheet<void>(
      context: nav.currentContext!,
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(child: Text('blood group: O-')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('blood group: O-'), findsOneWidget);

    BiometricLockService().lockSession();
    await tester.pumpWidget(_app(lockEnabled: true, nav: nav));
    await tester.pumpAndSettle();

    expect(find.text('Ability Link is locked'), findsOneWidget);
    expect(find.text('blood group: O-'), findsNothing);
  });
}
