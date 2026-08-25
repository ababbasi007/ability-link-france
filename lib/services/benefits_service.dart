import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/benefit_scheme.dart';
import '../models/user_profile.dart';
import 'notification_service.dart';
import 'seed_write_guard.dart';

class BenefitsService {
  BenefitsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    NotificationService? notifications,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _notifications = notifications ?? NotificationService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final NotificationService _notifications;

  CollectionReference<Map<String, dynamic>> get _schemes =>
      _db.collection('benefitSchemes');
  CollectionReference<Map<String, dynamic>> get _offices =>
      _db.collection('governmentOffices');
  CollectionReference<Map<String, dynamic>> get _apps =>
      _db.collection('benefitApplications');

  Stream<List<BenefitScheme>> watchSchemes() {
    return _schemes.snapshots().map(
      (snap) => snap.docs.map(BenefitScheme.fromDoc).toList(),
    );
  }

  Stream<List<GovernmentOffice>> watchOffices() {
    return _offices.snapshots().map(
      (snap) => snap.docs.map(GovernmentOffice.fromDoc).toList(),
    );
  }

  Future<int> ensureSeeded() {
    return SeedWriteGuard.runOnce('benefits', _auth, () async {
      const catalog = 'benefits';
      var n = 0;
      for (final s in seedBenefits) {
        if (!await SeedWriteGuard.canWrite(catalog)) return n;
        final ref = _schemes.doc(s.id);
        final snap = await ref.get();
        if (!snap.exists) {
          try {
            await ref.set({...s.toMap(), 'seeded': true});
            n++;
          } on FirebaseException catch (e) {
            if (SeedWriteGuard.isPermissionDenied(e)) {
              await SeedWriteGuard.block(catalog);
              return n;
            }
            rethrow;
          }
        }
      }
      for (final o in seedGovernmentOffices) {
        if (!await SeedWriteGuard.canWrite(catalog)) return n;
        final ref = _offices.doc(o.id);
        final snap = await ref.get();
        if (!snap.exists) {
          try {
            await ref.set({...o.toMap(), 'seeded': true});
            n++;
          } on FirebaseException catch (e) {
            if (SeedWriteGuard.isPermissionDenied(e)) {
              await SeedWriteGuard.block(catalog);
              return n;
            }
            rethrow;
          }
        }
      }
      return n;
    });
  }

  int matchScore(BenefitScheme scheme, UserProfile? profile) {
    var score = 24;
    final profiles = profile?.accessibilityProfiles ?? const <String>[];
    if (scheme.matchesProfile(profiles)) score += 28;
    if (scheme.category == 'disability' || scheme.category == 'certificate') {
      score += 8;
    }
    if (scheme.deadlineLabel.isNotEmpty) score += 4;
    if (scheme.phone.isNotEmpty || scheme.email.isNotEmpty) score += 4;
    return score.clamp(0, 99);
  }

  List<BenefitScheme> filter(
    List<BenefitScheme> all, {
    String query = '',
    String category = 'all',
    UserProfile? profile,
  }) {
    var list = all.where((s) {
      if (!s.matchesQuery(query)) return false;
      if (category != 'all' && category.isNotEmpty && s.category != category) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) {
      final cmp = matchScore(b, profile).compareTo(matchScore(a, profile));
      if (cmp != 0) return cmp;
      return a.name.compareTo(b.name);
    });
    return list;
  }

  Future<List<BenefitScheme>> listSchemes({
    String query = '',
    String category = 'all',
    UserProfile? profile,
  }) async {
    await ensureSeeded();
    final snap = await _schemes.limit(120).get();
    final all = snap.docs.map(BenefitScheme.fromDoc).toList();
    return filter(all, query: query, category: category, profile: profile);
  }

  Future<BenefitScheme?> getScheme(String id) async {
    await ensureSeeded();
    final doc = await _schemes.doc(id).get();
    if (!doc.exists) return null;
    return BenefitScheme.fromDoc(doc);
  }

