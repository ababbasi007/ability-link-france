import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/benefit_scheme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/benefits_service.dart';
import '../../theme/app_colors.dart';
import 'benefit_detail_screen.dart';

class BenefitEligibilityScreen extends StatefulWidget {
  const BenefitEligibilityScreen({super.key});

  @override
  State<BenefitEligibilityScreen> createState() =>
      _BenefitEligibilityScreenState();
}

class _BenefitEligibilityScreenState extends State<BenefitEligibilityScreen> {
  final _benefits = BenefitsService();
  final _auth = AuthService();

  bool _hasDisabilityRecognition = true;
  bool _lowIncome = false;
  bool _seekingWork = false;
  bool _student = false;
  bool _needsHousing = false;
  bool _needsTransport = false;
  bool _needsHealthcare = false;
  bool _needsTaxHelp = false;
  List<EligibilityResult>? _results;

  void _run(List<BenefitScheme> schemes, UserProfile? profile) {
    setState(() {
      _results = _benefits.checkEligibility(
        schemes,
        hasDisabilityRecognition: _hasDisabilityRecognition,
        lowIncome: _lowIncome,
        seekingWork: _seekingWork,
        student: _student,
        needsHousing: _needsHousing,
        needsTransport: _needsTransport,
        needsHealthcare: _needsHealthcare,
        needsTaxHelp: _needsTaxHelp,
        profile: profile,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Eligibility checker',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _auth.watchCurrentProfile(),
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          return StreamBuilder<List<BenefitScheme>>(
            stream: _benefits.watchSchemes(),
            builder: (context, snap) {
              final schemes = snap.data ?? seedBenefits;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    'Answer a few questions. This is guidance only — not an official decision.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _toggle(
                    'I have (or am applying for) disability recognition / MDPH',
                    _hasDisabilityRecognition,
                    (v) => setState(() => _hasDisabilityRecognition = v),
                  ),
                  _toggle(
                    'Low income / need financial support',
                    _lowIncome,
                    (v) => setState(() => _lowIncome = v),
                  ),
                  _toggle(
                    'Looking for work or workplace adaptations',
                    _seekingWork,
                    (v) => setState(() => _seekingWork = v),
                  ),
                  _toggle(
                    'Student / school or university support',
                    _student,
                    (v) => setState(() => _student = v),
                  ),
                  _toggle(
                    'Housing adaptation or rent aid',
                    _needsHousing,
                    (v) => setState(() => _needsHousing = v),
                  ),
                  _toggle(
                    'Transport / parking / mobility card',
                    _needsTransport,
                    (v) => setState(() => _needsTransport = v),
                  ),
                  _toggle(
                    'Healthcare / insurance coverage',
                    _needsHealthcare,
                    (v) => setState(() => _needsHealthcare = v),
                  ),
                  _toggle(
                    'Tax reliefs',
                    _needsTaxHelp,
                    (v) => setState(() => _needsTaxHelp = v),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _run(schemes, profile),
                    child: const Text('Check matching benefits'),
                  ),
                  if (_results != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _results!.isEmpty
                          ? 'No strong matches — try enabling more situations.'
                          : '${_results!.where((r) => r.likelyEligible).length} likely matches · ${_results!.length} scored',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final r in _results!) ...[
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => BenefitDetailScreen(
                                  scheme: r.scheme,
                                  matchScore: r.score,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        r.scheme.name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${r.score}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        color: r.likelyEligible
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  r.likelyEligible
                                      ? 'Likely relevant'
                                      : 'Possible / explore',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  r.reasons.take(3).join(' · '),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }
}
