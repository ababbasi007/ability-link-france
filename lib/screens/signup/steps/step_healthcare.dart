import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepHealthcare extends StatelessWidget {
  const StepHealthcare({
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
      step: 8,
      title: 'Healthcare Profile',
      subtitle: 'Optional, but highly recommended.',
      onBack: onBack,
      onNext: onNext,
      onSkip: onSkip,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SignupTextField(
            hint: 'Doctor / Physician',
            icon: Icons.medical_services_outlined,
            initialValue: data.doctor,
            onChanged: (v) => data.doctor = v,
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Hospital / Clinic',
            icon: Icons.local_hospital_outlined,
            initialValue: data.hospital,
            onChanged: (v) => data.hospital = v,
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Medical Conditions',
            icon: Icons.healing_outlined,
            initialValue: data.conditions,
            onChanged: (v) => data.conditions = v,
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Allergies',
            icon: Icons.warning_amber_rounded,
            initialValue: data.allergies,
            onChanged: (v) => data.allergies = v,
          ),
          const SizedBox(height: 12),
          SignupTextField(
            hint: 'Current Medications',
            icon: Icons.medication_outlined,
            initialValue: data.medications,
            onChanged: (v) => data.medications = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SignupDropdown(
                  hint: 'Blood Group',
                  icon: Icons.bloodtype_outlined,
                  value: data.bloodGroup,
                  items: const [
                    'A+',
                    'A-',
                    'B+',
                    'B-',
                    'AB+',
                    'AB-',
                    'O+',
                    'O-',
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      data.bloodGroup = v;
                      onChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SignupDropdown(
                  hint: 'Insurance (Optional)',
                  icon: Icons.verified_user_outlined,
                  value: data.insurance,
                  items: const [
                    'Public / National',
                    'Private',
                    'Employer',
                    'None',
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      data.insurance = v;
                      onChanged();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Emergency Medical Notes (Optional)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1B4B),
            ),
          ),
          const SizedBox(height: 8),
          SignupTextField(
            hint: 'Any critical notes for first responders…',
            maxLines: 3,
            initialValue: data.emergencyNotes,
            onChanged: (v) => data.emergencyNotes = v,
          ),
        ],
      ),
    );
  }
}
