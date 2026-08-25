import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_lock_service.dart';
import '../../theme/app_colors.dart';
import '../privacy/passport_privacy_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _auth = AuthService();
  final _bio = BiometricLockService();
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String ok) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_auth.messageFor(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            'Change password',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Update'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      if (next.text.trim() != confirm.text.trim()) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New passwords do not match')),
        );
        return;
      }
      await _run(
        () => _auth.changePassword(
          currentPassword: current.text,
          newPassword: next.text,
        ),
        'Password updated',
      );
    } finally {
      current.dispose();
      next.dispose();
      confirm.dispose();
    }
  }

  Future<void> _forgot() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    await _run(
      () => _auth.sendPasswordReset(email),
      'Reset email sent to $email',
    );
  }

  Future<void> _toggleBiometric(bool enabled) async {
    if (enabled) {
      final available = await _bio.isAvailable();
      if (!available) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This device has no Face ID, fingerprint, or screen lock.',
            ),
          ),
        );
        return;
      }
      final ok = await _bio.authenticate(
        reason: 'Confirm to turn on biometric lock',
      );
      if (!ok) return;
    } else {
      BiometricLockService.sessionUnlocked = true;
    }
    await _run(
      () => _auth.setBiometricLock(enabled),
      enabled ? 'Biometric lock on' : 'Biometric lock off',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final emailAccount =
        user?.providerData.any((p) => p.providerId == 'password') == true;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Security',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _auth.watchCurrentProfile(),
        builder: (context, snap) {
          final lockOn = snap.data?.preferences['biometricLock'] == true;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'Account sign-in',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_reset_outlined),
                      title: const Text('Change password'),
                      subtitle: Text(
                        emailAccount
                            ? 'Re-enter your current password, then set a new one'
                            : 'Google accounts manage passwords in Google',
                      ),
                      enabled: emailAccount && !_busy,
                      onTap: emailAccount ? _changePassword : null,
                    ),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Forgot password'),
                      subtitle: Text(
                        user?.email == null || user!.email!.isEmpty
                            ? 'No email on this account'
                            : 'Send a reset link to ${user.email}',
                      ),
                      enabled:
                          !_busy &&
                          user?.email != null &&
                          user!.email!.isNotEmpty,
                      onTap: _forgot,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Device lock',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text('Biometric lock'),
                  subtitle: const Text(
                    'Require Face ID, fingerprint, or device PIN when opening the app',
                  ),
                  value: lockOn,
                  onChanged: _busy ? null : _toggleBiometric,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Privacy',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Passport sharing & privacy'),
                  subtitle: const Text(
                    'Consent, access log, export, and delete account',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PassportPrivacyScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Covers the whole app while locked.
///
/// This has to sit above the navigator: wrapping only the shell left pushed
/// screens and open sheets visible after the app came back from the background.
class BiometricLockGate extends StatefulWidget {
  const BiometricLockGate({
    super.key,
    required this.child,
    required this.enabled,
  });

  final bool enabled;
  final Widget child;

  @override
  State<BiometricLockGate> createState() => _BiometricLockGateState();
}

class _BiometricLockGateState extends State<BiometricLockGate>
    with WidgetsBindingObserver {
  final _bio = BiometricLockService();
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only record pause time when fully backgrounded (not just inactive, which
    // happens during notification shade pull / system dialog and would cause
    // spurious lock-on-resume when the user comes back quickly).
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    }
    if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null; // always clear so stale timestamps can't accumulate
      if (pausedAt != null) {
        final away = DateTime.now().difference(pausedAt);
        if (away.inSeconds >= 30) {
          _bio.lockSession();
          if (mounted) setState(() {});
        }
      }
    }
  }

  Future<void> _unlock() async {
    final ok = await _bio.authenticate();
    if (ok && mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || BiometricLockService.sessionUnlocked) {
      return widget.child;
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_rounded,
                size: 56,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Ability Link is locked',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use Face ID, fingerprint, or your device PIN to continue.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _unlock,
                icon: const Icon(Icons.fingerprint_rounded),
                label: const Text('Unlock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
