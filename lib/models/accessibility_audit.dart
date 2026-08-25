import 'package:cloud_firestore/cloud_firestore.dart';

import 'accessible_service.dart';

class AuditItemDef {
  const AuditItemDef(
    this.id,
    this.label, {
    this.kind = AuditFieldKind.toggle,
    this.options,
    this.suffix,
  });

  final String id;
  final String label;
  final AuditFieldKind kind;
  final List<String>? options;
  final String? suffix;
}

enum AuditFieldKind { toggle, counter, dropdown, text }

class AuditSectionDef {
  const AuditSectionDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
    this.photos = false,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<AuditItemDef> items;
  final bool photos;
}

class AuditMeasurementDef {
  const AuditMeasurementDef(this.id, this.label, this.unit, this.hint);
  final String id;
  final String label;
  final String unit;
  final String hint;
}

/// 10-step Accessibility Audit matching the Audit a Place wizard.
abstract final class AuditCatalog {
  static const steps = <String>[
    'Basic Information',
    'Parking & Arrival',
    'Entrance & Building',
    'Mobility Accessibility',
    'Accessible Toilet',
    'Visual Accessibility',
    'Hearing & Communication',
    'Cognitive Accessibility',
    'Services & Emergency',
    'Review & Submit',
  ];

  static const nextLabels = <String>[
    'Next: Parking & Arrival',
    'Next: Entrance & Building',
    'Next: Mobility Accessibility',
    'Next: Accessible Toilet',
    'Next: Visual Accessibility',
    'Next: Hearing & Communication',
    'Next: Cognitive Accessibility',
    'Next: Services & Emergency',
    'Next: Review & Submit',
    'Submit Audit',
  ];

  static const categories = [
    'Restaurant / Cafe',
    'Hospital',
    'Library',
    'Shopping',
    'Transit',
    'Park',
    'Other',
  ];

