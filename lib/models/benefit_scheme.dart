import 'package:cloud_firestore/cloud_firestore.dart';

/// Categories used across the Government Benefits module.
const kBenefitCategories = <String, String>{
  'disability': 'Disability',
  'financial': 'Financial',
  'healthcare': 'Healthcare',
  'education': 'Education',
  'employment': 'Employment',
  'transport': 'Transport',
  'housing': 'Housing',
  'tax': 'Tax',
  'certificate': 'Certificates',
};

class BenefitScheme {
  const BenefitScheme({
    required this.id,
    required this.name,
    required this.country,
    required this.summary,
    required this.whoFor,
    required this.steps,
    required this.documents,
    this.agency = '',
    this.url = '',
    this.tags = const [],
    this.category = 'disability',
    this.eligibilityHints = const [],
    this.deadlineLabel = '',
    this.reminderDays = 0,
    this.phone = '',
    this.email = '',
    this.officeHint = '',
  });

  final String id;
  final String name;
  final String country;
  final String summary;
  final String whoFor;
  final List<String> steps;
  final List<String> documents;
  final String agency;
  final String url;
  final List<String> tags;
  final String category;
  final List<String> eligibilityHints;
  final String deadlineLabel;
  final int reminderDays;
  final String phone;
  final String email;
  final String officeHint;

  String get categoryLabel => kBenefitCategories[category] ?? category;

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        summary.toLowerCase().contains(q) ||
        country.toLowerCase().contains(q) ||
        whoFor.toLowerCase().contains(q) ||
        agency.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        categoryLabel.toLowerCase().contains(q) ||
        tags.any((t) => t.toLowerCase().contains(q)) ||
        eligibilityHints.any((t) => t.toLowerCase().contains(q));
  }

  bool matchesProfile(List<String> accessibilityProfiles) {
    if (accessibilityProfiles.isEmpty) return true;
    final joined = accessibilityProfiles.join(' ').toLowerCase();
    return tags.any((t) => joined.contains(t.toLowerCase())) ||
        whoFor.toLowerCase().contains('all') ||
        whoFor.toLowerCase().contains('disability');
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'country': country,
    'summary': summary,
    'whoFor': whoFor,
    'steps': steps,
    'documents': documents,
    'agency': agency,
    'url': url,
    'tags': tags,
    'category': category,
    'eligibilityHints': eligibilityHints,
    'deadlineLabel': deadlineLabel,
    'reminderDays': reminderDays,
    'phone': phone,
    'email': email,
    'officeHint': officeHint,
  };

  factory BenefitScheme.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BenefitScheme(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Benefit',
      country: (d['country'] as String?) ?? '',
      summary: (d['summary'] as String?) ?? '',
      whoFor: (d['whoFor'] as String?) ?? '',
      steps: ((d['steps'] as List?) ?? const []).map((e) => '$e').toList(),
      documents: ((d['documents'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
      agency: (d['agency'] as String?) ?? '',
      url: (d['url'] as String?) ?? '',
      tags: ((d['tags'] as List?) ?? const []).map((e) => '$e').toList(),
      category: (d['category'] as String?) ?? 'disability',
      eligibilityHints: ((d['eligibilityHints'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
      deadlineLabel: (d['deadlineLabel'] as String?) ?? '',
      reminderDays: (d['reminderDays'] as num?)?.toInt() ?? 0,
      phone: (d['phone'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      officeHint: (d['officeHint'] as String?) ?? '',
    );
  }
}

class GovernmentOffice {
  const GovernmentOffice({
    required this.id,
    required this.name,
    required this.agency,
    required this.city,
    required this.address,
    required this.phone,
    required this.email,
    required this.hours,
    required this.services,
    this.lat = 0,
    this.lng = 0,
    this.accessibleNotes = '',
    this.url = '',
  });

  final String id;
  final String name;
  final String agency;
  final String city;
  final String address;
  final String phone;
  final String email;
  final String hours;
  final List<String> services;
  final double lat;
  final double lng;
  final String accessibleNotes;
  final String url;

  bool get hasCoords => lat != 0 || lng != 0;

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        agency.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        address.toLowerCase().contains(q) ||
        services.any((s) => s.toLowerCase().contains(q));
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'agency': agency,
    'city': city,
    'address': address,
    'phone': phone,
    'email': email,
    'hours': hours,
    'services': services,
    'lat': lat,
    'lng': lng,
    'accessibleNotes': accessibleNotes,
    'url': url,
  };

  factory GovernmentOffice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return GovernmentOffice(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Office',
      agency: (d['agency'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      address: (d['address'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      hours: (d['hours'] as String?) ?? '',
      services: ((d['services'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      accessibleNotes: (d['accessibleNotes'] as String?) ?? '',
      url: (d['url'] as String?) ?? '',
    );
  }
}

class BenefitApplication {
  const BenefitApplication({
    required this.id,
    required this.uid,
    required this.schemeId,
    required this.schemeName,
    required this.category,
    required this.status,
    required this.createdAt,
    this.note = '',
    this.deadlineLabel = '',
    this.remindAt,
    this.agency = '',
  });

  final String id;
  final String uid;
  final String schemeId;
  final String schemeName;
  final String category;

  /// draft | submitted | in_review | approved | denied | withdrawn
  final String status;
  final DateTime createdAt;
  final String note;
  final String deadlineLabel;
  final DateTime? remindAt;
  final String agency;

  factory BenefitApplication.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final created = d['createdAt'];
    final remind = d['remindAt'];
    return BenefitApplication(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      schemeId: (d['schemeId'] as String?) ?? '',
      schemeName: (d['schemeName'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'draft',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      note: (d['note'] as String?) ?? '',
      deadlineLabel: (d['deadlineLabel'] as String?) ?? '',
      remindAt: remind is Timestamp ? remind.toDate() : null,
      agency: (d['agency'] as String?) ?? '',
    );
  }
}

class EligibilityResult {
  const EligibilityResult({
    required this.scheme,
    required this.score,
    required this.likelyEligible,
    required this.reasons,
  });

  final BenefitScheme scheme;
  final int score;
  final bool likelyEligible;
  final List<String> reasons;
}
