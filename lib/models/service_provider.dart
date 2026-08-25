import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/remote_image_url.dart';

class ServiceProvider {
  const ServiceProvider({
    required this.id,
    required this.name,
    required this.title,
    required this.category,
    required this.specialty,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.priceFrom,
    required this.currency,
    required this.languages,
    required this.services,
    required this.accessibilityTags,
    required this.city,
    required this.photoUrl,
    this.verified = false,
    this.availableNow = false,
    this.yearsExperience = 0,
    this.ownerUid = '',
    this.checklist = const {},
    this.evidence = const [],
    this.hidden = false,
    this.availabilitySlots = const [],
    this.assistanceType = '',
    this.skills = const [],
  });

  final String id;
  final String name;
  final String title; // e.g. MD, PT
  final String
  category; // healthcare, rehab, education, caregiving, assistance, other
  final String specialty;
  final String bio;
  final double rating;
  final int reviewCount;
  final int priceFrom;
  final String currency;
  final List<String> languages;
  final List<String> services;
  final List<String> accessibilityTags;
  final String city;
  final String photoUrl;
  final bool verified;
  final bool availableNow;
  final int yearsExperience;
  final String ownerUid;
  final Map<String, bool> checklist;
  final List<ProviderEvidence> evidence;
  final bool hidden;

  /// Recurring weekly windows shown on caregiver profiles, e.g. "Mon 9–13".
  final List<String> availabilitySlots;

  /// Primary Assistance Marketplace type id (see assistance_taxonomy).
  final String assistanceType;
  final List<String> skills;

  bool get isAssistance =>
      category == 'assistance' ||
      category == 'caregiving' ||
      assistanceType.isNotEmpty;

  int get checklistPercent {
    if (kAccessibilityChecklist.isEmpty) return 0;
    var done = 0;
    for (final key in kAccessibilityChecklist.keys) {
      if (checklist[key] == true) done++;
    }
    return ((done / kAccessibilityChecklist.length) * 100).round();
  }

  String get priceLabel => '$currency$priceFrom+';

  String get categoryLabel {
    switch (category) {
      case 'healthcare':
        return 'Healthcare';
      case 'rehab':
        return 'Rehabilitation';
      case 'education':
        return 'Education';
      case 'caregiving':
        return 'Caregiving';
      case 'assistance':
        return 'Assistance';
      default:
        return 'Services';
    }
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        specialty.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        bio.toLowerCase().contains(q) ||
        assistanceType.toLowerCase().contains(q) ||
        services.any((s) => s.toLowerCase().contains(q)) ||
        skills.any((s) => s.toLowerCase().contains(q)) ||
        accessibilityTags.any((t) => t.toLowerCase().contains(q)) ||
        city.toLowerCase().contains(q) ||
        languages.any((l) => l.toLowerCase().contains(q));
  }

  bool matchesCategory(String filter) {
    if (filter == 'All') return true;
    if (filter == 'Assistance') {
      return isAssistance;
    }
    return categoryLabel == filter || category == filter.toLowerCase();
  }

  bool matchesAssistanceType(String typeId) {
    if (typeId.isEmpty || typeId == 'All') return true;
    if (assistanceType == typeId) return true;
    // Fallback: specialty / services contain the label keywords.
    final t = typeId.replaceAll('_', ' ');
    return specialty.toLowerCase().contains(t) ||
        services.any((s) => s.toLowerCase().contains(t));
  }

