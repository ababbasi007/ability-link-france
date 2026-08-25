import 'package:flutter/material.dart';

import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepProfile extends StatelessWidget {
  const StepProfile({
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

  static const _profiles = [
    (Icons.accessible_rounded, 'Mobility'),
    (Icons.visibility_off_outlined, 'Blind'),
    (Icons.visibility_outlined, 'Low Vision'),
    (Icons.hearing_disabled_rounded, 'Deaf'),
    (Icons.hearing_rounded, 'Hard of Hearing'),
    (Icons.psychology_outlined, 'Cognitive Disability'),
    (Icons.record_voice_over_outlined, 'Speech Disability'),
    (Icons.back_hand_outlined, 'Upper Limb Disability'),
    (Icons.airline_seat_legroom_extra, 'Lower Limb Disability'),
    (Icons.monitor_heart_outlined, 'Chronic Illness'),
    (Icons.elderly_rounded, 'Elderly'),
    (Icons.more_horiz_rounded, 'Other'),
  ];

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      step: 4,
      title: 'Accessibility Profile',
      subtitle: 'What best describes you? Select all that apply.',
      onBack: onBack,
      onNext: onNext,
      onSkip: onSkip,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _profiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.95,
        ),
        itemBuilder: (context, i) {
          final item = _profiles[i];
          final selected = data.accessibilityProfiles.contains(item.$2);
          return SelectableIconCard(
            icon: item.$1,
            label: item.$2,
            selected: selected,
            onTap: () {
              if (selected) {
                data.accessibilityProfiles.remove(item.$2);
              } else {
                data.accessibilityProfiles.add(item.$2);
              }
              onChanged();
            },
          );
        },
      ),
    );
  }
}
