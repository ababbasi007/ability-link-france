import 'package:cloud_firestore/cloud_firestore.dart';

class EducationProgram {
  const EducationProgram({
    required this.id,
    required this.name,
    required this.kind,
    required this.institution,
    required this.city,
    required this.summary,
    required this.description,
    required this.accessFeatures,
    required this.inclusiveFor,
    required this.level,
    this.mode = 'on-campus',
    this.deadlineLabel = '',
    this.awardLabel = '',
    this.verified = false,
    this.institutionId = '',
    this.classrooms = const [],
    this.learningMaterials = const [],
    this.assistiveTech = const [],
    this.applicationSteps = const [],
    this.applicationNotes = '',
    this.signLanguageSupport = false,
    this.specialEducation = false,
    this.online = false,
  });

  final String id;
  final String name;

  /// school | university | institute | course | scholarship |
  /// special_ed | assistive_tech | materials | sign_language
  final String kind;
  final String institution;
  final String city;
  final String summary;
  final String description;
  final List<String> accessFeatures;
  final List<String> inclusiveFor;
  final String level;

  /// on-campus | hybrid | online
  final String mode;
  final String deadlineLabel;
  final String awardLabel;
  final bool verified;
  final String institutionId;
  final List<String> classrooms;
  final List<String> learningMaterials;
  final List<String> assistiveTech;
  final List<String> applicationSteps;
  final String applicationNotes;
  final bool signLanguageSupport;
  final bool specialEducation;
  final bool online;

  String get kindLabel => switch (kind) {
    'university' => 'University',
    'institute' => 'Training institute',
    'course' => 'Online / course',
    'scholarship' => 'Scholarship',
    'special_ed' => 'Special education',
    'assistive_tech' => 'Assistive technology',
    'materials' => 'Learning materials',
    'sign_language' => 'Sign-language support',
    'school' => 'Accessible school',
    _ => 'Education',
  };

  String get modeLabel => switch (mode) {
    'online' => 'Online',
    'hybrid' => 'Hybrid',
    _ => 'On campus',
  };

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        institution.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        summary.toLowerCase().contains(q) ||
        kind.toLowerCase().contains(q) ||
        level.toLowerCase().contains(q) ||
        accessFeatures.any((f) => f.toLowerCase().contains(q)) ||
        classrooms.any((f) => f.toLowerCase().contains(q)) ||
        learningMaterials.any((f) => f.toLowerCase().contains(q)) ||
        assistiveTech.any((f) => f.toLowerCase().contains(q));
  }

  factory EducationProgram.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final mode = (d['mode'] as String?) ?? 'on-campus';
    return EducationProgram(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Program',
      kind: (d['kind'] as String?) ?? 'school',
      institution: (d['institution'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      summary: (d['summary'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      accessFeatures: List<String>.from(
        d['accessFeatures'] as List? ?? const [],
      ),
      inclusiveFor: List<String>.from(d['inclusiveFor'] as List? ?? const []),
      level: (d['level'] as String?) ?? '',
      mode: mode,
      deadlineLabel: (d['deadlineLabel'] as String?) ?? '',
      awardLabel: (d['awardLabel'] as String?) ?? '',
      verified: d['verified'] == true,
      institutionId: (d['institutionId'] as String?) ?? '',
      classrooms: List<String>.from(d['classrooms'] as List? ?? const []),
      learningMaterials: List<String>.from(
        d['learningMaterials'] as List? ?? const [],
      ),
      assistiveTech: List<String>.from(d['assistiveTech'] as List? ?? const []),
      applicationSteps: List<String>.from(
        d['applicationSteps'] as List? ?? const [],
      ),
      applicationNotes: (d['applicationNotes'] as String?) ?? '',
      signLanguageSupport: d['signLanguageSupport'] == true,
      specialEducation:
          d['specialEducation'] == true ||
          (d['kind'] as String?) == 'special_ed',
      online: d['online'] == true || mode == 'online',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'kind': kind,
    'institution': institution,
    'city': city,
    'summary': summary,
    'description': description,
    'accessFeatures': accessFeatures,
    'inclusiveFor': inclusiveFor,
    'level': level,
    'mode': mode,
    'deadlineLabel': deadlineLabel,
    'awardLabel': awardLabel,
    'verified': verified,
    'institutionId': institutionId,
    'classrooms': classrooms,
    'learningMaterials': learningMaterials,
    'assistiveTech': assistiveTech,
    'applicationSteps': applicationSteps,
    'applicationNotes': applicationNotes,
    'signLanguageSupport': signLanguageSupport,
    'specialEducation': specialEducation,
    'online': online,
  };
}

class EducationInstitution {
  const EducationInstitution({
    required this.id,
    required this.name,
    required this.kind,
    required this.city,
    required this.summary,
    required this.description,
    required this.accessFeatures,
    required this.disabilityServices,
    this.classrooms = const [],
    this.verified = false,
    this.photoUrl = '',
    this.websiteLabel = '',
  });

  final String id;
  final String name;

  /// school | university | institute | academy
  final String kind;
  final String city;
  final String summary;
  final String description;
  final List<String> accessFeatures;
  final List<String> disabilityServices;
  final List<String> classrooms;
  final bool verified;
  final String photoUrl;
  final String websiteLabel;

  String get kindLabel => switch (kind) {
    'university' => 'University',
    'institute' => 'Training institute',
    'academy' => 'Academy',
    _ => 'School',
  };

  factory EducationInstitution.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return EducationInstitution(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Institution',
      kind: (d['kind'] as String?) ?? 'school',
      city: (d['city'] as String?) ?? '',
      summary: (d['summary'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      accessFeatures: List<String>.from(
        d['accessFeatures'] as List? ?? const [],
      ),
      disabilityServices: List<String>.from(
        d['disabilityServices'] as List? ?? const [],
      ),
      classrooms: List<String>.from(d['classrooms'] as List? ?? const []),
      verified: d['verified'] == true,
      photoUrl: (d['photoUrl'] as String?) ?? '',
      websiteLabel: (d['websiteLabel'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'kind': kind,
    'city': city,
    'summary': summary,
    'description': description,
    'accessFeatures': accessFeatures,
    'disabilityServices': disabilityServices,
    'classrooms': classrooms,
    'verified': verified,
    'photoUrl': photoUrl,
    'websiteLabel': websiteLabel,
  };
}

class EducationInterest {
  const EducationInterest({
    required this.id,
    required this.uid,
    required this.programId,
    required this.programName,
    required this.kind,
    required this.status,
    required this.note,
    required this.createdAt,
    this.matchScore = 0,
  });

  final String id;
  final String uid;
  final String programId;
  final String programName;
  final String kind;

  /// interested | applied | withdrawn | bookmarked
  final String status;
  final String note;
  final DateTime createdAt;
  final int matchScore;

  factory EducationInterest.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return EducationInterest(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      programId: (d['programId'] as String?) ?? '',
      programName: (d['programName'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'school',
      status: (d['status'] as String?) ?? 'interested',
      note: (d['note'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      matchScore: (d['matchScore'] as num?)?.toInt() ?? 0,
    );
  }
}
