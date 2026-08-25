import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class AssistanceSosRow extends StatelessWidget {
  const AssistanceSosRow({
    super.key,
    required this.onFindAssistance,
    required this.onCallEmergency,
    required this.onShareLocation,
    required this.onCategory,
  });

  final VoidCallback onFindAssistance;
  final VoidCallback onCallEmergency;
  final VoidCallback onShareLocation;
  final ValueChanged<String> onCategory;

  static const _cats = [
    (
      Icons.support_agent_rounded,
      'Assistant',
      Color(0xFF6C63FF),
      Color(0xFFEEEBFF),
    ),
    (Icons.edit_note_rounded, 'Writer', Color(0xFF22C55E), Color(0xFFE6F9ED)),
    (
      Icons.sign_language_rounded,
      'Sign Language',
      Color(0xFFF97316),
      Color(0xFFFFF0E8),
    ),
    (
      Icons.accessible_rounded,
      'Mobility',
      Color(0xFF14B8A6),
      Color(0xFFE5F9F6),
    ),
    (Icons.more_horiz_rounded, 'More', Color(0xFF6B7280), Color(0xFFF3F4F6)),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 11,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Assistance?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                  Text(
                    'Find someone who can help you',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < _cats.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: InkWell(
                            onTap: () => onCategory(_cats[i].$2),
                            child: Column(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _cats[i].$4,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _cats[i].$1,
                                    color: _cats[i].$3,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _cats[i].$2,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E1B4B),
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: onFindAssistance,
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Find Assistance',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 9,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
              decoration: BoxDecoration(
                color: AppColors.sosBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sosBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Emergency SOS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.sos,
                    ),
                  ),
                  Text(
                    'Quick access to help',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _SosAction(
                            icon: Icons.phone_rounded,
                            label: 'Call Emergency',
                            onTap: onCallEmergency,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _SosAction(
                            icon: Icons.location_on_rounded,
                            label: 'Share Location',
                            onTap: onShareLocation,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your location will be shared with emergency contacts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SosAction extends StatelessWidget {
  const _SosAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.sos, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
