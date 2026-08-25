import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../signup_data.dart';
import '../signup_flow_screen.dart';

class StepPassport extends StatelessWidget {
  const StepPassport({
    super.key,
    required this.data,
    required this.onBack,
    required this.onFinish,
    required this.onSkip,
  });

  final SignupData data;
  final VoidCallback onBack;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      step: 11,
      title: 'Accessibility Passport',
      subtitle: 'Review your profile summary.',
      onBack: onBack,
      onNext: onFinish,
      onSkip: onSkip,
      nextLabel: 'Finish Setup',
      showSkip: true,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6C63FF),
                  Color(0xFF5B52E8),
                  Color(0xFF4F46C8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'Ability Passport',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      data.passportId,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/images/avatar.png'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.fullName.isEmpty
                                ? 'Ayesha Khan'
                                : data.fullName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.role ?? 'I Need Support',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final p in data.accessibilityProfiles.take(
                                3,
                              ))
                                _pill(p),
                              if (data.mobilityAid.isNotEmpty)
                                _pill(data.mobilityAid),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 40,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _info(
                          'Emergency',
                          data.emergencyName.isEmpty
                              ? 'Sara Khan'
                              : data.emergencyName,
                        ),
                      ),
                      Expanded(child: _info('Blood', data.bloodGroup)),
                      Expanded(
                        child: _info('Language', data.preferredLanguage),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your Accessibility Needs',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1B4B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _need(
                Icons.accessible_rounded,
                data.mobilityAid.isEmpty ? 'Mobility' : data.mobilityAid,
              ),
              _need(
                Icons.people_outline_rounded,
                data.needCaregiver ? 'Caregiver' : 'Independent',
              ),
              _need(
                Icons.sign_language_outlined,
                data.needsInterpreter || data.signLanguage != 'None'
                    ? 'Sign'
                    : 'Spoken',
              ),
              _need(Icons.chat_outlined, data.preferredContactMethod),
            ],
          ),
          if (data.communicationSummary.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                data.communicationSummary,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            "You're all set! 🎉",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your Accessibility Passport is ready. Start exploring Ability Link.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _need(IconData icon, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1B4B),
            ),
          ),
        ],
      ),
    );
  }
}