  static const checklist = <AuditSectionDef>[
    AuditSectionDef(
      id: 'parking',
      title: 'Accessible Arrival & Parking',
      subtitle: 'Evaluate exterior access from street to door.',
      photos: true,
      items: [
        AuditItemDef('available', 'Accessible parking available?'),
        AuditItemDef(
          'spaces',
          'Number of accessible spaces',
          kind: AuditFieldKind.counter,
        ),
        AuditItemDef(
          'distance',
          'Distance from parking to entrance',
          kind: AuditFieldKind.dropdown,
          options: [
            'Under 10 meters',
            '10-20 meters',
            '20-50 meters',
            'Over 50 meters',
          ],
        ),
        AuditItemDef('kerbRamp', 'Kerb-ramp / curb cut available?'),
        AuditItemDef('dropOff', 'Accessible drop-off point?'),
        AuditItemDef(
          'dropOffDistance',
          'Drop-off distance to entrance',
          kind: AuditFieldKind.dropdown,
          options: [
            'At entrance (0–5 m)',
            'Under 15 meters',
            '15–30 meters',
            'Over 30 meters',
          ],
        ),
        AuditItemDef(
          'dropOffLocation',
          'Drop-off location / landmark',
          kind: AuditFieldKind.text,
          suffix: 'e.g. East curb · Door B',
        ),
        AuditItemDef('marked', 'Accessible spaces clearly marked?'),
        AuditItemDef(
          'surface',
          'Parking surface condition',
          kind: AuditFieldKind.dropdown,
          options: ['Excellent', 'Good', 'Fair', 'Poor'],
        ),
        AuditItemDef('evParking', 'Accessible EV parking spaces?'),
        AuditItemDef(
          'evSpaces',
          'Number of accessible EV spaces',
          kind: AuditFieldKind.counter,
        ),
        AuditItemDef('evCharging', 'Accessible EV charging available?'),
        AuditItemDef(
          'fee',
          'Parking cost',
          kind: AuditFieldKind.dropdown,
          options: ['Free', 'Paid', 'Mixed', 'Unknown'],
        ),
      ],
    ),
    AuditSectionDef(
      id: 'entrance',
      title: 'Entrance & Building Access',
      subtitle: 'Primary entrance, doors, ramps, and elevators.',
      photos: true,
      items: [
        AuditItemDef('stepFree', 'Step-free entrance?'),
        AuditItemDef('ramp', 'Ramp available?'),
        AuditItemDef(
          'rampGradient',
          'Ramp gradient',
          kind: AuditFieldKind.text,
          suffix: 'e.g. 1:12 (8.3%)',
        ),
        AuditItemDef(
          'doorWidth',
          'Main door width',
          kind: AuditFieldKind.text,
          suffix: 'cm',
        ),
        AuditItemDef(
          'doorType',
          'Door type',
          kind: AuditFieldKind.dropdown,
          options: ['Automatic', 'Power-assist', 'Manual', 'Revolving'],
        ),
        AuditItemDef(
          'threshold',
          'Threshold height',
          kind: AuditFieldKind.text,
          suffix: 'cm',
        ),
        AuditItemDef('elevator', 'Elevator available?'),
        AuditItemDef(
          'elevatorDims',
          'Elevator dimensions',
          kind: AuditFieldKind.text,
          suffix: 'e.g. 110 cm x 140 cm',
        ),
        AuditItemDef('elevatorControls', 'Elevator controls accessible?'),
        AuditItemDef('routeThroughout', 'Accessible route throughout?'),
      ],
    ),
    AuditSectionDef(
      id: 'mobility',
      title: 'Mobility Accessibility',
      subtitle: 'Interior movement, seating, and surfaces.',
      items: [
        AuditItemDef('corridors', 'Corridors wide enough?'),
        AuditItemDef('turning', 'Turning space available?'),
        AuditItemDef('counters', 'Accessible counters?'),
        AuditItemDef('seating', 'Accessible seating?'),
        AuditItemDef('handrails', 'Stairs have handrails?'),
        AuditItemDef('altStairs', 'Alternative to stairs?'),
        AuditItemDef('floorSafe', 'Floor surface is safe?'),
        AuditItemDef('obstacles', 'Path is free of obstacles?'),
        AuditItemDef('restAreas', 'Rest areas available?'),
      ],
    ),
    AuditSectionDef(
      id: 'toilet',
      title: 'Accessible Toilet',
      subtitle: 'Restroom size, fittings, and alarms.',
      photos: true,
      items: [
        AuditItemDef('available', 'Accessible toilet available?'),
        AuditItemDef(
          'doorWidth',
          'Door width',
          kind: AuditFieldKind.text,
          suffix: 'cm',
        ),
        AuditItemDef(
          'turning',
          'Turning radius',
          kind: AuditFieldKind.text,
          suffix: 'cm',
        ),
        AuditItemDef('grabRails', 'Grab rails available?'),
        AuditItemDef('transfer', 'Transfer space beside toilet?'),
        AuditItemDef('sink', 'Accessible sink?'),
        AuditItemDef('alarm', 'Emergency alarm?'),
        AuditItemDef('babyChange', 'Baby changing facility?'),
        AuditItemDef('signage', 'Toilet signage clear?'),
      ],
    ),
    AuditSectionDef(
      id: 'visual',
      title: 'Visual Accessibility',
      subtitle: 'Tactile, contrast, lighting, and guide dogs.',
      items: [
        AuditItemDef('tactile', 'Tactile pathways?'),
        AuditItemDef('braille', 'Tactile / Braille signage?'),
        AuditItemDef('contrast', 'High-contrast signage?'),
        AuditItemDef('largePrint', 'Large print information?'),
        AuditItemDef('lighting', 'Good lighting?'),
        AuditItemDef('obstaclesMarked', 'Obstacles marked?'),
        AuditItemDef('stairEdge', 'Stair-edge contrast?'),
        AuditItemDef('audible', 'Audible announcements?'),
        AuditItemDef('guideDog', 'Guide dog permitted?'),
      ],
    ),
    AuditSectionDef(
      id: 'hearing',
      title: 'Hearing & Communication',
      subtitle: 'Loops, captions, alerts, and language access.',
      items: [
        AuditItemDef('loop', 'Hearing loop?'),
        AuditItemDef('captions', 'Captioned screens?'),
        AuditItemDef('visualAnnouncements', 'Visual announcements?'),
        AuditItemDef('signLanguage', 'Sign language support?'),
        AuditItemDef('staffTraining', 'Staff training?'),
        AuditItemDef('textChat', 'Text / chat contact?'),
        AuditItemDef('emergencyAlerts', 'Accessible emergency alerts?'),
        AuditItemDef('quietArea', 'Quiet communication area?'),
      ],
    ),
    AuditSectionDef(
      id: 'cognitive',
      title: 'Cognitive Accessibility',
      subtitle: 'Wayfinding, sensory load, and predictable layout.',
      items: [
        AuditItemDef('simpleSignage', 'Simple signage?'),
        AuditItemDef('easyInstructions', 'Easy instructions?'),
        AuditItemDef('navigation', 'Clear navigation?'),
        AuditItemDef('quiet', 'Quiet areas?'),
        AuditItemDef('lowSensory', 'Low sensory areas?'),
        AuditItemDef(
          'calmWaitingRoom',
          'Calm waiting room tags / low-sensory waiting area?',
        ),
        AuditItemDef('crowding', 'Crowding information available?'),
        AuditItemDef('layout', 'Predictable layout?'),
        AuditItemDef('awareness', 'Disability awareness training?'),
        AuditItemDef('visualInstructions', 'Visual instructions?'),
        AuditItemDef('flexibleWait', 'Flexible waiting?'),
      ],
    ),
    AuditSectionDef(
      id: 'staff',
      title: 'Services & Staff Support',
      subtitle: 'Assistance and inclusive service.',
      items: [
        AuditItemDef('wheelchairAssist', 'Wheelchair assistance'),
        AuditItemDef('personalAssist', 'Personal assistance'),
        AuditItemDef('priority', 'Priority service'),
        AuditItemDef(
          'receptionDesk',
          'Accessible reception desk / front counter',
        ),
        AuditItemDef('serviceAnimal', 'Service animals welcome'),
        AuditItemDef('familyFriendly', 'Family / child friendly'),
        AuditItemDef('petFriendly', 'Pet friendly (not only service animals)'),
        AuditItemDef('formats', 'Alternate formats'),
      ],
    ),
    AuditSectionDef(
      id: 'emergency',
      title: 'Emergency Accessibility',
      subtitle: 'Alarms, exits, and assisted evacuation.',
      items: [
        AuditItemDef('exits', 'Accessible emergency exits'),
        AuditItemDef('visualAlarms', 'Visual fire alarms'),
        AuditItemDef('audibleAlarms', 'Audible alarms'),
        AuditItemDef('evacAssist', 'Evacuation assistance'),
        AuditItemDef('refuge', 'Refuge area / evac chair'),
      ],
    ),
  ];

