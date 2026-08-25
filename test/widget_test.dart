import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ability_link/services/auth_service.dart';

void main() {
  test('AuthService maps FirebaseAuthException codes', () {
    expect(
      AuthService.errorMessage(
        FirebaseAuthException(code: 'email-already-in-use'),
      ),
      contains('already registered'),
    );
    expect(
      AuthService.errorMessage(
        FirebaseAuthException(code: 'invalid-credential'),
      ),
      contains('Incorrect'),
    );
  });
}
