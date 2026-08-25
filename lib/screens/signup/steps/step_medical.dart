import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepMedical extends StatelessWidget {
  const StepMedical({
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

  static const _aids = [
    (Icons.accessible_rounded, 'Wheelchair'),
    (Icons.directions_walk_rounded, 'Walker'),
    (Icons.elderly_rounded, 'Cane'),
    (Icons.accessibility_new_rounded, 'Crutches'),
    (Icons.personal_injury_outlined, 'Prosthetic'),
    (Icons.block_rounded, 'None'),
    (Icons.more_horiz_rounded, 'Others'),
  ];

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      step: 7,
      title: 'Medical & Accessibility Details',
      subtitle: 'Help us understand your mobility and access needs.',
      onBack: onBack,
      onNext: onNext,
      onSkip: onSkip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mobility Aid',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _aids.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) {
              final aid = _aids[i];
              return SelectableIconCard(
                icon: aid.$1,
                label: aid.$2,
                selected: data.mobilityAid == aid.$2,
                compact: true,
                onTap: () {
                  data.mobilityAid = aid.$2;
                  onChanged();
                },
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Access Requirements',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 12),
          YesNoToggle(
            label: 'Need accessible transport?',
            value: data.needAccessibleTransport,
            onChanged: (v) {
              data.needAccessibleTransport = v;
              onChanged();
            },
          ),
          YesNoToggle(
            label: 'Need elevator access?',
            value: data.needElevator,
            onChanged: (v) {
              data.needElevator = v;
              onChanged();
            },
          ),
          YesNoToggle(
            label: 'Need accessible toilet?',
            value: data.needAccessibleToilet,
            onChanged: (v) {
              data.needAccessibleToilet = v;
              onChanged();
            },
          ),
          YesNoToggle(
            label: 'Need caregiver?',
            value: data.needCaregiver,
            onChanged: (v) {
              data.needCaregiver = v;
              onChanged();
            },
          ),
          YesNoToggle(
            label: 'Need service animal accommodation?',
            value: data.needServiceAnimal,
            onChanged: (v) {
              data.needServiceAnimal = v;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
