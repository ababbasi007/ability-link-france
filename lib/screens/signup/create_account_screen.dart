import 'package:flutter/material.dart';

import '../auth/auth_screen.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthScreen(initialTab: AuthTab.signUp);
  }
}