  static const measurements = <AuditMeasurementDef>[];

  static AuditSectionDef section(String id) =>
      checklist.firstWhere((s) => s.id == id);

  static List<AuditItemDef> togglesOf(AuditSectionDef section) =>
      section.items.where((i) => i.kind == AuditFieldKind.toggle).toList();
}

class AuditPhoto {
  const AuditPhoto({required this.uri, this.caption = ''});

  final String uri;
  final String caption;

  bool get isNetwork => uri.startsWith('http://') || uri.startsWith('https://');

  Map<String, dynamic> toMap() => {'uri': uri, 'caption': caption};

  factory AuditPhoto.fromMap(Map<String, dynamic> m) => AuditPhoto(
    uri: (m['uri'] as String?) ?? '',
    caption: (m['caption'] as String?) ?? '',
  );
}

class AccessibilityAudit {
  const AccessibilityAudit({
    required this.id,
    required this.uid,
    required this.auditorName,
    required this.placeId,
    required this.placeName,
    required this.placeAddress,
    required this.category,
    this.phone = '',
    this.hours = '',
    this.website = '',
    this.gps = '',
    this.confirmed = false,
    this.status = 'draft',
    this.answers = const {},
    this.sectionNotes = const {},
    this.photos = const [],
    this.measurements = const {},
    this.auditorNotes = '',
    this.score = 0,
    this.sectionScores = const {},
    this.seeded = false,
    this.createdAt,
    this.updatedAt,
    this.submittedAt,
  });