  factory ServiceProvider.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ServiceProvider(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Provider',
      title: (d['title'] as String?) ?? '',
      category: (d['category'] as String?) ?? 'other',
      specialty: (d['specialty'] as String?) ?? '',
      bio: (d['bio'] as String?) ?? '',
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      priceFrom: (d['priceFrom'] as num?)?.toInt() ?? 0,
      currency: (d['currency'] as String?) ?? '\$',
      languages: List<String>.from(d['languages'] as List? ?? const []),
      services: List<String>.from(d['services'] as List? ?? const []),
      accessibilityTags: List<String>.from(
        d['accessibilityTags'] as List? ?? const [],
      ),
      city: (d['city'] as String?) ?? '',
      photoUrl: sanitizeRemoteImageUrl((d['photoUrl'] as String?) ?? ''),
      verified: d['verified'] == true,
      availableNow: d['availableNow'] == true,
      yearsExperience: (d['yearsExperience'] as num?)?.toInt() ?? 0,
      ownerUid: (d['ownerUid'] as String?) ?? '',
      checklist: {
        for (final e in Map<String, dynamic>.from(
          d['checklist'] as Map? ?? {},
        ).entries)
          e.key: e.value == true,
      },
      evidence: [
        for (final raw in (d['evidence'] as List? ?? const []))
          if (raw is Map)
            ProviderEvidence(
              title: (raw['title'] as String?) ?? 'Evidence',
              url: (raw['url'] as String?) ?? '',
            ),
      ],
      hidden: d['hidden'] == true,
      availabilitySlots: List<String>.from(
        d['availabilitySlots'] as List? ?? const [],
      ),
      assistanceType: (d['assistanceType'] as String?) ?? '',
      skills: List<String>.from(d['skills'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'title': title,
    'category': category,
    'specialty': specialty,
    'bio': bio,
    'rating': rating,
    'reviewCount': reviewCount,
    'priceFrom': priceFrom,
    'currency': currency,
    'languages': languages,
    'services': services,
    'accessibilityTags': accessibilityTags,
    'city': city,
    'photoUrl': photoUrl,
    'verified': verified,
    'availableNow': availableNow,
    'yearsExperience': yearsExperience,
    'ownerUid': ownerUid,
    'checklist': checklist,
    'evidence': evidence.map((e) => e.toMap()).toList(),
    'hidden': hidden,
    'availabilitySlots': availabilitySlots,
    'assistanceType': assistanceType,
    'skills': skills,
  };
}

class ProviderEnquiry {
  const ProviderEnquiry({
    required this.providerId,
    required this.providerName,
    required this.message,
    required this.preferredSlot,
    required this.contactPhone,
    this.service = '',
  });

  final String providerId;
  final String providerName;
  final String message;
  final String preferredSlot;
  final String contactPhone;
  final String service;
}

class ProviderEvidence {
  const ProviderEvidence({required this.title, required this.url});

  final String title;
  final String url;

  Map<String, dynamic> toMap() => {'title': title, 'url': url};
}

class EnquiryLead {
  const EnquiryLead({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.providerId,
    required this.service,
    required this.message,
    required this.preferredSlot,
    required this.contactPhone,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String uid;
  final String userName;
  final String userEmail;
  final String providerId;
  final String service;
  final String message;
  final String preferredSlot;
  final String contactPhone;
  final String status;
  final DateTime createdAt;

  factory EnquiryLead.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return EnquiryLead(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      userName: (d['userName'] as String?) ?? 'Client',
      userEmail: (d['userEmail'] as String?) ?? '',
      providerId: (d['providerId'] as String?) ?? '',
      service: (d['service'] as String?) ?? '',
      message: (d['message'] as String?) ?? '',
      preferredSlot: (d['preferredSlot'] as String?) ?? '',
      contactPhone: (d['contactPhone'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'pending',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

const kAccessibilityChecklist = <String, String>{
  'stepFreeEntrance': 'Step-free entrance',
  'accessibleToilet': 'Accessible toilet',
  'reservedParking': 'Reserved accessible parking',
  'staffTrained': 'Staff trained on disability support',
  'captionsOnVideo': 'Captions on video sessions',
  'serviceAnimalWelcome': 'Service animals welcome',
  'plainLanguageMaterials': 'Plain-language materials',
  'sensoryFriendlyHours': 'Sensory-friendly hours',
};
