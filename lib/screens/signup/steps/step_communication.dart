import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../data/passport_options.dart';
import '../signup_data.dart';
import '../signup_flow_screen.dart';
import '../signup_shared.dart';

class StepCommunication extends StatelessWidget {
  const StepCommunication({
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
      step: 5,
      total: 11,
      title: 'Communication preferences',
      subtitle: 'How you prefer to communicate — stored on your Passport.',
      onBack: onBack,
      onNext: onNext,
      onSkip: onSkip,
      child: CommunicationPrefsForm(data: data, onChanged: onChanged),
    );
  }
}

class CommunicationPrefsForm extends StatelessWidget {
  const CommunicationPrefsForm({
    super.key,
    required this.data,
    required this.onChanged,
  });

  final SignupData data;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How you communicate',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mode in PassportOptions.communicationModes)
              FilterChip(
                label: Text(mode),
                selected: data.communicationModes.contains(mode),
                onSelected: (v) {
                  if (v) {
                    data.communicationModes.add(mode);
                  } else {
                    data.communicationModes.remove(mode);
                  }
                  onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        SignupDropdown(
          hint: 'Sign language',
          icon: Icons.sign_language_outlined,
          value: data.signLanguage,
          items: PassportOptions.signLanguages,
          onChanged: (v) {
            if (v != null) {
              data.signLanguage = v;
              onChanged();
            }
          },
        ),
        const SizedBox(height: 12),
        SignupDropdown(
          hint: 'Preferred contact method',
          icon: Icons.contact_phone_outlined,
          value: data.preferredContactMethod,
          items: PassportOptions.contactMethods,
          onChanged: (v) {
            if (v != null) {
              data.preferredContactMethod = v;
              onChanged();
            }
          },
        ),
        const SizedBox(height: 12),
        YesNoToggle(
          label: 'Need a sign language interpreter?',
          value: data.needsInterpreter,
          onChanged: (v) {
            data.needsInterpreter = v;
            onChanged();
          },
        ),
        YesNoToggle(
          label: 'Need captions / subtitles?',
          value: data.needsCaptions,
          onChanged: (v) {
            data.needsCaptions = v;
            data.captions = v;
            onChanged();
          },
        ),
        YesNoToggle(
          label: 'Prefer easy-read / plain language?',
          value: data.easyRead,
          onChanged: (v) {
            data.easyRead = v;
            data.simpleLanguage = v;
            onChanged();
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Notes for staff (optional)',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 8),
        SignupTextField(
          hint: 'e.g. speak slowly, use LSF, write things down…',
          maxLines: 3,
          initialValue: data.communicationNotes,
          onChanged: (v) => data.communicationNotes = v,
        ),
      ],
    );
  }
}
