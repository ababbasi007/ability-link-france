import 'package:local_auth/local_auth.dart';

class BiometricLockService {
  BiometricLockService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  static bool sessionUnlocked = false;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({String reason = 'Unlock Ability Link'}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (ok) sessionUnlocked = true;
      return ok;
    } catch (_) {
      return false;
    }
  }

  void lockSession() {
    sessionUnlocked = false;
  }
}
