import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.role,
    required this.passportId,
    required this.onboardingComplete,
    this.personal = const {},
    this.contact = const {},
    this.accessibility = const {},
    this.healthcare = const {},
    this.preferences = const {},
    this.services = const {},
    this.createdAt,
  });

  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? photoUrl;
  final String? role;
  final String passportId;
  final bool onboardingComplete;
  final Map<String, dynamic> personal;
  final Map<String, dynamic> contact;
  final Map<String, dynamic> accessibility;
  final Map<String, dynamic> healthcare;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> services;
  final DateTime? createdAt;

  String get firstName {
    final fromPersonal = (personal['firstName'] as String?)?.trim() ?? '';
    if (fromPersonal.isNotEmpty) return fromPersonal;
    if (fullName.trim().isEmpty) return 'there';
    return fullName.trim().split(RegExp(r'\s+')).first;
  }

  String get displayName {
    if (fullName.trim().isNotEmpty) return fullName.trim();
    final first = (personal['firstName'] as String?)?.trim() ?? '';
    final last = (personal['lastName'] as String?)?.trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Ability Link user';
  }

  String get city {
    final c = (contact['city'] as String?)?.trim() ?? '';
    final country = (contact['country'] as String?)?.trim() ?? '';
    if (c.isNotEmpty && country.isNotEmpty) return '$c, $country';
    if (c.isNotEmpty) return c;
    if (country.isNotEmpty) return country;
    return 'Location not set';
  }

  String get mobile {
    final code = (contact['countryCode'] as String?)?.trim() ?? '';
    final m = (contact['mobile'] as String?)?.trim() ?? '';
    if (m.isNotEmpty) return '$code $m'.trim();
    if (phone.trim().isNotEmpty) return phone.trim();
    return 'Not set';
  }

  String get dateOfBirth =>
      (personal['dateOfBirth'] as String?)?.trim().isNotEmpty == true
      ? personal['dateOfBirth'] as String
      : 'Not set';

  String get preferredLanguage =>
      (personal['preferredLanguage'] as String?)?.trim().isNotEmpty == true
      ? personal['preferredLanguage'] as String
      : 'English';

  List<String> get accessibilityProfiles {
    final raw = accessibility['profiles'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  List<String> get assistanceNeeds {
    final raw = accessibility['assistanceNeeds'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  Map<String, dynamic> get communication {
    final c = accessibility['communication'];
    if (c is Map) return Map<String, dynamic>.from(c);
    return const {};
  }

  List<String> get communicationModes {
    final raw = communication['modes'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  String get signLanguage {
    final v = (communication['signLanguage'] as String?)?.trim() ?? '';
    return v.isEmpty ? 'None' : v;
  }

  String get preferredContactMethod {
    final v =
        (communication['preferredContactMethod'] as String?)?.trim() ?? '';
    return v.isEmpty ? 'Voice call' : v;
  }

  bool get needsCaptions =>
      communication['needsCaptions'] == true || preferences['captions'] == true;

  bool get needsInterpreter => communication['needsInterpreter'] == true;

  bool get easyRead =>
      communication['easyRead'] == true ||
      preferences['simpleLanguage'] == true;

  String get communicationNotes =>
      (communication['notes'] as String?)?.trim() ?? '';

  String get communicationSummary {
    final parts = <String>[
      if (communicationModes.isNotEmpty) communicationModes.join(', '),
      if (signLanguage != 'None') signLanguage,
      if (needsInterpreter) 'Interpreter',
      if (needsCaptions) 'Captions',
      preferredContactMethod,
    ];
    if (parts.isEmpty) return 'Not set';
    return parts.join(' · ');
  }

  String get mobilityAid =>
      (accessibility['mobilityAid'] as String?)?.trim() ?? '';

  bool get needCaregiver => accessibility['needCaregiver'] == true;

  Map<String, dynamic> get emergency {
    final e = contact['emergency'];
    if (e is Map) return Map<String, dynamic>.from(e);
    return const {};
  }

  String get bloodGroup =>
      (healthcare['bloodGroup'] as String?)?.trim().isNotEmpty == true
      ? healthcare['bloodGroup'] as String
      : '—';

  String get memberSinceLabel {
    final d = createdAt;
    if (d == null) return 'Member';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Member since ${months[d.month - 1]} ${d.year}';
  }

  /// Rough completeness from onboarding fields present in Firestore.
  int get profileStrengthPercent {
    var score = 0;
    var total = 0;

    void check(bool ok) {
      total++;
      if (ok) score++;
    }

    check(displayName.isNotEmpty && displayName != 'Ability Link user');
    check(email.isNotEmpty);
    check(mobile != 'Not set');
    check(dateOfBirth != 'Not set');
    check(city != 'Location not set');
    check(accessibilityProfiles.isNotEmpty);
    check(mobilityAid.isNotEmpty);
    check(communicationModes.isNotEmpty);
    check((emergency['name'] as String?)?.trim().isNotEmpty == true);
    check((emergency['phone'] as String?)?.trim().isNotEmpty == true);
    check((healthcare['bloodGroup'] as String?)?.trim().isNotEmpty == true);
    check(onboardingComplete);

    if (total == 0) return 0;
    return ((score / total) * 100).round().clamp(0, 100);
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile.fromMap(doc.id, data);
  }

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    DateTime? created;
    final rawCreated = data['createdAt'];
    if (rawCreated is Timestamp) {
      created = rawCreated.toDate();
    }

    Map<String, dynamic> asMap(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v);
      return {};
    }

    final personal = asMap(data['personal']);
    final contact = asMap(data['contact']);
    final fullName = (data['fullName'] as String?)?.trim() ?? '';
    final first = (personal['firstName'] as String?)?.trim() ?? '';
    final last = (personal['lastName'] as String?)?.trim() ?? '';
    final computedName = fullName.isNotEmpty ? fullName : '$first $last'.trim();

    final contactEmail = (contact['email'] as String?)?.trim() ?? '';
    final topEmail = (data['email'] as String?)?.trim() ?? '';

    return UserProfile(
      uid: uid,
      fullName: computedName,
      email: topEmail.isNotEmpty ? topEmail : contactEmail,
      phone: (data['phone'] as String?)?.trim() ?? '',
      photoUrl: data['photoUrl'] as String?,
      role: data['role'] as String?,
      passportId: (data['passportId'] as String?)?.trim().isNotEmpty == true
          ? data['passportId'] as String
          : 'AL-${uid.substring(0, uid.length.clamp(0, 6)).toUpperCase()}',
      onboardingComplete: data['onboardingComplete'] == true,
      personal: personal,
      contact: contact,
      accessibility: asMap(data['accessibility']),
      healthcare: asMap(data['healthcare']),
      preferences: asMap(data['preferences']),
      services: asMap(data['services']),
      createdAt: created,
    );
  }

  static UserProfile empty(String uid) => UserProfile(
    uid: uid,
    fullName: '',
    email: '',
    phone: '',
    photoUrl: null,
    role: null,
    passportId: 'AL-——',
    onboardingComplete: false,
  );

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    String? role,
    String? passportId,
    bool? onboardingComplete,
    Map<String, dynamic>? personal,
    Map<String, dynamic>? contact,
    Map<String, dynamic>? accessibility,
    Map<String, dynamic>? healthcare,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? services,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      passportId: passportId ?? this.passportId,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      personal: personal ?? this.personal,
      contact: contact ?? this.contact,
      accessibility: accessibility ?? this.accessibility,
      healthcare: healthcare ?? this.healthcare,
      preferences: preferences ?? this.preferences,
      services: services ?? this.services,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
