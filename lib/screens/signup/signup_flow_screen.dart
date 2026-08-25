import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../auth/auth_gate.dart';
import 'signup_data.dart';
import 'signup_shared.dart';
import 'steps/step_assistance.dart';
import 'steps/step_communication.dart';
import 'steps/step_contact.dart';
import 'steps/step_healthcare.dart';
import 'steps/step_medical.dart';
import 'steps/step_passport.dart';
import 'steps/step_personal.dart';
import 'steps/step_personalization.dart';
import 'steps/step_preferences.dart';
import 'steps/step_profile.dart';
import 'steps/step_role.dart';

class SignupFlowScreen extends StatefulWidget {
  const SignupFlowScreen({super.key});

  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

class _SignupFlowScreenState extends State<SignupFlowScreen> {
  final _auth = AuthService();
  final _data = SignupData();
  int _step = 1;
  bool _saving = false;

  void _next() {
    if (_step < 11) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 1) setState(() => _step--);
  }

  void _skip() {
    if (_step < 11) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      // Prefill email from auth if empty
      final user = _auth.currentUser;
      if ((_data.email.isEmpty) && user?.email != null) {
        _data.email = user!.email!;
      }
      if (_data.firstName.isEmpty && (user?.displayName?.isNotEmpty ?? false)) {
        final parts = user!.displayName!.trim().split(' ');
        _data.firstName = parts.first;
        if (parts.length > 1) {
          _data.lastName = parts.sublist(1).join(' ');
        }
      }
      await _auth.saveOnboardingProfile(_data);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_auth.messageFor(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: SignupProgressBar(step: _step, total: 11),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 1:
        return StepRole(
          data: _data,
          onChanged: () => setState(() {}),
          onContinue: () {
            if (_data.role == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select a role to continue'),
                ),
              );
              return;
            }
            _next();
          },
        );
      case 2:
        return StepPersonal(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 3:
        return StepContact(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 4:
        return StepProfile(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 5:
        return StepCommunication(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 6:
        return StepAssistance(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 7:
        return StepMedical(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 8:
        return StepHealthcare(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 9:
        return StepPreferences(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 10:
        return StepPersonalization(
          data: _data,
          onBack: _back,
          onNext: _next,
          onSkip: _skip,
          onChanged: () => setState(() {}),
        );
      case 11:
      default:
        return StepPassport(
          data: _data,
          onBack: _back,
          onFinish: _finish,
          onSkip: _finish,
        );
    }
  }
}

/// Shared scroll + footer layout for signup steps.
class SignupStepScaffold extends StatelessWidget {
  const SignupStepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onBack,
    required this.onNext,
    this.onSkip,
    this.nextLabel = 'Next',
    this.showSkip = true,
    this.total = 11,
  });

  final int step;
  final int total;
  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback? onSkip;
  final String nextLabel;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              SignupStepHeader(
                step: step,
                total: total,
                title: title,
                subtitle: subtitle,
                onBack: onBack,
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FB),
            border: Border(top: BorderSide(color: Color(0xFFF0F1F3))),
          ),
          child: SignupBottomBar(
            onBack: onBack,
            onNext: onNext,
            onSkip: onSkip,
            nextLabel: nextLabel,
            showSkip: showSkip,
          ),
        ),
      ],
    );
  }
}
