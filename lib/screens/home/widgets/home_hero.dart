import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

/// Light-green hero carousel card matching the homepage mockup.
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.onExplore,
  });

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 168,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3FBF6), Color(0xFFE8F5EE), Color(0xFFDFF3E8)],
        ),
        border: Border.all(color: const Color(0xFFD5F2E8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -4,
            top: 8,
            width: 168,
            child: Image.asset(
              'assets/images/home_hero_mock_art.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/home_hero_illustration.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 140, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                    children: [
                      const TextSpan(text: 'Empowering '),
                      TextSpan(
                        text: 'Abilities',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                    children: [
                      const TextSpan(text: 'Connecting '),
                      TextSpan(
                        text: 'Lives',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find accessible places, trusted services\nand a supportive community.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
                const Spacer(),
                Material(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    onTap: onExplore,
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore Nearby',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.near_me_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Dot(active: true),
                SizedBox(width: 5),
                _Dot(active: false),
                SizedBox(width: 5),
                _Dot(active: false),
                SizedBox(width: 5),
                _Dot(active: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 14 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}
