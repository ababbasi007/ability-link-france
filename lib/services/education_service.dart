import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/education_program.dart';
import '../models/user_profile.dart';

class EducationService {
  EducationService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _programs =>
      _db.collection('educationPrograms');
  CollectionReference<Map<String, dynamic>> get _institutions =>
      _db.collection('educationInstitutions');
  CollectionReference<Map<String, dynamic>> get _interests =>
      _db.collection('educationInterests');

  Stream<List<EducationProgram>> watchPrograms() {
    return _programs.snapshots().map(
      (snap) => snap.docs.map(EducationProgram.fromDoc).toList(),
    );
  }

  Stream<List<EducationInstitution>> watchInstitutions() {
    return _institutions.snapshots().map(
      (snap) => snap.docs.map(EducationInstitution.fromDoc).toList(),
    );
  }

  Future<EducationInstitution?> getInstitution(String id) async {
    final doc = await _institutions.doc(id).get();
    if (!doc.exists) return null;
    return EducationInstitution.fromDoc(doc);
  }

  Future<EducationProgram?> getProgram(String id) async {
    final doc = await _programs.doc(id).get();
    if (!doc.exists) return null;
    return EducationProgram.fromDoc(doc);
  }

  Stream<List<EducationInterest>> watchMyInterests() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _interests.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(EducationInterest.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<int> ensureSeeded() async {
    var n = 0;
    for (final inst in seedInstitutions) {
      final ref = _institutions.doc(inst.id);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          ...inst.toMap(),
          'seeded': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        n++;
      }
    }
    for (final p in seedEducation) {
      final ref = _programs.doc(p.id);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          ...p.toMap(),
          'seeded': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        n++;
      }
    }
    return n;
  }

  int matchScore(EducationProgram program, UserProfile? profile) {
    var score = 28;
    if (program.verified) score += 8;
    if (program.online ||
        program.mode == 'online' ||
        program.mode == 'hybrid') {
      score += 8;
    }
    if (program.signLanguageSupport) score += 4;
    if (program.specialEducation) score += 4;

    final profiles =
        profile?.accessibilityProfiles.map((e) => e.toLowerCase()).toList() ??
        const <String>[];
    for (final tag in program.inclusiveFor) {
      final t = tag.toLowerCase();
      if (profiles.any((p) => p.contains(t) || t.contains(p))) score += 12;
    }

    final aid = (profile?.mobilityAid ?? '').toLowerCase();
    for (final f in program.accessFeatures) {
      final x = f.toLowerCase();
      if (aid.contains('wheelchair') &&
          (x.contains('wheelchair') ||
              x.contains('step-free') ||
              x.contains('elevator'))) {
        score += 8;
      }
      if (x.contains('caption') ||
          x.contains('screen reader') ||
          x.contains('quiet') ||
          x.contains('asl')) {
        score += 4;
      }
    }
    return score.clamp(0, 99);
  }

  List<EducationProgram> filter(
    List<EducationProgram> all, {
    String query = '',
    String kind = 'All',
    bool verifiedOnly = false,
    bool onlineOnly = false,
    bool specialEdOnly = false,
    bool signLanguageOnly = false,
    UserProfile? profile,
  }) {
    var list = all.where((p) {
      if (!p.matchesQuery(query)) return false;
      if (kind != 'All' && p.kind != kind) return false;
      if (verifiedOnly && !p.verified) return false;
      if (onlineOnly && !(p.online || p.mode == 'online')) return false;
      if (specialEdOnly && !p.specialEducation && p.kind != 'special_ed') {
        return false;
      }
      if (signLanguageOnly &&
          !p.signLanguageSupport &&
          p.kind != 'sign_language') {
        return false;
      }
      return true;
    }).toList();
    list.sort(
      (a, b) => matchScore(b, profile).compareTo(matchScore(a, profile)),
    );
    return list;
  }

  List<EducationProgram> programsForInstitution(
    List<EducationProgram> all,
    String institutionId,
  ) {
    return all.where((p) => p.institutionId == institutionId).toList();
  }

  Future<String> expressInterest({
    required EducationProgram program,
    required String note,
    required String status,
    int matchScoreValue = 0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to continue');
    final id = '${program.id}_${user.uid}';
    await _interests.doc(id).set({
      'uid': user.uid,
      'userName': user.displayName ?? '',
      'userEmail': user.email ?? '',
      'programId': program.id,
      'programName': program.name,
      'kind': program.kind,
      'institution': program.institution,
      'status': status,
      'note': note,
      'matchScore': matchScoreValue,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return id;
  }

  Future<void> withdraw(String id) async {
    await _interests.doc(id).update({
      'status': 'withdrawn',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final seedInstitutions = <EducationInstitution>[
  EducationInstitution(
    id: 'inst-metro',
    name: 'Metro Inclusive College',
    kind: 'university',
    city: 'New York, NY',
    verified: true,
    summary:
        'Accessible undergraduate campus with a full disability services office.',
    description:
        'Public-facing disability-friendly college with step-free routes, accessible housing, captioned lectures, and an on-site DRC.',
    accessFeatures: [
      'Step-free campus',
      'Elevators',
      'Accessible housing',
      'Captions in lectures',
    ],
    disabilityServices: [
      'Disability Resource Center (ground floor)',
      'Note-taking coordination',
      'Exam accommodations',
      'Housing accessibility requests',
    ],
    classrooms: [
      'Lecture Hall A — step-free, induction loop',
      'Seminar 12 — height-adjustable desks',
      'Quiet exam suite B',
    ],
    websiteLabel: 'metro-inclusive.example/access',
    photoUrl:
        'https://images.unsplash.com/photo-1541339907198-e08756dedf3f?w=800&h=400&fit=crop',
  ),
  EducationInstitution(
    id: 'inst-riverside',
    name: 'Riverside STEM Academy',
    kind: 'school',
    city: 'Brooklyn, NY',
    verified: true,
    summary: 'High school / dual enrollment STEM with hybrid accessible labs.',
    description:
        'STEM academy for secondary learners with height-adjustable lab benches and sensory-friendly study rooms.',
    accessFeatures: ['Wheelchair labs', 'Flexible schedule', 'Sensory rooms'],
    disabilityServices: [
      'IEP liaison',
      'Hybrid lecture days',
      'Counselor access',
    ],
    classrooms: [
      'Lab 1 — wheelchair benches',
      'Sensory study room 3',
      'Hybrid lecture theater',
    ],
    websiteLabel: 'riverside-stem.example',
  ),
  EducationInstitution(
    id: 'inst-brightleaf',
    name: 'Bright Leaf Education',
    kind: 'institute',
    city: 'Remote / NYC',
    verified: true,
    summary: 'Training institute for accessible online certificates.',
    description:
        'Adult training institute focused on plain-language digital skills and screen-reader-ready courses.',
    accessFeatures: ['Screen reader', 'Captions', 'Plain language'],
    disabilityServices: [
      'Mentor office hours',
      'Caption QC',
      'AT lending desk',
    ],
    classrooms: ['Virtual classroom (captioned)', 'Office-hours pods'],
    websiteLabel: 'brightleaf.example',
  ),
  EducationInstitution(
    id: 'inst-openpath',
    name: 'OpenPath Foundation',
    kind: 'academy',
    city: 'United States',
    verified: true,
    summary: 'Scholarship and AT stipend partner for accredited programs.',
    description:
        'Foundation awarding access grants and assistive-technology stipends nationwide.',
    accessFeatures: ['Plain-language application', 'AT stipend'],
    disabilityServices: ['Application help desk', 'Device stipend admin'],
    websiteLabel: 'openpath.example/grants',
  ),
  EducationInstitution(
    id: 'inst-city-access',
    name: 'City Access Health Academy',
    kind: 'institute',
    city: 'Queens, NY',
    verified: true,
    summary: 'Health academy with ASL and Deaf-led instruction.',
    description:
        'Community training institute for patients, caregivers, and interpreters.',
    accessFeatures: ['Deaf instructors', 'Captions', 'Flexible hours'],
    disabilityServices: ['ASL campus liaison', 'Interpreter booking'],
    classrooms: ['ASL lab', 'Hybrid seminar room with captions'],
    websiteLabel: 'cityaccess-health.example',
  ),
];

final seedEducation = <EducationProgram>[
  EducationProgram(
    id: 'edu-metro-inclusive-college',
    name: 'Metro Inclusive College — Undergraduate',
    kind: 'university',
    institution: 'Metro Inclusive College',
    institutionId: 'inst-metro',
    city: 'New York, NY',
    level: 'Undergraduate',
    mode: 'on-campus',
    verified: true,
    inclusiveFor: ['Mobility', 'Visual', 'Hearing', 'Cognitive'],
    accessFeatures: [
      'Step-free campus',
      'Elevators',
      'Accessible housing',
      'Captions in lectures',
      'Quiet exam rooms',
    ],
    summary:
        'University programs with verified step-free routes and disability services.',
    description:
        'Undergraduate degrees with a dedicated access team, note-taking, and housing that includes roll-in showers.',
    classrooms: [
      'Lecture Hall A — step-free, induction loop',
      'Seminar 12 — height-adjustable desks',
      'Quiet exam suite B',
    ],
    learningMaterials: [
      'Captioned lecture capture',
      'Screen-reader syllabi',
      'Large-print handouts on request',
    ],
    assistiveTech: ['Campus AT lending', 'Speech-to-text in lectures'],
    applicationSteps: [
      'Complete common application',
      'Upload Accessibility Passport summary (optional)',
      'Request housing accessibility form',
      'Schedule DRC intake after admit',
    ],
    applicationNotes:
        'Rolling admissions · access forms due 30 days before term.',
  ),
  EducationProgram(
    id: 'edu-riverside-stem',
    name: 'Riverside STEM Academy',
    kind: 'school',
    institution: 'Riverside STEM Academy',
    institutionId: 'inst-riverside',
    city: 'Brooklyn, NY',
    level: 'High school / dual enrollment',
    mode: 'hybrid',
    verified: true,
    inclusiveFor: ['Mobility', 'Cognitive'],
    accessFeatures: [
      'Wheelchair labs',
      'Flexible schedule',
      'Sensory-friendly rooms',
    ],
    summary: 'Accessible high school STEM with hybrid labs.',
    description:
        'Dual-enrollment STEM tracks. Lab benches are height-adjustable. Hybrid option for lecture days.',
    classrooms: ['Lab 1 — wheelchair benches', 'Sensory study room 3'],
    learningMaterials: [
      'Plain-language lab cards',
      'Video demos with captions',
    ],
    applicationSteps: [
      'Family information session',
      'Submit IEP / 504 summary (optional)',
      'Campus access tour',
    ],
    applicationNotes: 'Applications open each January for fall entry.',
  ),
  EducationProgram(
    id: 'edu-brightleaf-institute',
    name: 'Bright Leaf Digital Skills Institute',
    kind: 'institute',
    institution: 'Bright Leaf Education',
    institutionId: 'inst-brightleaf',
    city: 'Remote / NYC',
    level: 'Adult training',
    mode: 'online',
    online: true,
    verified: true,
    inclusiveFor: ['Cognitive', 'Visual', 'Hearing'],
    accessFeatures: ['Screen reader', 'Captions', 'Plain language'],
    summary: 'Training institute for accessible digital certificates.',
    description:
        'Adult learners earn stackable certificates with mentor support and AT-ready platforms.',
    classrooms: ['Virtual classroom (captioned)'],
    learningMaterials: ['Plain-language modules', 'Glossary packs'],
    assistiveTech: ['Screen reader QA', 'Keyboard-only navigation'],
    applicationSteps: [
      'Create Bright Leaf account',
      'AT needs questionnaire',
      'Choose certificate track',
    ],
  ),
  EducationProgram(
    id: 'edu-plain-language-it',
    name: 'Plain-language IT fundamentals',
    kind: 'course',
    institution: 'Bright Leaf Education',
    institutionId: 'inst-brightleaf',
    city: 'Remote',
    level: 'Certificate',
    mode: 'online',
    online: true,
    verified: true,
    inclusiveFor: ['Cognitive', 'Visual', 'Hearing'],
    accessFeatures: [
      'Screen reader',
      'Captions',
      'Plain language',
      'Self-paced',
    ],
    summary:
        'Self-paced online course designed for screen readers and plain language.',
    description:
        '8-week online course. All videos captioned. Materials in plain language with glossary.',
    learningMaterials: [
      'Captioned video lessons',
      'Plain-language PDF workbook',
      'Screen-reader HTML modules',
    ],
    assistiveTech: [
      'Compatible with NVDA / VoiceOver',
      'Keyboard shortcuts map',
    ],
    applicationSteps: [
      'Enroll online',
      'Select AT preferences',
      'Join orientation webinar',
    ],
    applicationNotes: 'Starts every month · self-paced within 12 weeks.',
  ),
  EducationProgram(
    id: 'edu-asl-healthcare',
    name: 'ASL for healthcare visits',
    kind: 'sign_language',
    institution: 'City Access Health Academy',
    institutionId: 'inst-city-access',
    city: 'Queens, NY',
    level: 'Short course',
    mode: 'hybrid',
    verified: true,
    signLanguageSupport: true,
    inclusiveFor: ['Hearing'],
    accessFeatures: [
      'Deaf instructors',
      'Captions',
      'Flexible hours',
      'ASL primary',
    ],
    summary:
        'Sign-language education support for clinic visits and caregiver families.',
    description:
        'Four Saturday sessions plus online practice. Interpreters provided. Deaf-led instruction.',
    classrooms: ['ASL lab', 'Hybrid seminar with captions'],
    learningMaterials: ['ASL video drills', 'Clinic phrase cards'],
    applicationSteps: [
      'Register for cohort',
      'Indicate Deaf / hearing learner track',
      'Request interpreter if needed for mixed sessions',
    ],
  ),
  EducationProgram(
    id: 'edu-iep-pathways',
    name: 'Inclusive Pathways — Special Education',
    kind: 'special_ed',
    institution: 'Riverside STEM Academy',
    institutionId: 'inst-riverside',
    city: 'Brooklyn, NY',
    level: 'K–12 support',
    mode: 'hybrid',
    verified: true,
    specialEducation: true,
    inclusiveFor: ['Cognitive', 'Mobility', 'Hearing'],
    accessFeatures: [
      'IEP coordination',
      'Sensory-friendly rooms',
      '1:1 aide option',
      'Flexible testing',
    ],
    summary:
        'Special education pathway with IEP liaison and accessible classrooms.',
    description:
        'Structured special education supports alongside dual-enrollment STEM. Families work with an IEP liaison and access sensory rooms.',
    classrooms: [
      'Resource room R2',
      'Sensory study room 3',
      'Quiet testing suite',
    ],
    learningMaterials: [
      'IEP-aligned packets',
      'Visual schedules',
      'Plain-language progress reports',
    ],
    assistiveTech: ['Speech-generating device support', 'Reading pens'],
    applicationSteps: [
      'Intake with special education coordinator',
      'Share current IEP / evaluation',
      'Classroom observation visit',
      'Placement team meeting',
    ],
    applicationNotes:
        'Referrals accepted year-round; placement reviews monthly.',
  ),
  EducationProgram(
    id: 'edu-at-lending',
    name: 'Campus Assistive Technology Lending',
    kind: 'assistive_tech',
    institution: 'Metro Inclusive College',
    institutionId: 'inst-metro',
    city: 'New York, NY',
    level: 'All enrolled students',
    mode: 'on-campus',
    verified: true,
    inclusiveFor: ['Visual', 'Hearing', 'Mobility', 'Cognitive'],
    accessFeatures: ['Device lending', 'Training sessions', 'Repair desk'],
    summary:
        'Borrow screen readers, captioning kits, and mobility classroom tools.',
    description:
        'AT library for enrolled learners: short- and semester-term loans with setup help.',
    assistiveTech: [
      'NVDA / JAWS training laptops',
      'Live captioning kits',
      'Height-adjustable desk carts',
      'Smart pens',
    ],
    learningMaterials: ['AT quick-start guides (plain language + video)'],
    applicationSteps: [
      'Show student ID',
      'Complete AT needs form',
      'Book training slot',
      'Check out device',
    ],
  ),
  EducationProgram(
    id: 'edu-materials-pack',
    name: 'Accessible Learning Materials Pack',
    kind: 'materials',
    institution: 'Bright Leaf Education',
    institutionId: 'inst-brightleaf',
    city: 'Remote',
    level: 'Any learner',
    mode: 'online',
    online: true,
    verified: true,
    inclusiveFor: ['Visual', 'Cognitive', 'Hearing'],
    accessFeatures: [
      'Screen reader HTML',
      'Captions',
      'Plain language',
      'High contrast',
    ],
    summary:
        'Downloadable accessible materials library for courses and tutors.',
    description:
        'Reusable packs: captioned explainers, plain-language worksheets, and high-contrast slides.',
    learningMaterials: [
      'Captioned explainer videos',
      'Plain-language worksheets',
      'High-contrast slide kits',
      'Glossary cards',
    ],
    applicationSteps: [
      'Create free materials account',
      'Choose pack',
      'Download or stream',
    ],
  ),
  EducationProgram(
    id: 'edu-access-scholars',
    name: 'Access Scholars Grant',
    kind: 'scholarship',
    institution: 'OpenPath Foundation',
    institutionId: 'inst-openpath',
    city: 'United States',
    level: 'Any accredited program',
    mode: 'online',
    online: true,
    verified: true,
    deadlineLabel: 'Rolling',
    awardLabel: 'Up to \$8,000',
    inclusiveFor: ['Mobility', 'Visual', 'Hearing', 'Cognitive'],
    accessFeatures: [
      'Assistive tech stipend',
      'Plain-language application',
      'Caregiver letter optional',
    ],
    summary: 'Need-based grant plus an assistive-technology stipend.',
    description:
        'Open to students with a disability attending an accredited program. Plain-language application.',
    assistiveTech: ['Stipend for devices and software'],
    applicationSteps: [
      'Confirm accredited enrollment',
      'Complete plain-language form',
      'Optional caregiver / advisor letter',
      'Upload expense estimate for AT',
    ],
    applicationNotes: 'Rolling decisions within 4–6 weeks.',
  ),
  EducationProgram(
    id: 'edu-campus-housing-fund',
    name: 'Accessible Housing Award',
    kind: 'scholarship',
    institution: 'Metro Inclusive College',
    institutionId: 'inst-metro',
    city: 'New York, NY',
    level: 'Undergraduate',
    mode: 'on-campus',
    verified: true,
    deadlineLabel: 'May 15',
    awardLabel: 'Campus housing covered',
    inclusiveFor: ['Mobility'],
    accessFeatures: ['Wheelchair housing', 'Step-free campus'],
    summary: 'Covers accessible residence-hall housing for mobility-aid users.',
    description:
        'Awarded to incoming students who need roll-in showers or adjacent caregiver rooms.',
    applicationSteps: [
      'Admit to Metro Inclusive College',
      'Submit housing accessibility form',
      'DRC verification meeting',
    ],
    applicationNotes: 'Deadline May 15 for fall housing.',
  ),
  EducationProgram(
    id: 'edu-sl-classroom-aide',
    name: 'Sign-language classroom support',
    kind: 'sign_language',
    institution: 'City Access Health Academy',
    institutionId: 'inst-city-access',
    city: 'Queens, NY',
    level: 'K–12 & adult',
    mode: 'hybrid',
    verified: true,
    signLanguageSupport: true,
    inclusiveFor: ['Hearing'],
    accessFeatures: ['Classroom ASL interpreter', 'VRI backup', 'Deaf mentor'],
    summary:
        'Ongoing sign-language education support for classrooms and tutoring.',
    description:
        'Book interpreters and Deaf mentors for classes, exams, and parent meetings.',
    classrooms: ['Any partner school classroom with VRI kit'],
    applicationSteps: [
      'Request support window',
      'Share class schedule',
      'Confirm interpreter / mentor',
    ],
  ),
];
