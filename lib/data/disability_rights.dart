/// Curated disability rights explainers used by the AI assistant.
class RightsTopic {
  const RightsTopic({
    required this.id,
    required this.title,
    required this.summary,
    required this.points,
    this.keywords = const [],
  });

  final String id;
  final String title;
  final String summary;
  final List<String> points;
  final List<String> keywords;

  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        summary.toLowerCase().contains(q) ||
        keywords.any((k) => q.contains(k.toLowerCase()));
  }
}

const disabilityRightsTopics = <RightsTopic>[
  RightsTopic(
    id: 'reasonable-accommodation',
    title: 'Reasonable accommodation',
    summary:
        'You can ask for changes that remove barriers at work, school, or services — as long as they are reasonable.',
    points: [
      'Examples: ramp access, captions, flexible hours, plain-language forms, quieter rooms.',
      'Ask in writing and keep a copy.',
      'Employers and schools often must consider requests seriously under disability law.',
      'Ability Link Passport helps you describe needs clearly.',
    ],
    keywords: ['accommodation', 'reasonable', 'workplace', 'school', 'adjust'],
  ),
  RightsTopic(
    id: 'access-to-buildings',
    title: 'Access to public buildings and shops',
    summary:
        'Public places should be usable by people with disabilities — entrances, toilets, information, and services.',
    points: [
      'Look for step-free entry, accessible toilets, lifts, and clear signage.',
      'You can report barriers in Ability Map audits and reviews.',
      'In France, ERP rules and accessibility agendas set many building duties.',
      'Ask staff for an alternative service if access is blocked.',
    ],
    keywords: ['building', 'shop', 'toilet', 'ramp', 'elevator', 'erp'],
  ),
  RightsTopic(
    id: 'transport-rights',
    title: 'Accessible transport rights',
    summary:
        'Public transport should offer step-free paths, assistance, and clear information where required.',
    points: [
      'Ask stations about elevators, boarding assistance, and service animals.',
      'Report outages (elevator down) so others are warned.',
      'Use Ability Link step-free routing for walking segments.',
      'Keep proof of disability parking cards when traveling.',
    ],
    keywords: ['transport', 'metro', 'bus', 'train', 'elevator', 'travel'],
  ),
  RightsTopic(
    id: 'healthcare-consent',
    title: 'Healthcare access and consent',
    summary:
        'You have the right to understandable information, consent, and accessible care.',
    points: [
      'Ask for captions, plain language, or a support person in visits.',
      'Share your Passport so clinicians know access needs.',
      'You can refuse treatment you do not understand — ask for clarification.',
      'Emergency care should not depend on ability to climb stairs or hear announcements alone.',
    ],
    keywords: ['doctor', 'hospital', 'consent', 'medical', 'telehealth'],
  ),
  RightsTopic(
    id: 'non-discrimination',
    title: 'Non-discrimination',
    summary:
        'Disability is a protected characteristic in many countries — unfair refusal of service or jobs can be challenged.',
    points: [
      'Document what happened (date, place, names, photos).',
      'Use local equality bodies, MDPH mediators, or legal aid clinics.',
      'Ability Link reviews and barrier reports create evidence trails.',
      'You do not have to accept ableist language or being spoken over.',
    ],
    keywords: ['discrimination', 'rights', 'equality', 'refuse', 'unfair'],
  ),
  RightsTopic(
    id: 'un-crpd',
    title: 'UN Convention on the Rights of Persons with Disabilities',
    summary:
        'An international treaty affirming dignity, autonomy, accessibility, and equal participation.',
    points: [
      'Core ideas: accessibility, independent living, education, work, health.',
      'Many countries (including France) have ratified it.',
      'It guides national laws but local procedures still matter for claims.',
      'Ask Ability Link for country-specific benefit next steps.',
    ],
    keywords: ['un', 'crpd', 'convention', 'international', 'treaty'],
  ),
];

RightsTopic? matchRightsTopic(String query) {
  for (final t in disabilityRightsTopics) {
    if (t.matches(query)) return t;
  }
  return null;
}
