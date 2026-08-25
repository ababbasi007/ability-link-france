import 'package:flutter/material.dart';

/// Canonical Assistance Marketplace categories.
class AssistanceType {
  const AssistanceType({
    required this.id,
    required this.label,
    required this.icon,
    required this.shortLabel,
    required this.aliases,
  });

  final String id;
  final String label;
  final IconData icon;
  final String shortLabel;
  final List<String> aliases;

  bool matchesQuery(String q) {
    final needle = q.trim().toLowerCase();
    if (needle.isEmpty) return true;
    if (label.toLowerCase().contains(needle)) return true;
    if (shortLabel.toLowerCase().contains(needle)) return true;
    return aliases.any((a) => a.toLowerCase().contains(needle));
  }
}

const kAssistanceTypes = <AssistanceType>[
  AssistanceType(
    id: 'personal_assistant',
    label: 'Personal Assistant',
    shortLabel: 'Assistant',
    icon: Icons.support_agent_rounded,
    aliases: ['PA', 'personal aide', 'daily living'],
  ),
  AssistanceType(
    id: 'visual_impairment',
    label: 'Visual Impairment Support',
    shortLabel: 'Visual',
    icon: Icons.visibility_rounded,
    aliases: ['guide', 'sighted guide', 'blind support'],
  ),
  AssistanceType(
    id: 'writer_scribe',
    label: 'Writer / Scribe',
    shortLabel: 'Writer',
    icon: Icons.edit_note_rounded,
    aliases: ['scribe', 'note taker', 'writer'],
  ),
  AssistanceType(
    id: 'sign_language',
    label: 'Sign Language Interpreter',
    shortLabel: 'Sign Language',
    icon: Icons.sign_language_rounded,
    aliases: ['ASL', 'interpreter', 'LSF', 'deaf'],
  ),
  AssistanceType(
    id: 'mobility',
    label: 'Mobility Assistant',
    shortLabel: 'Mobility',
    icon: Icons.accessible_rounded,
    aliases: ['wheelchair', 'transfer', 'mobility aid'],
  ),
  AssistanceType(
    id: 'healthcare_assistant',
    label: 'Healthcare Assistant',
    shortLabel: 'Healthcare',
    icon: Icons.medical_services_outlined,
    aliases: ['hospital companion', 'clinic aide', 'meds prompt'],
  ),
  AssistanceType(
    id: 'education_support',
    label: 'Education Support',
    shortLabel: 'Education',
    icon: Icons.school_outlined,
    aliases: ['classroom', 'IEP', 'tutor aide'],
  ),
  AssistanceType(
    id: 'travel_assistant',
    label: 'Travel Assistant',
    shortLabel: 'Travel',
    icon: Icons.flight_outlined,
    aliases: ['airport', 'transit escort', 'travel companion'],
  ),
  AssistanceType(
    id: 'elderly_care',
    label: 'Elderly Care',
    shortLabel: 'Elderly Care',
    icon: Icons.elderly_rounded,
    aliases: ['senior', 'aging', 'companion care'],
  ),
  AssistanceType(
    id: 'home_support',
    label: 'Home Support',
    shortLabel: 'Home Support',
    icon: Icons.home_outlined,
    aliases: ['housework', 'meal prep', 'home help'],
  ),
];

AssistanceType? assistanceTypeById(String id) {
  for (final t in kAssistanceTypes) {
    if (t.id == id) return t;
  }
  return null;
}

AssistanceType? assistanceTypeByShortLabel(String label) {
  final needle = label.trim().toLowerCase();
  for (final t in kAssistanceTypes) {
    if (t.shortLabel.toLowerCase() == needle) return t;
    if (t.label.toLowerCase() == needle) return t;
    if (t.aliases.any((a) => a.toLowerCase() == needle)) return t;
  }
  // Home chip "More" is not a type.
  return null;
}

String assistanceTypeLabel(String id) => assistanceTypeById(id)?.label ?? id;
