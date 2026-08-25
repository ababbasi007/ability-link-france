import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class HomeAiBanner extends StatelessWidget {
  const HomeAiBanner({super.key, required this.onChat});

  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD5F2E8)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/home_ai_mascot.png',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Image.asset(
              'assets/images/ai_robot.png',
              width: 58,
              height: 58,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Need help? Chat with our AI Assistant anytime, anywhere.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: onChat,
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Chat with AI',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