  final String id;
  final String uid;
  final String auditorName;
  final String placeId;
  final String placeName;
  final String placeAddress;
  final String category;
  final String phone;
  final String hours;
  final String website;
  final String gps;
  final bool confirmed;
  final String status; // draft | submitted
  /// Keys: `{sectionId}.{itemId}` → yes | partial | no | na
  final Map<String, String> answers;
  final Map<String, String> sectionNotes;
  final List<AuditPhoto> photos;
  final Map<String, String> measurements;
  final String auditorNotes;
  final int score;
  final Map<String, int> sectionScores;
  final bool seeded;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? submittedAt;

  bool get isDraft => status != 'submitted';

  factory AccessibilityAudit.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return AccessibilityAudit(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      auditorName: (d['auditorName'] as String?) ?? 'Auditor',
      placeId: (d['placeId'] as String?) ?? '',
      placeName: (d['placeName'] as String?) ?? '',
      placeAddress: (d['placeAddress'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      hours: (d['hours'] as String?) ?? '',
      website: (d['website'] as String?) ?? '',
      gps: (d['gps'] as String?) ?? '',
      confirmed: d['confirmed'] == true,
      status: (d['status'] as String?) ?? 'draft',
      answers: Map<String, String>.from(d['answers'] as Map? ?? const {}),
      sectionNotes: Map<String, String>.from(
        d['sectionNotes'] as Map? ?? const {},
      ),
      photos: [
        for (final p in d['photos'] as List? ?? const [])
          if (p is Map) AuditPhoto.fromMap(Map<String, dynamic>.from(p)),
      ],
      measurements: Map<String, String>.from(
        d['measurements'] as Map? ?? const {},
      ),
      auditorNotes: (d['auditorNotes'] as String?) ?? '',
      score: (d['score'] as num?)?.toInt() ?? 0,
      sectionScores: {
        for (final e in (d['sectionScores'] as Map? ?? const {}).entries)
          e.key.toString(): (e.value as num?)?.toInt() ?? 0,
      },
      seeded: d['seeded'] == true,
      createdAt: _ts(d['createdAt']),
      updatedAt: _ts(d['updatedAt']),
      submittedAt: _ts(d['submittedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'auditorName': auditorName,
    'placeId': placeId,
    'placeName': placeName,
    'placeAddress': placeAddress,
    'category': category,
    'phone': phone,
    'hours': hours,
    'website': website,
    'gps': gps,
    'confirmed': confirmed,
    'status': status,
    'answers': answers,
    'sectionNotes': sectionNotes,
    'photos': photos.map((p) => p.toMap()).toList(),
    'measurements': measurements,
    'auditorNotes': auditorNotes,
    'score': score,
    'sectionScores': sectionScores,
    'seeded': seeded,
  };

  AccessibilityAudit copyWith({
    String? id,
    String? placeId,
    String? placeName,
    String? placeAddress,
    String? category,
    String? phone,
    String? hours,
    String? website,
    String? gps,
    bool? confirmed,
    String? status,
    Map<String, String>? answers,
    Map<String, String>? sectionNotes,
    List<AuditPhoto>? photos,
    Map<String, String>? measurements,
    String? auditorNotes,
    int? score,
    Map<String, int>? sectionScores,
  }) {
    return AccessibilityAudit(
      id: id ?? this.id,
      uid: uid,
      auditorName: auditorName,
      placeId: placeId ?? this.placeId,
      placeName: placeName ?? this.placeName,
      placeAddress: placeAddress ?? this.placeAddress,
      category: category ?? this.category,
      phone: phone ?? this.phone,
      hours: hours ?? this.hours,
      website: website ?? this.website,
      gps: gps ?? this.gps,
      confirmed: confirmed ?? this.confirmed,
      status: status ?? this.status,
      answers: answers ?? this.answers,
      sectionNotes: sectionNotes ?? this.sectionNotes,
      photos: photos ?? this.photos,
      measurements: measurements ?? this.measurements,
      auditorNotes: auditorNotes ?? this.auditorNotes,
      score: score ?? this.score,
      sectionScores: sectionScores ?? this.sectionScores,
      seeded: seeded,
      createdAt: createdAt,
      updatedAt: updatedAt,
      submittedAt: submittedAt,
    );
  }

  String answerFor(String sectionId, String itemId) =>
      answers['$sectionId.$itemId'] ?? '';

  int answeredCount() {
    var n = 0;
    for (final section in AuditCatalog.checklist) {
      for (final item in AuditCatalog.togglesOf(section)) {
        if (answerFor(section.id, item.id).isNotEmpty) n++;
      }
    }
    return n;
  }

  int get totalItems => AuditCatalog.checklist.fold(
    0,
    (s, e) => s + AuditCatalog.togglesOf(e).length,
  );

  /// yes=1, partial=0.5, no=0, na skipped. Non-toggle fields are ignored.
  static ({int score, Map<String, int> sections}) compute(
    Map<String, String> answers,
  ) {
    final sections = <String, int>{};
    var nume = 0.0;
    var deno = 0.0;
    for (final section in AuditCatalog.checklist) {
      var sN = 0.0;
      var sD = 0.0;
      for (final item in AuditCatalog.togglesOf(section)) {
        final v = answers['${section.id}.${item.id}'] ?? '';
        if (v.isEmpty || v == 'na') continue;
        sD += 1;
        deno += 1;
        final pts = switch (v) {
          'yes' => 1.0,
          'partial' => 0.5,
          _ => 0.0,
        };
        sN += pts;
        nume += pts;
      }
      sections[section.id] = sD == 0 ? 0 : ((sN / sD) * 100).round();
    }
    final score = deno == 0 ? 0 : ((nume / deno) * 100).round();
    return (score: score, sections: sections);
  }

  int sectionOutOf10(String sectionId) {
    final pct =
        sectionScores[sectionId] ?? compute(answers).sections[sectionId] ?? 0;
    return (pct / 10).round().clamp(0, 10);
  }

  String get scoreLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Very Good';
    if (score >= 60) return 'Good';
    if (score >= 40) return 'Fair';
    return 'Needs work';
  }

  double get starRating => (score / 20).clamp(0, 5);

  List<String> inferredFeatures() {
    bool yes(String section, String item) => answerFor(section, item) == 'yes';
    final out = <String>{};
    if (yes('parking', 'available') || yes('parking', 'marked')) {
      out.add('parking');
    }
    if (yes('parking', 'kerbRamp') || yes('entrance', 'stepFree')) {
      out.add('stepFree');
    }
    if (yes('entrance', 'ramp')) out.add('ramp');
    if (yes('entrance', 'elevator')) out.add('elevator');
    if (yes('toilet', 'available')) out.add('toilet');
    if (yes('visual', 'braille') || yes('visual', 'tactile')) {
      out.add('braille');
      out.add('visual');
    }
    if (yes('hearing', 'loop')) out.add('hearing');
    if (yes('hearing', 'signLanguage')) out.add('signLanguage');
    if (yes('cognitive', 'quiet') || yes('hearing', 'quietArea')) {
      out.add('quiet');
    }
    if (yes('cognitive', 'calmWaitingRoom')) {
      out.add('calmWaitingRoom');
    }
    if (yes('parking', 'dropOff')) out.add('dropOff');
    if (yes('parking', 'evParking')) out.add('evAccessibleParking');
    if (yes('parking', 'evCharging')) out.add('evCharging');
    final parkingFee = answerFor('parking', 'fee').trim().toLowerCase();
    if (parkingFee == 'free') out.add('freeParking');
    if (yes('hearing', 'captions')) out.add('captions');
    if (yes('staff', 'serviceAnimal') || yes('visual', 'guideDog')) {
      out.add('serviceAnimal');
    }
    if (yes('staff', 'familyFriendly')) out.add('familyFriendly');
    if (yes('staff', 'petFriendly')) out.add('petFriendly');
    if (yes('staff', 'receptionDesk')) {
      out.add('receptionDesk');
    }
    if (yes('mobility', 'corridors')) out.add('wideCorridors');
    if (yes('mobility', 'seating')) out.add('accessibleSeating');
    if (yes('mobility', 'counters')) out.add('lowCounters');
    if (yes('entrance', 'elevatorControls')) {
      out.add('brailleElevatorControls');
      out.add('braille');
      out.add('visual');
    }
    if (yes('visual', 'contrast')) {
      out.add('highContrastSignage');
      out.add('visual');
    }
    if (yes('visual', 'audible')) {
      out.add('audioAnnouncements');
      out.add('visual');
    }
    if (yes('visual', 'lighting')) {
      out.add('goodLighting');
      out.add('visual');
    }
    if (yes('hearing', 'emergencyAlerts')) {
      out.add('visualEmergencyAlarms');
      out.add('hearing');
    }
    if (yes('hearing', 'textChat')) {
      out.add('textChat');
      out.add('hearing');
    }
    return out.toList();
  }

  List<AccessibleServiceItem> inferredServices() {
    bool yes(String section, String item) => answerFor(section, item) == 'yes';
    final out = <AccessibleServiceItem>[];
    if (yes('staff', 'wheelchairAssist')) {
      out.add(
        const AccessibleServiceItem(
          id: 'staff.wheelchairAssist',
          label: 'Wheelchair escort',
          description: 'Staff can guide you through the building.',
          source: 'audit',
        ),
      );
    }
    if (yes('staff', 'personalAssist')) {
      out.add(
        const AccessibleServiceItem(
          id: 'staff.personalAssist',
          label: 'Personal assistance',
          description: 'One-to-one help on arrival when requested.',
          source: 'audit',
        ),
      );
    }
    if (yes('staff', 'priority')) {
      out.add(
        const AccessibleServiceItem(
          id: 'staff.priority',
          label: 'Priority access',
          description: 'Shorter wait or dedicated queue for disabled visitors.',
          source: 'audit',
        ),
      );
    }
    if (yes('staff', 'formats')) {
      out.add(
        const AccessibleServiceItem(
          id: 'staff.formats',
          label: 'Alternate formats',
          description: 'Large print, audio, or digital formats on request.',
          source: 'audit',
        ),
      );
    }
    return out;
  }

  List<String> inferredNeeds() {
    final needs = <String>{};
    if (answerFor('entrance', 'stepFree') == 'yes' ||
        answerFor('mobility', 'corridors') == 'yes') {
      needs.add('wheelchair');
    }
    if (answerFor('visual', 'braille') == 'yes' ||
        answerFor('visual', 'contrast') == 'yes' ||
        answerFor('visual', 'audible') == 'yes' ||
        answerFor('visual', 'lighting') == 'yes' ||
        answerFor('entrance', 'elevatorControls') == 'yes') {
      needs.add('visual');
    }
    if (answerFor('hearing', 'loop') == 'yes' ||
        answerFor('hearing', 'signLanguage') == 'yes' ||
        answerFor('hearing', 'emergencyAlerts') == 'yes' ||
        answerFor('hearing', 'textChat') == 'yes' ||
        answerFor('hearing', 'captions') == 'yes') {
      needs.add('hearing');
    }
    if (answerFor('cognitive', 'quiet') == 'yes' ||
        answerFor('cognitive', 'navigation') == 'yes') {
      needs.add('cognitive');
    }
    return needs.toList();
  }

  static DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;
}
