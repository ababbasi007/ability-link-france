import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Matches mock: one bordered panel split into two suggestions.
class AiSuggestionsSection extends StatelessWidget {
  const AiSuggestionsSection({
    super.key,
    required this.onRoute,
    required this.onExercises,
  });

  final VoidCallback onRoute;
  final VoidCallback onExercises;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Suggestions for You',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: onRoute,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFF6C63FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Best accessible route to your physiotherapy session.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E1B4B),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'View Route >',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: onExercises,
                      borderRadius: const BorderRadius.horizontal(
                        right: Radius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 14, 12, 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Try these exercises for better shoulder mobility.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E1B4B),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'View Exercises >',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const _ExerciseIllustration(),
                          ],
                        ),
                      ),
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

class _ExerciseIllustration extends StatelessWidget {
  const _ExerciseIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEAFE).withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.accessibility_new_rounded,
            color: Color(0xFF3B82F6),
            size: 28,
          ),
        ],
      ),
    );
  }
}
