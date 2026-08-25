import 'package:flutter/material.dart';

/// Shared option lists for Accessibility Passport (signup + editor).
class PassportOptions {
  static const profiles = <(IconData, String)>[
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

  static const mobilityAids = <(IconData, String)>[
    (Icons.accessible_rounded, 'Wheelchair'),
    (Icons.directions_walk_rounded, 'Walker'),
    (Icons.elderly_rounded, 'Cane'),
    (Icons.accessibility_new_rounded, 'Crutches'),
    (Icons.personal_injury_outlined, 'Prosthetic'),
    (Icons.block_rounded, 'None'),
    (Icons.more_horiz_rounded, 'Others'),
  ];

  static const assistanceNeeds = [
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

  static const communicationModes = [
    'Spoken conversation',
    'Sign language',
    'Lip reading',
    'Written / chat',
    'AAC / speech device',
    'Easy-read / plain language',
    'Video with interpreter',
  ];

  static const signLanguages = [
    'None',
    'LSF (French)',
    'ASL',
    'BSL',
    'International Sign',
    'Other',
  ];

  static const contactMethods = [
    'Voice call',
    'SMS',
    'Email',
    'Video (sign)',
    'In person with interpreter',
  ];

  static const languages = ['English', 'French', 'Arabic', 'Spanish'];

  static const countries = [
    'France',
    'United States',
    'United Kingdom',
    'Canada',
    'United Arab Emirates',
    'India',
    'Pakistan',
    'Other',
  ];

  static const genders = ['Female', 'Male', 'Non-binary', 'Prefer not to say'];

  static const relations = [
    'Partner',
    'Parent',
    'Sibling',
    'Child',
    'Friend',
    'Caregiver',
    'Other',
  ];

  static const bloodGroups = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  static const insurance = ['Public / National', 'Private', 'Employer', 'None'];
}
