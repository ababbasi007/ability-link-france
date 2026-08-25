import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../signup_data.dart';
import '../signup_shared.dart';

class StepRole extends StatelessWidget {
  const StepRole({
    super.key,
    required this.data,
    required this.onChanged,
    required this.onContinue,
  });

  final SignupData data;
  final VoidCallback onChanged;
  final VoidCallback onContinue;

  static const _roles = [
    (
      'I Need Support',
      'I need help and support in daily life',
      Icons.handshake_outlined,
    ),
    (
      'Caregiver / Family',
      'I care for someone and manage their needs',
      Icons.family_restroom_rounded,
    ),
    (
      'Healthcare Professional',
      'I provide healthcare or therapy services',
      Icons.medical_services_outlined,
    ),
    ('Organization', 'We represent an organization', Icons.apartment_rounded),
    (
      'Volunteer',
      'I want to help and make a difference',
      Icons.volunteer_activism_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Row(
                children: [
                  const Spacer(),
                  Text(
                    'Step 1 of 11',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_a.png',
                      width: 56,
                      height: 56,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ability Link',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Empowering abilities, connecting lives.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEEF0FF), Color(0xFFE0E4FF)],
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.accessible_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.groups_rounded,
                      size: 44,
                      color: Color(0xFF8B85FF),
                    ),
                    SizedBox(width: 12),
                    Icon(
                      Icons.favorite_rounded,
                      size: 36,
                      color: Color(0xFFA78BFA),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome to Ability Link',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose how you want to use Ability Link',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              for (final role in _roles) ...[
                _RoleCard(
                  title: role.$1,
                  subtitle: role.$2,
                  icon: role.$3,
                  selected: data.role == role.$1,
                  onTap: () {
                    data.role = role.$1;
                    onChanged();
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SignupBottomBar(
            showBack: false,
            showSkip: false,
            nextLabel: 'Continue',
            onNext: onContinue,
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primaryLight : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : const Color(0xFFEEF0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
