import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/inclusive_job.dart';
import '../models/user_profile.dart';

class JobsService {
  JobsService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _jobs => _db.collection('jobs');
  CollectionReference<Map<String, dynamic>> get _employers =>
      _db.collection('employers');
  CollectionReference<Map<String, dynamic>> get _applications =>
      _db.collection('jobApplications');

  Stream<List<InclusiveJob>> watchJobs({int limit = 250}) {
    return _jobs
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(InclusiveJob.fromDoc).toList());
  }

  Stream<List<JobApplication>> watchMyApplications() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _applications.where('uid', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(JobApplication.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<EmployerProfile?> getEmployer(String id) async {
    final doc = await _employers.doc(id).get();
    if (!doc.exists) return null;
    return EmployerProfile.fromDoc(doc);
  }

  Future<int> ensureSeeded() async {
    final existing = await _jobs.limit(1).get();
    if (existing.docs.isNotEmpty) return 0;
    final batch = _db.batch();
    for (final e in seedEmployers) {
      batch.set(_employers.doc(e.id), {
        ...e.toMap(),
        'seeded': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    for (final job in seedJobs) {
      batch.set(_jobs.doc(job.id), {
        ...job.toMap(),
        'seeded': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return seedJobs.length;
  }

  /// 0–100 score using Accessibility Passport profiles and needs.
  int matchScore(InclusiveJob job, UserProfile? profile) {
    var score = 28;
    if (job.verifiedEmployer) score += 8;
    if (job.remote) score += 10;

    final profiles =
        profile?.accessibilityProfiles.map((e) => e.toLowerCase()).toList() ??
        const <String>[];
    for (final tag in job.inclusiveFor) {
      final t = tag.toLowerCase();
      if (profiles.any((p) => p.contains(t) || t.contains(p))) {
        score += 12;
      }
    }

    final aid = (profile?.mobilityAid ?? '').toLowerCase();
    final needsCaregiver = profile?.needCaregiver ?? false;
    for (final a in job.accommodations) {
      final x = a.toLowerCase();
      if (aid.contains('wheelchair') && x.contains('wheelchair')) score += 10;
      if (needsCaregiver && x.contains('caregiver')) score += 6;
      if (x.contains('caption') ||
          x.contains('screen reader') ||
          x.contains('flexible')) {
        score += 4;
      }
    }

    final city = (profile?.city ?? '').toLowerCase();
    if (!job.remote &&
        city.isNotEmpty &&
        job.city.toLowerCase().split(',').first.trim().isNotEmpty &&
        city.contains(job.city.toLowerCase().split(',').first.trim())) {
      score += 8;
    }

    return score.clamp(0, 99);
  }

  List<InclusiveJob> filter(
    List<InclusiveJob> all, {
    String query = '',
    String category = 'All',
    bool remoteOnly = false,
    bool verifiedOnly = false,
    UserProfile? profile,
  }) {
    var list = all.where((j) {
      if (!j.matchesQuery(query)) return false;
      if (category != 'All' && j.category != category) return false;
      if (remoteOnly && !j.remote) return false;
      if (verifiedOnly && !j.verifiedEmployer) return false;
      return true;
    }).toList();
    list.sort(
      (a, b) => matchScore(b, profile).compareTo(matchScore(a, profile)),
    );
    return list;
  }

  Future<String> apply({
    required InclusiveJob job,
    required String note,
    required List<String> requestedAccommodations,
    int matchScoreValue = 0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to apply');
    final id = '${job.id}_${user.uid}';
    await _applications.doc(id).set({
      'uid': user.uid,
      'userName': user.displayName ?? '',
      'userEmail': user.email ?? '',
      'jobId': job.id,
      'jobTitle': job.title,
      'employerId': job.employerId,
      'employerName': job.employerName,
      'status': 'submitted',
      'note': note,
      'requestedAccommodations': requestedAccommodations,
      'matchScore': matchScoreValue,
      'accommodationStatus': requestedAccommodations.isEmpty
          ? 'none'
          : 'requested',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return id;
  }

  Stream<EmployerProfile?> watchMyEmployer() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _employers.where('ownerUid', isEqualTo: uid).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return EmployerProfile.fromDoc(snap.docs.first);
    });
  }

  Stream<List<InclusiveJob>> watchJobsForEmployer(String employerId) {
    return _jobs
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snap) => snap.docs.map(InclusiveJob.fromDoc).toList());
  }

  Stream<List<JobApplication>> watchEmployerApplications(String employerId) {
    return _applications
        .where('employerId', isEqualTo: employerId)
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(JobApplication.fromDoc).toList();
          list.sort((a, b) {
            final byScore = b.matchScore.compareTo(a.matchScore);
            if (byScore != 0) return byScore;
            return b.createdAt.compareTo(a.createdAt);
          });
          return list;
        });
  }

  Future<String> createEmployer({
    required String name,
    required String industry,
    required String city,
    required String about,
    required List<String> pledges,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to register as an employer');
    final existing = await _employers
        .where('ownerUid', isEqualTo: user.uid)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return existing.docs.first.id;
    final ref = _employers.doc();
    final initials = name.trim().isEmpty
        ? 'EM'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((w) => w[0])
              .join()
              .toUpperCase();
    await ref.set({
      'name': name.trim(),
      'industry': industry.trim(),
      'city': city.trim(),
      'about': about.trim(),
      'inclusivePledges': pledges,
      'verified': false,
      'logoHint': initials,
      'ownerUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateEmployer({
    required String id,
    required String about,
    required List<String> pledges,
    required String city,
    required String industry,
  }) async {
    await _employers.doc(id).update({
      'about': about.trim(),
      'inclusivePledges': pledges,
      'city': city.trim(),
      'industry': industry.trim(),
    });
  }

  Future<void> postJob({
    required EmployerProfile employer,
    required String title,
    required String category,
    required String workType,
    required String city,
    required String summary,
    required String description,
    required String salaryLabel,
    required bool remote,
    required List<String> accommodations,
    required List<String> inclusiveFor,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to post a job');
    await _jobs.doc().set({
      'title': title.trim(),
      'employerId': employer.id,
      'employerName': employer.name,
      'city': city.trim(),
      'workType': workType,
      'category': category,
      'summary': summary.trim(),
      'description': description.trim(),
      'accommodations': accommodations,
      'inclusiveFor': inclusiveFor,
      'salaryLabel': salaryLabel.trim(),
      'remote': remote,
      'verifiedEmployer': employer.verified,
      'postedDaysAgo': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setApplicationStatus(String id, String status) async {
    await _applications.doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAccommodationStatus(String id, String status) async {
    await _applications.doc(id).update({
      'accommodationStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> withdraw(String applicationId) async {
    await _applications.doc(applicationId).update({
      'status': 'withdrawn',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final seedEmployers = <EmployerProfile>[
  EmployerProfile(
    id: 'openpath-labs',
    name: 'OpenPath Labs',
    industry: 'Technology',
    city: 'New York, NY',
    about:
        'Product studio hiring for accessible software. Flexible hours, captioned meetings, and workplace assessments.',
    inclusivePledges: [
      'Remote-first by default',
      'Workplace assessment on request',
      'Paid access internships',
    ],
    verified: true,
    logoHint: 'OP',
  ),
  EmployerProfile(
    id: 'city-access-health',
    name: 'City Access Health',
    industry: 'Healthcare',
    city: 'Brooklyn, NY',
    about:
        'Community clinics looking for coordinators who understand disability services and plain-language care.',
    inclusivePledges: [
      'Step-free offices',
      'Caregiver-friendly schedules',
      'Captioned huddles',
    ],
    verified: true,
    logoHint: 'CA',
  ),
  EmployerProfile(
    id: 'northline-transit',
    name: 'Northline Transit',
    industry: 'Transport',
    city: 'Newark, NJ',
    about:
        'Public mobility operator expanding inclusive customer-support and operations roles.',
    inclusivePledges: ['Shift flexibility', 'Assistive tech stipend'],
    verified: false,
    logoHint: 'NT',
  ),
  EmployerProfile(
    id: 'bright-leaf-edu',
    name: 'Bright Leaf Education',
    industry: 'Education',
    city: 'Remote',
    about:
        'Inclusive learning nonprofit. Roles designed with cognitive and sensory access in mind.',
    inclusivePledges: [
      'Async-first writing',
      'Quiet hours',
      'Screen-reader QA',
    ],
    verified: true,
    logoHint: 'BL',
  ),
];

final seedJobs = <InclusiveJob>[
  InclusiveJob(
    id: 'job-access-pm',
    title: 'Accessibility Product Manager',
    employerId: 'openpath-labs',
    employerName: 'OpenPath Labs',
    city: 'New York, NY',
    workType: 'full-time',
    category: 'Technology',
    remote: true,
    verifiedEmployer: true,
    salaryLabel: '\$95k–\$120k',
    postedDaysAgo: 3,
    inclusiveFor: ['Mobility', 'Visual', 'Hearing', 'Cognitive'],
    accommodations: [
      'Remote',
      'Flexible hours',
      'Captions',
      'Screen reader',
      'Quiet workspace',
    ],
    summary:
        'Shape inclusive product roadmaps with engineers and lived-experience advisors.',
    description:
        'Own accessibility features for a consumer app. Work async, join captioned standups, and partner with disability consultants. Experience with WCAG is a plus — lived experience is valued equally.',
  ),
  InclusiveJob(
    id: 'job-support-coord',
    title: 'Patient Access Coordinator',
    employerId: 'city-access-health',
    employerName: 'City Access Health',
    city: 'Brooklyn, NY',
    workType: 'full-time',
    category: 'Healthcare',
    remote: false,
    verifiedEmployer: true,
    salaryLabel: '\$52k–\$64k',
    postedDaysAgo: 5,
    inclusiveFor: ['Mobility', 'Hearing'],
    accommodations: [
      'Wheelchair access',
      'Flexible hours',
      'Captions',
      'Caregiver-friendly',
    ],
    summary:
        'Help patients book accessible clinic visits and telehealth follow-ups.',
    description:
        'Coordinate appointments, share plain-language instructions, and flag access barriers. Hybrid 3 days on-site in a step-free clinic.',
  ),
  InclusiveJob(
    id: 'job-customer-ops',
    title: 'Inclusive Customer Operations',
    employerId: 'northline-transit',
    employerName: 'Northline Transit',
    city: 'Newark, NJ',
    workType: 'part-time',
    category: 'Support',
    remote: false,
    verifiedEmployer: false,
    salaryLabel: '\$24–\$28/hr',
    postedDaysAgo: 1,
    inclusiveFor: ['Mobility', 'Cognitive'],
    accommodations: ['Wheelchair access', 'Flexible hours', 'Quiet workspace'],
    summary:
        'Support riders who need accessible routing and station assistance.',
    description:
        'Part-time desk role with predictable shifts. Training provided. Optional job-coach presence during onboarding.',
  ),
  InclusiveJob(
    id: 'job-content-access',
    title: 'Accessible Content Specialist',
    employerId: 'bright-leaf-edu',
    employerName: 'Bright Leaf Education',
    city: 'Remote',
    workType: 'contract',
    category: 'Education',
    remote: true,
    verifiedEmployer: true,
    salaryLabel: '\$45–\$65/hr',
    postedDaysAgo: 8,
    inclusiveFor: ['Visual', 'Cognitive', 'Hearing'],
    accommodations: [
      'Remote',
      'Screen reader',
      'Captions',
      'Flexible hours',
      'Quiet workspace',
    ],
    summary:
        'Write and QA courses so they work with screen readers and plain language.',
    description:
        'Contract (6 months). Fully remote. Deliver alt text, captions, and cognitive-load reviews for learning modules.',
  ),
  InclusiveJob(
    id: 'job-data-intern',
    title: 'Inclusive Data Intern',
    employerId: 'openpath-labs',
    employerName: 'OpenPath Labs',
    city: 'New York, NY',
    workType: 'internship',
    category: 'Technology',
    remote: true,
    verifiedEmployer: true,
    salaryLabel: '\$28/hr',
    postedDaysAgo: 2,
    inclusiveFor: ['Cognitive', 'Mobility', 'Visual'],
    accommodations: ['Remote', 'Mentorship', 'Flexible hours', 'Screen reader'],
    summary:
        'Paid internship analyzing accessibility feedback with a dedicated mentor.',
    description:
        '12-week internship. Pair with a mentor twice a week. No degree required — portfolio or community work welcome.',
  ),
  InclusiveJob(
    id: 'job-clinic-ot-liaison',
    title: 'Rehab Services Liaison',
    employerId: 'city-access-health',
    employerName: 'City Access Health',
    city: 'Brooklyn, NY',
    workType: 'full-time',
    category: 'Healthcare',
    remote: false,
    verifiedEmployer: true,
    salaryLabel: '\$68k–\$80k',
    postedDaysAgo: 12,
    inclusiveFor: ['Mobility'],
    accommodations: [
      'Wheelchair access',
      'Flexible hours',
      'Caregiver-friendly',
    ],
    summary:
        'Connect patients to tele-rehab and in-clinic therapy with access notes.',
    description:
        'Bridge clinical teams and Ability Link-style referrals. On-site with elevator access and adjustable desks.',
  ),
];
