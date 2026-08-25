import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import 'home_mock_glyphs.dart';

class HomeQuickTiles extends StatelessWidget {
  const HomeQuickTiles({
    super.key,
    required this.onPassport,
    required this.onBookings,
    required this.onMessages,
    required this.onSaved,
  });

  final VoidCallback onPassport;
  final VoidCallback onBookings;
  final VoidCallback onMessages;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('passport', 'Accessibility Passport', 'Your personal profile'),
      ('bookings', 'Bookings', 'View your appointments'),
      ('messages', 'Messages', 'Stay connected'),
      ('saved', 'Saved', 'Places, jobs & more'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Container(width: 1, height: 72, color: const Color(0xFFE5E7EB)),
            Expanded(
              child: InkWell(
                onTap: switch (i) {
                  0 => onPassport,
                  1 => onBookings,
                  2 => onMessages,
                  _ => onSaved,
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Column(
                    children: [
                      HomeQuickGlyph(kind: items[i].$1, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        items[i].$2,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$3,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 8,
                          color: AppColors.textSecondary,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
