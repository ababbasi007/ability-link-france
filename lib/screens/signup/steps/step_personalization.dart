import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepPersonalization extends StatelessWidget {
  const StepPersonalization({
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

  static const _services = [
    (Icons.health_and_safety_outlined, 'Telehealth'),
    (Icons.fitness_center_rounded, 'Tele-Rehabilitation'),
    (Icons.map_outlined, 'Accessibility Map'),
    (Icons.flight_outlined, 'Accessible Tourism'),
    (Icons.school_outlined, 'Accessible Education'),
    (Icons.groups_rounded, 'Caregiver Support'),
    (Icons.account_balance_outlined, 'Government Benefits'),
    (Icons.auto_awesome_rounded, 'AI Assistant'),
  ];

  @override
  Widget build(BuildContext context) {
    return SignupStepScaffold(
      step: 10,
      title: 'AI Personalization',
      subtitle: "Let's personalize Ability Link for you.",
      onBack: onBack,
      onNext: onNext,
      onSkip: onSkip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services you are interested in',
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
            itemCount: _services.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.78,
            ),
            itemBuilder: (context, i) {
              final s = _services[i];
              final selected = data.interestedServices.contains(s.$2);
              return SelectableIconCard(
                icon: s.$1,
                label: s.$2,
                selected: selected,
                compact: true,
                onTap: () {
                  if (selected) {
                    data.interestedServices.remove(s.$2);
                  } else {
                    data.interestedServices.add(s.$2);
                  }
                  onChanged();
                },
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Notification Preferences',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 10),
          SignupToggleTile(
            label: 'Medication Reminders',
            icon: Icons.medication_rounded,
            value: data.medReminders,
            onChanged: (v) {
              data.medReminders = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Appointment Reminders',
            icon: Icons.event_available_rounded,
            value: data.appointmentReminders,
            onChanged: (v) {
              data.appointmentReminders = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Nearby Accessible Places',
            icon: Icons.place_outlined,
            value: data.nearbyPlaces,
            onChanged: (v) {
              data.nearbyPlaces = v;
              onChanged();
            },
          ),
          SignupToggleTile(
            label: 'Government Benefit Updates',
            icon: Icons.campaign_outlined,
            value: data.benefitUpdates,
            onChanged: (v) {
              data.benefitUpdates = v;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