  List<EligibilityResult> checkEligibility(
    List<BenefitScheme> schemes, {
    required bool hasDisabilityRecognition,
    required bool lowIncome,
    required bool seekingWork,
    required bool student,
    required bool needsHousing,
    required bool needsTransport,
    required bool needsHealthcare,
    required bool needsTaxHelp,
    UserProfile? profile,
  }) {
    final passport = profile?.accessibilityProfiles ?? const <String>[];
    final results = <EligibilityResult>[];

    for (final s in schemes) {
      var score = 0;
      final reasons = <String>[];

      if (s.matchesProfile(passport)) {
        score += 25;
        reasons.add('Matches your accessibility passport tags');
      }
      if (hasDisabilityRecognition &&
          (s.category == 'disability' ||
              s.category == 'certificate' ||
              s.tags.any((t) => t.contains('disability')))) {
        score += 20;
        reasons.add('Disability recognition / MDPH pathway');
      }
      if (lowIncome &&
          (s.category == 'financial' ||
              s.tags.any((t) => t.contains('income') || t.contains('aah')))) {
        score += 20;
        reasons.add('Income-related support');
      }
      if (seekingWork && s.category == 'employment') {
        score += 18;
        reasons.add('Employment / RQTH support');
      }
      if (student && s.category == 'education') {
        score += 18;
        reasons.add('Education support');
      }
      if (needsHousing && s.category == 'housing') {
        score += 18;
        reasons.add('Housing adaptation / rent aid');
      }
      if (needsTransport && s.category == 'transport') {
        score += 15;
        reasons.add('Transport accessibility');
      }
      if (needsHealthcare && s.category == 'healthcare') {
        score += 18;
        reasons.add('Healthcare coverage');
      }
      if (needsTaxHelp && s.category == 'tax') {
        score += 15;
        reasons.add('Tax relief');
      }
      if (s.eligibilityHints.isNotEmpty) {
        score += 5;
        reasons.add('Official eligibility notes available');
      }

      if (score > 0) {
        results.add(
          EligibilityResult(
            scheme: s,
            score: score.clamp(0, 100),
            likelyEligible: score >= 35,
            reasons: reasons,
          ),
        );
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }

  List<GovernmentOffice> filterOffices(
    List<GovernmentOffice> all, {
    String query = '',
  }) {
    var list = all.where((o) => o.matchesQuery(query)).toList();
    list.sort((a, b) => a.city.compareTo(b.city));
    return list;
  }

  Future<String> startApplication({
    required BenefitScheme scheme,
    String note = '',
    bool setReminder = true,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to track applications');

    DateTime? remindAt;
    if (setReminder && scheme.reminderDays > 0) {
      remindAt = DateTime.now().add(Duration(days: scheme.reminderDays));
    } else if (setReminder) {
      remindAt = DateTime.now().add(const Duration(days: 30));
    }

    final ref = await _apps.add({
      'uid': uid,
      'schemeId': scheme.id,
      'schemeName': scheme.name,
      'category': scheme.category,
      'status': 'draft',
      'note': note.trim(),
      'deadlineLabel': scheme.deadlineLabel,
      'agency': scheme.agency,
      'remindAt': remindAt == null ? null : Timestamp.fromDate(remindAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (remindAt != null) {
      await _notifications.notify(
        uid: uid,
        type: 'benefit_reminder',
        title: 'Benefit deadline reminder',
        body:
            '${scheme.name}: follow up by ${_fmt(remindAt)}${scheme.deadlineLabel.isEmpty ? '' : ' (${scheme.deadlineLabel})'}',
        relatedId: ref.id,
      );
    }

    return ref.id;
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
    String? note,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in required');
    final doc = await _apps.doc(applicationId).get();
    if (!doc.exists || doc.data()?['uid'] != uid) {
      throw StateError('Application not found');
    }
    await _apps.doc(applicationId).update({
      'status': status,
      if (note != null) 'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    final name =
        (doc.data()?['schemeName'] as String?) ?? 'Benefit application';
    await _notifications.notify(
      uid: uid,
      type: 'benefit_reminder',
      title: 'Benefit update: $status',
      body: (note != null && note.trim().isNotEmpty)
          ? '$name · ${note.trim()}'
          : name,
      relatedId: applicationId,
    );
  }

  Stream<List<BenefitApplication>> watchMyApplications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _apps.where('uid', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(BenefitApplication.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Seed catalog (also used as offline fallback for AI assistant).
final seedBenefits = <BenefitScheme>[
  BenefitScheme(
    id: 'fr-aah',
    name: 'AAH — Allocation aux adultes handicapés',
    country: 'France',
    category: 'financial',
    summary:
        'Income support for adults with a disability rate of 80%+ (or 50–79% with restricted work capacity).',
    whoFor: 'Adults with recognized disability living in France',
    agency: 'CAF / MSA + MDPH',
    url: 'https://www.service-public.fr/particuliers/vosdroits/F12242',
    phone: '3230',
    email: 'contact@caf.fr',
    officeHint: 'CAF or MSA office; MDPH for disability rate',
    deadlineLabel: 'Renew before expiration (usually every 1–5 years)',
    reminderDays: 60,
    eligibilityHints: const [
      'Disability rate ≥ 80% or 50–79% with substantial and lasting work restriction',
      'Age 20+ (or 16+ if no longer dependent for family benefits)',
      'Residence in France',
      'Income below CAF ceiling',
    ],
    steps: const [
      'Obtain MDPH disability recognition / rate',
      'Apply via CAF or MSA with MDPH decision',
      'Declare income and household composition',
      'Track payment on CAF online account',
    ],
    documents: const [
      'MDPH decision (taux d’incapacité)',
      'ID / residence proof',
      'Income statements',
      'Bank details (RIB)',
    ],
    tags: const ['disability', 'income', 'aah', 'france'],
  ),
  BenefitScheme(
    id: 'fr-pch',
    name: 'PCH — Prestation de compensation du handicap',
    country: 'France',
    category: 'disability',
    summary:
        'Compensation for human help, technical aids, home adaptation, transport, and specific costs.',
    whoFor: 'People with lasting disability meeting MDPH criteria',
    agency: 'MDPH / Département',
    url: 'https://www.service-public.fr/particuliers/vosdroits/F14202',
    phone: '3977',
    email: 'contact@mdph.fr',
    officeHint: 'Your département MDPH office',
    deadlineLabel: 'MDPH renewal windows vary by decision',
    reminderDays: 90,
    eligibilityHints: const [
      'Difficulty with essential activities of daily living',
      'Permanent or lasting disability expected ≥ 1 year',
      'Age and residence criteria apply',
    ],
    steps: const [
      'Complete MDPH form (Cerfa) with medical certificate',
      'Describe needs: human help, aids, housing, transport',
      'MDPH evaluates and proposes a plan',
      'Département pays approved elements',
    ],
    documents: const [
      'Cerfa MDPH application',
      'Medical certificate (< 1 year)',
      'Quotes for aids / works',
      'Identity and address proof',
    ],
    tags: const ['disability', 'aids', 'pch', 'adaptation'],
  ),
  BenefitScheme(
    id: 'fr-rqth',
    name: 'RQTH — Recognition of disabled worker status',
    country: 'France',
    category: 'employment',
    summary:
        'Official status for workplace accommodations, Agefiph/Fiphfp support, and protected employment pathways.',
    whoFor: 'People seeking or in employment with a disability',
    agency: 'MDPH',
    url: 'https://www.service-public.fr/particuliers/vosdroits/F1650',
    phone: '3977',
    officeHint: 'MDPH + Cap emploi / France Travail',
    deadlineLabel: 'Renew before RQTH expiry (often 1–10 years)',
    reminderDays: 90,
    eligibilityHints: const [
      'Disability impacting work capacity',
      'MDPH recognition required',
    ],
    steps: const [
      'Apply for RQTH via MDPH',
      'Inform employer / Cap emploi if desired',
      'Request workplace adjustments',
      'Access Agefiph or Fiphfp funding if eligible',
    ],
    documents: const [
      'MDPH Cerfa',
      'Medical certificate',
      'CV / employment situation note',
    ],
    tags: const ['employment', 'rqth', 'workplace'],
  ),
  BenefitScheme(
    id: 'fr-agefiph',
    name: 'Agefiph employment aids',
    country: 'France',
    category: 'employment',
    summary:
        'Funding for workplace adaptations, training, job retention, and entrepreneurship for disabled workers in the private sector.',
    whoFor: 'RQTH holders and employers in the private sector',
    agency: 'Agefiph',
    url: 'https://www.agefiph.fr/',
    phone: '0800 11 10 09',
    email: 'contact@agefiph.fr',
    officeHint: 'Regional Agefiph delegation',
    deadlineLabel: 'Apply before purchase / training start',
    reminderDays: 21,
    eligibilityHints: const [
      'RQTH or equivalent recognition',
      'Private-sector employment or job seeker pathway',
    ],
    steps: const [
      'Confirm RQTH',
      'Build project with Cap emploi / counselor',
      'Submit Agefiph request with quotes',
      'Implement after approval',
    ],
    documents: const [
      'RQTH decision',
      'Quotes / training plan',
      'Employer attestation if applicable',
    ],
    tags: const ['employment', 'agefiph', 'adaptation'],
  ),
  BenefitScheme(
    id: 'fr-ald',
    name: 'ALD — Affection de longue durée (100% care)',
    country: 'France',
    category: 'healthcare',
    summary:
        'Long-term illness pathway with full coverage of related care by Assurance Maladie.',
    whoFor:
        'People with listed long-term conditions (including some disability-related)',
    agency: 'Assurance Maladie (CPAM)',
    url:
        'https://www.ameli.fr/assure/droits-demarches/maladie-accident-hospitalisation/affection-longue-duree-ald',
    phone: '3646',
    officeHint: 'Your CPAM office or ameli.fr account',
    deadlineLabel: 'Protocol renewal with treating physician',
    reminderDays: 60,
    eligibilityHints: const [
      'Condition on ALD list or exceptional ALD',
      'Protocol established by physician and CPAM',
    ],
    steps: const [
      'Physician opens ALD request',
      'CPAM validates protocol',
      'Present carte Vitale + protocol for related care',
      'Renew before end date',
    ],
    documents: const [
      'Medical protocol',
      'Carte Vitale',
      'Specialist reports as needed',
    ],
    tags: const ['healthcare', 'ald', 'insurance'],
  ),
  BenefitScheme(
    id: 'fr-c2s',
    name: 'Complémentaire santé solidaire (C2S)',
    country: 'France',
    category: 'healthcare',
    summary:
        'Free or low-cost complementary health coverage based on income — useful alongside disability-related care costs.',
    whoFor: 'Low-income residents covered by Assurance Maladie',
    agency: 'CPAM / MSA',
    url:
        'https://www.ameli.fr/assure/droits-demarches/difficultes-acces-droits-soins/complementaire-sante-solidaire',
    phone: '3646',
    officeHint: 'CPAM or apply on ameli.fr',
    deadlineLabel: 'Renew yearly',
    reminderDays: 45,
    eligibilityHints: const [
      'Income under C2S ceilings',
      'Affiliated to Assurance Maladie',
    ],
    steps: const [
      'Check eligibility simulator on ameli.fr',
      'Apply online or at CPAM',
      'Receive attestation',
      'Present with carte Vitale',
    ],
    documents: const [
      'Income proof',
      'Family composition',
      'Assurance Maladie number',
    ],
    tags: const ['healthcare', 'income', 'c2s'],
  ),
  BenefitScheme(
    id: 'fr-aes',
    name: 'AESH / school disability support',
    country: 'France',
    category: 'education',
    summary:
        'Human support (AESH), teaching adaptations, and MDPH educational plan (PPS) for pupils with disabilities.',
    whoFor:
        'Children and students with disability in school / higher ed pathways',
    agency: 'MDPH + Éducation nationale',
    url: 'https://www.service-public.fr/particuliers/vosdroits/F1653',
    phone: '3977',
    officeHint: 'MDPH + school / university disability service',
    deadlineLabel: 'Request before school year / exam sessions',
    reminderDays: 90,
    eligibilityHints: const [
      'MDPH recognition of educational needs',
      'Enrolled in school or higher education',
    ],
    steps: const [
      'MDPH application for PPS / AESH',
      'ESS meeting with school',
      'Implement adaptations and support hours',
      'Review annually',
    ],
    documents: const [
      'MDPH form',
      'Medical / psycho-educational reports',
      'School attestation',
    ],
    tags: const ['education', 'aesh', 'pps', 'school'],
  ),
  BenefitScheme(
    id: 'fr-bourse-handicap',
    name: 'Higher education disability grants & CROUS support',
    country: 'France',
    category: 'education',
    summary:
        'CROUS grants, disability service accommodations, and exam arrangements for students with disabilities.',
    whoFor: 'Students in higher education with disability',
    agency: 'CROUS + university disability office',
    url: 'https://www.etudiant.gouv.fr/',
    phone: '0 806 000 278',
    officeHint: 'CROUS + campus disability service',
    deadlineLabel: 'Dossier social étudiant (usually May–May window)',
    reminderDays: 30,
    eligibilityHints: const [
      'Enrolled in higher education',
      'Disability documentation for accommodations',
    ],
    steps: const [
      'File Dossier Social Étudiant for grants',
      'Register with campus disability service',
      'Request exam / course adaptations',
      'Coordinate with MDPH if needed',
    ],
    documents: const [
      'Student card / enrollment',
      'Medical certificate',
      'Income tax notice for grants',
    ],
    tags: const ['education', 'student', 'crous'],
  ),
  BenefitScheme(
    id: 'eu-parking',
    name: 'EU disability parking card',
    country: 'EU / France',
    category: 'transport',
    summary:
        'Blue badge / EU parking card for reserved spaces and parking concessions.',
    whoFor: 'People with significant mobility impairment',
    agency: 'MDPH (France) / local authority',
    url: 'https://www.service-public.fr/particuliers/vosdroits/F289',
    phone: '3977',
    officeHint: 'MDPH application; card issued by prefecture/MDPH process',
    deadlineLabel: 'Renew before card expiry',
    reminderDays: 60,
    eligibilityHints: const [
      'Significant walking difficulty or equivalent criteria',
      'MDPH evaluation',
    ],
    steps: const [
      'Apply via MDPH',
      'Receive European parking card',
      'Display when using reserved spaces',
      'Renew before expiry',
    ],
    documents: const ['MDPH Cerfa', 'Medical certificate', 'Photo / identity'],
    tags: const ['transport', 'parking', 'mobility'],
  ),
  BenefitScheme(
    id: 'fr-carte-mobilite',
    name: 'Carte mobilité inclusion (CMI)',
    country: 'France',
    category: 'transport',
    summary:
        'CMI parking, priority, and disability mention for transport and public access advantages.',
    whoFor: 'People with disability meeting MDPH CMI criteria',
    agency: 'MDPH',
    url: 'https://www.service-public.fr/particuliers/vosdroits/F34049',
    phone: '3977',
    officeHint: 'MDPH of your département',
    deadlineLabel: 'Renew before CMI expiry',
    reminderDays: 60,
    eligibilityHints: const [
      'Disability rate or mobility criteria for CMI type requested',
    ],
    steps: const [
      'Request CMI via MDPH (priority / parking / disability)',
      'Receive card',
      'Use for priority queues, parking, transport reductions where applicable',
    ],
    documents: const [
      'MDPH application',
      'Medical certificate',
      'Identity photo',
    ],
    tags: const ['transport', 'cmi', 'priority', 'certificate'],
  ),
  BenefitScheme(
    id: 'fr-apl-adap',
    name: 'Housing: APL / ALS + accessibility adaptations',
    country: 'France',
    category: 'housing',
    summary:
        'Housing benefits (CAF) plus pathways for adapting rental or owned homes (PCH / Anah / local aids).',
    whoFor: 'Tenants/owners with disability-related housing needs',
    agency: 'CAF + Anah / MDPH',
    url: 'https://www.service-public.fr/particuliers/vosdroits/N20360',
    phone: '3230',
    email: 'contact@caf.fr',
    officeHint: 'CAF for APL; Anah / MDPH for works',
    deadlineLabel: 'APL: ongoing; adaptation grants: before works start',
    reminderDays: 30,
    eligibilityHints: const [
      'Means-tested for APL/ALS',
      'Disability-related adaptation needs for works aids',
    ],
    steps: const [
      'Apply for APL/ALS on caf.fr',
      'Assess adaptation needs with occupational therapist',
      'Combine PCH / Anah / local grants as eligible',
      'Get landlord agreement if renting',
    ],
    documents: const [
      'Lease / ownership proof',
      'Income tax notice',
      'Quotes for adaptation works',
      'MDPH decision if using PCH',
    ],
    tags: const ['housing', 'apl', 'adaptation'],
  ),
  BenefitScheme(
    id: 'fr-anah',
    name: 'Anah home adaptation grants',
    country: 'France',
    category: 'housing',
    summary:
        'National Housing Agency aids for accessibility works for owners and some landlords.',
    whoFor:
        'Owner-occupiers (and eligible landlords) adapting homes for disability/aging',
    agency: 'Anah',
    url: 'https://www.anah.fr/',
    phone: '0 806 706 806',
    officeHint: 'Local Anah / France Rénov’ advisor',
    deadlineLabel: 'Submit before starting works',
    reminderDays: 21,
    eligibilityHints: const [
      'Income ceilings may apply',
      'Works must improve accessibility / autonomy',
    ],
    steps: const [
      'Contact France Rénov’ / Anah advisor',
      'File application with quotes',
      'Wait for agreement before works',
      'Claim after completion',
    ],
    documents: const [
      'Income proof',
      'Property title',
      'Detailed quotes',
      'Medical / OT assessment recommended',
    ],
    tags: const ['housing', 'anah', 'works'],
  ),
  BenefitScheme(
    id: 'fr-tax-disability',
    name: 'Income tax disability allowances',
    country: 'France',
    category: 'tax',
    summary:
        'Extra half-share / disability-related tax reductions and deductions (e.g. dependent with disability, equipment).',
    whoFor: 'Taxpayers with disability or dependent with disability',
    agency: 'DGFiP (impots.gouv.fr)',
    url: 'https://www.impots.gouv.fr/',
    phone: '0 809 401 401',
    officeHint: 'Tax office or impots.gouv.fr messaging',
    deadlineLabel: 'Annual tax return (spring)',
    reminderDays: 30,
    eligibilityHints: const [
      'Disability rate or card as required by tax code',
      'Declare on annual income tax return',
    ],
    steps: const [
      'Gather MDPH / disability card proof',
      'Tick disability boxes on tax return',
      'Keep supporting documents 3+ years',
      'Contact tax office if correction needed',
    ],
    documents: const [
      'MDPH decision or disability card',
      'Tax household composition',
      'Expense receipts if deducting equipment',
    ],
    tags: const ['tax', 'impot', 'disability'],
  ),
  BenefitScheme(
    id: 'fr-tv-tax-exempt',
    name: 'Local tax reliefs for disability',
    country: 'France',
    category: 'tax',
    summary:
        'Possible exemptions or reductions on local taxes for certain disability situations (verify current rules yearly).',
    whoFor: 'Eligible households with disability recognition',
    agency: 'DGFiP / local authority',
    url: 'https://www.service-public.fr/particuliers/vosdroits/N22580',
    phone: '0 809 401 401',
    officeHint: 'Centre des finances publiques',
    deadlineLabel: 'Claim when tax notice arrives',
    reminderDays: 20,
    eligibilityHints: const [
      'Depends on card type, age, and income — verify annually',
    ],
    steps: const [
      'Check eligibility on service-public.fr for current year',
      'Attach disability proof if requested',
      'Request correction if not applied automatically',
    ],
    documents: const ['Disability card / MDPH decision', 'Tax notice'],
    tags: const ['tax', 'local', 'exemption'],
  ),
  BenefitScheme(
    id: 'fr-mdph-certificate',
    name: 'Disability certificates & MDPH decisions',
    country: 'France',
    category: 'certificate',
    summary:
        'Central MDPH pathway for disability rate, CMI, RQTH, PCH, AEEH, and educational plans — the gateway to most French benefits.',
    whoFor: 'Anyone needing official disability recognition in France',
    agency: 'MDPH',
    url: 'https://www.service-public.fr/particuliers/vosdroits/N12230',
    phone: '3977',
    email: 'via departmental MDPH',
    officeHint: 'Maison Départementale des Personnes Handicapées',
    deadlineLabel: 'Renew each decision before expiry',
    reminderDays: 90,
    eligibilityHints: const [
      'Medical evidence of lasting disability or health condition',
      'Residence in the département',
    ],
    steps: const [
      'Download Cerfa MDPH pack',
      'Physician completes medical certificate',
      'Submit to MDPH (online where available)',
      'Receive notification of decisions',
      'Use decisions to open CAF / tax / employment rights',
    ],
    documents: const [
      'Cerfa forms',
      'Medical certificate',
      'Identity and address',
      'Life project / needs statement',
    ],
    tags: const ['certificate', 'mdph', 'disability'],
  ),
  BenefitScheme(
    id: 'fr-aeeh',
    name: 'AEEH — Education allowance for disabled children',
    country: 'France',
    category: 'financial',
    summary:
        'Family benefit for children with disability, with possible complements for care costs.',
    whoFor: 'Families of children with disability under 20',
    agency: 'CAF / MSA + MDPH',
    url: 'https://www.service-public.fr/particuliers/vosdroits/F14809',
    phone: '3230',
    officeHint: 'CAF after MDPH decision',
    deadlineLabel: 'Renew with MDPH decision',
    reminderDays: 60,
    eligibilityHints: const [
      'Child under 20 with MDPH-recognized disability',
      'Permanent care needs criteria',
    ],
    steps: const [
      'MDPH evaluates disability and complements',
      'CAF pays AEEH based on decision',
      'Request complements if care costs high',
    ],
    documents: const ['MDPH decision', 'Family CAF file', 'Medical reports'],
    tags: const ['financial', 'child', 'aeeh'],
  ),
  BenefitScheme(
    id: 'eu-ehic',
    name: 'EHIC / GHIC — Healthcare when traveling in EU',
    country: 'EU',
    category: 'healthcare',
    summary:
        'European Health Insurance Card for medically necessary care during temporary stays in the EU/EEA/Switzerland.',
    whoFor: 'Residents covered by a national health system',
    agency: 'National health insurer (CPAM in France)',
    url:
        'https://www.ameli.fr/assure/droits-demarches/europe-international/protection-sociale-etranger/carte-europeenne-assurance-maladie',
    phone: '3646',
    officeHint: 'Order on ameli.fr',
    deadlineLabel: 'Order before travel; renew before expiry',
    reminderDays: 30,
    eligibilityHints: const [
      'Affiliated to Assurance Maladie or equivalent',
      'Temporary stay abroad',
    ],
    steps: const [
      'Order EHIC on ameli.fr (free)',
      'Carry card when traveling',
      'Present to public providers',
      'Keep receipts for any reclaim',
    ],
    documents: const ['Ameli account / social security number'],
    tags: const ['healthcare', 'travel', 'ehic', 'eu'],
  ),
];

final seedGovernmentOffices = <GovernmentOffice>[
  GovernmentOffice(
    id: 'mdph-paris',
    name: 'MDPH Paris',
    agency: 'MDPH',
    city: 'Paris',
    address: '11 rue Cabanis, 75014 Paris',
    phone: '01 40 33 87 87',
    email: 'contact@mdph.paris.fr',
    hours: 'Mon–Fri 9:00–16:30 (appointment recommended)',
    services: const ['PCH', 'RQTH', 'CMI', 'AEEH', 'PPS'],
    lat: 48.8380,
    lng: 2.3390,
    accessibleNotes:
        'Step-free entrance; priority seating; appointment preferred',
    url: 'https://mdph.paris.fr/',
  ),
  GovernmentOffice(
    id: 'caf-paris',
    name: 'CAF de Paris',
    agency: 'CAF',
    city: 'Paris',
    address: 'Reception hubs across arrondissements — book via caf.fr',
    phone: '3230',
    email: 'via caf.fr messaging',
    hours: 'Varies by reception point',
    services: const ['AAH', 'APL', 'AEEH'],
    lat: 48.8566,
    lng: 2.3522,
    accessibleNotes: 'Use caf.fr to find accessible reception nearby',
    url: 'https://www.caf.fr/',
  ),
  GovernmentOffice(
    id: 'cpam-paris',
    name: 'CPAM Paris',
    agency: 'Assurance Maladie',
    city: 'Paris',
    address: 'Book via ameli.fr — multiple reception points',
    phone: '3646',
    email: 'via ameli.fr',
    hours: 'By appointment',
    services: const ['ALD', 'C2S', 'EHIC'],
    lat: 48.8600,
    lng: 2.3400,
    accessibleNotes: 'Prefer online procedures; on-site assistance on request',
    url: 'https://www.ameli.fr/',
  ),
  GovernmentOffice(
    id: 'mdph-lyon',
    name: 'MDPH du Rhône',
    agency: 'MDPH',
    city: 'Lyon',
    address: 'Département du Rhône — MDPH reception (check mdph69)',
    phone: '04 72 61 80 80',
    email: 'mdph@rhone.fr',
    hours: 'Mon–Fri mornings; appointment recommended',
    services: const ['PCH', 'RQTH', 'CMI', 'certificates'],
    lat: 45.7640,
    lng: 4.8357,
    accessibleNotes: 'Accessible reception; bring medical pack',
    url: 'https://www.rhone.fr/',
  ),
  GovernmentOffice(
    id: 'france-travail-handicap',
    name: 'France Travail — disability advisors',
    agency: 'France Travail / Cap emploi',
    city: 'National network',
    address: 'Local agency — search on francetravail.fr',
    phone: '3949',
    email: 'via local agency',
    hours: 'Agency hours vary',
    services: const ['RQTH follow-up', 'job search', 'Agefiph orientation'],
    lat: 48.8700,
    lng: 2.3300,
    accessibleNotes: 'Ask for conseiller handicap / Cap emploi partnership',
    url: 'https://www.francetravail.fr/',
  ),
  GovernmentOffice(
    id: 'impots-paris',
    name: 'Centre des finances publiques (Paris sample)',
    agency: 'DGFiP',
    city: 'Paris',
    address: 'Find your tax centre on impots.gouv.fr',
    phone: '0 809 401 401',
    email: 'via particular space messaging',
    hours: 'Usually by appointment',
    services: const ['Disability tax shares', 'local tax relief'],
    lat: 48.8500,
    lng: 2.3200,
    accessibleNotes: 'Online account preferred; request accessible appointment',
    url: 'https://www.impots.gouv.fr/',
  ),
  GovernmentOffice(
    id: 'anah-conseil',
    name: 'France Rénov’ / Anah advisor desk',
    agency: 'Anah',
    city: 'National network',
    address: 'Local advisor via france-renov.gouv.fr',
    phone: '0 806 706 806',
    email: 'via local operator',
    hours: 'Phone Mon–Fri',
    services: const ['Home adaptation grants', 'accessibility works'],
    lat: 48.8600,
    lng: 2.3500,
    accessibleNotes: 'Home visits possible for assessments',
    url: 'https://www.anah.fr/',
  ),
];
