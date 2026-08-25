import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepPreferences extends StatelessWidget {
  const StepPreferences({
    super.key,
    required this.data,
    required this.onBack,
    required this.onNext,
    required this.onSkip,
    required this.onChanged,
  });

  final SignupData data;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      step: 9,
      title: 'Accessibility Preferences',
      subtitle: 'Customize your app experience.',
      onBack: onBack,
      onNext: onNext,
      onSkip: onSkip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupToggleTile(
            label: 'Large Text',
            icon: Icons.format_size_rounded,
            value: data.largeText,
            onChanged: (v) {
              data.largeText = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Voice Navigation',
            icon: Icons.record_voice_over_rounded,
            value: data.voiceNavigation,
            onChanged: (v) {
              data.voiceNavigation = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Dark Mode',
            icon: Icons.dark_mode_outlined,
            value: data.darkMode,
            onChanged: (v) {
              data.darkMode = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'High Contrast',
            icon: Icons.contrast_rounded,
            value: data.highContrast,
            onChanged: (v) {
              data.highContrast = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Screen Reader',
            icon: Icons.hearing_rounded,
            value: data.screenReader,
            onChanged: (v) {
              data.screenReader = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Haptic Feedback',
            icon: Icons.vibration_rounded,
            value: data.hapticFeedback,
            onChanged: (v) {
              data.hapticFeedback = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Captions',
            icon: Icons.closed_caption_rounded,
            value: data.captions,
            onChanged: (v) {
              data.captions = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Simple Language',
            icon: Icons.abc_rounded,
            value: data.simpleLanguage,
            onChanged: (v) {
              data.simpleLanguage = v;
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Text Size',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'A',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Expanded(
                child: Slider(
                  value: data.textSize,
                  min: 0.8,
                  max: 1.4,
                  divisions: 6,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    data.textSize = v;
                    onChanged();
                  },
                ),
              ),
              Text(
                'A',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
