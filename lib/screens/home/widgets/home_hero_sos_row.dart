import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import 'home_mock_glyphs.dart';

class HomeHeroSosRow extends StatelessWidget {
  const HomeHeroSosRow({
    super.key,
    required this.userName,
    required this.onAskAi,
    required this.onSos,
  });

  final String userName;
  final VoidCallback onAskAi;
  final VoidCallback onSos;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 15,
            child: _HeroCard(userName: userName, onAskAi: onAskAi),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 9, child: _SosCard(onTap: onSos)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.userName, required this.onAskAi});

  final String userName;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF007A52), Color(0xFF006D44), Color(0xFF005C3A)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -6,
            top: 6,
            width: 140,
            child: Image.asset(
              'assets/images/home_hero_illustration.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.35, 0.2),
              errorBuilder: (_, _, _) => Image.asset(
                'assets/images/home_hero_person.png',
                fit: BoxFit.contain,
                alignment: Alignment.bottomRight,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Soft left scrim so text stays readable over art
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFF006D44).withValues(alpha: 0.92),
                    const Color(0xFF006D44).withValues(alpha: 0.55),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.42, 0.78],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi $userName! 👋',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                SizedBox(
                  width: 130,
                  child: Text(
                    'What would you like to access today?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.94),
                      height: 1.25,
                    ),
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: onAskAi,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Ask AI Assistant',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.auto_awesome,
                              size: 12,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: const [
                    _Dot(active: true),
                    SizedBox(width: 5),
                    _Dot(active: false),
                  ],
                ),
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
    return Container(
      width: active ? 7 : 5,
      height: active ? 7 : 5,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white.withValues(alpha: 0.45),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _SosCard extends StatelessWidget {
  const _SosCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 9, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency SOS',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.sos,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Get help in an emergency',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  height: 1.15,
                ),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: CustomPaint(
                      painter: const SosRipplePainter(color: AppColors.sos),
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.sos,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x55E11D48),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'SOS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Tap to Alert >',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sos,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
