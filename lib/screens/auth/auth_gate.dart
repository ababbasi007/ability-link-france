import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../main_shell.dart';
import 'auth_screen.dart';
import '../signup/signup_flow_screen.dart';

/// Post-splash router based on auth + onboarding state.
///
/// - Signed out → [AuthScreen] (Sign Up tab)
/// - Signed in, onboarding incomplete → [SignupFlowScreen]
/// - Signed in, onboarding complete → [MainShell]
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, AuthService? authService})
    : _authService = authService;

  final AuthService? _authService;

  @override
  Widget build(BuildContext context) {
    final auth = _authService ?? AuthService();

    return StreamBuilder<User?>(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        // Only show a spinner on the very first load — never on resume.
        // Using snapshot.data (which retains the last value) avoids a black
        // flash when the stream briefly re-emits on app foreground.
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const AuthScreen(initialTab: AuthTab.signUp);
        }

        return FutureBuilder<bool>(
          key: ValueKey('onboard-${user.uid}'),
          future: auth.isOnboardingComplete(user.uid),
          builder: (context, onboardSnap) {
            if (onboardSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (onboardSnap.hasError) {
              return const SignupFlowScreen();
            }
            if (onboardSnap.data == true) {
              return const MainShell();
            }
            return const SignupFlowScreen();
          },
        );
      },
    );
  }
}

/// Drops every route and hands control back to [AuthGate].
///
/// Needed on sign-out as well as sign-in: [AuthGate] rebuilding underneath a
/// pushed screen left the signed-out user looking at authenticated content.
void resetToAuthGate(BuildContext context) {
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const AuthGate()),
    (_) => false,
  );
}

/// After login/signup, replace stack with [AuthGate] (no splash replay).
Future<void> navigateAfterAuth(BuildContext context, AuthService auth) async {
  resetToAuthGate(context);
}
