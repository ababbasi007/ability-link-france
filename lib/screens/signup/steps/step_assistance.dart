import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepAssistance extends StatelessWidget {
  const StepAssistance({
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

  static const _items = [
    'Personal Assistant',
    'Guide Assistant',
    'Writer / Scribe',
    'Sign Language Interpreter',
    'Wheelchair Assistance',
    'Caregiver',
    'Home Support',
    'Transportation',
    'Hospital Companion',
    'Shopping Assistance',
    'Government Benefits',
    'Education Support',
    'Travel Assistant',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      step: 6,
      title: 'Assistance Requirements',
      subtitle: 'What assistance do you usually need?',
      onBack: onBack,
      onNext: onNext,
      onSkip: onSkip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _items.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: _check(_items[i])),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < _items.length
                        ? _check(_items[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Additional Requirements (Optional)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          SignupTextField(
            hint: 'Share any other needs (max 200 characters)',
            maxLines: 4,
            initialValue: data.additionalRequirements,
            onChanged: (v) {
              if (v.length <= 200) {
                data.additionalRequirements = v;
                onChanged();
              }
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${data.additionalRequirements.length}/200',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _check(String label) {
    final selected = data.assistanceNeeds.contains(label);
    return InkWell(
      onTap: () {
        if (selected) {
          data.assistanceNeeds.remove(label);
        } else {
          data.assistanceNeeds.add(label);
        }
        onChanged();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 22,
              color: selected ? AppColors.primary : const Color(0xFFD1D5DB),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
