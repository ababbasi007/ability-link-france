import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

/// Five primary quick-actions under the hero (SOS, Map, Passport, AI, Support).
class HomePrimaryActions extends StatelessWidget {
  const HomePrimaryActions({
    super.key,
    required this.onSos,
    required this.onMap,
    required this.onPassport,
    required this.onAi,
    required this.onSupport,
  });

  final VoidCallback onSos;
  final VoidCallback onMap;
  final VoidCallback onPassport;
  final VoidCallback onAi;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.emergency_rounded,
        'SOS',
        'Emergency',
        const Color(0xFFFEE2E2),
        AppColors.sos,
        onSos,
      ),
      (
        Icons.location_on_rounded,
        'Ability Map',
        'Accessible places',
        const Color(0xFFE8F5EE),
        AppColors.primary,
        onMap,
      ),
      (
        Icons.badge_rounded,
        'Accessibility\nPassport',
        'Passport',
        const Color(0xFFE8F5EE),
        AppColors.primary,
        onPassport,
      ),
      (
        Icons.chat_bubble_rounded,
        'AI Assistant',
        'Ask Anything',
        const Color(0xFFE0F2FE),
        const Color(0xFF0284C7),
        onAi,
      ),
      (
        Icons.volunteer_activism_rounded,
        'Support',
        'Get Help',
        const Color(0xFFE8F5EE),
        AppColors.primary,
        onSupport,
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Expanded(
            child: InkWell(
              onTap: item.$6,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: item.$4,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.$1, color: item.$5, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.$3,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
