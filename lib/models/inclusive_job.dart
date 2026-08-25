import 'package:cloud_firestore/cloud_firestore.dart';

class InclusiveJob {
  const InclusiveJob({
    required this.id,
    required this.title,
    required this.employerId,
    required this.employerName,
    required this.city,
    required this.workType,
    required this.category,
    required this.summary,
    required this.description,
    required this.accommodations,
    required this.inclusiveFor,
    required this.salaryLabel,
    this.remote = false,
    this.verifiedEmployer = false,
    this.postedDaysAgo = 2,
  });

  final String id;
  final String title;
  final String employerId;
  final String employerName;
  final String city;

  /// full-time | part-time | contract | internship
  final String workType;
  final String category;
  final String summary;
  final String description;
  final List<String> accommodations;
  final List<String> inclusiveFor;
  final String salaryLabel;
  final bool remote;
  final bool verifiedEmployer;
  final int postedDaysAgo;

  String get workLabel => remote ? '$workType · Remote' : '$workType · $city';

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        employerName.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        summary.toLowerCase().contains(q) ||
        accommodations.any((a) => a.toLowerCase().contains(q));
  }

  factory InclusiveJob.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return InclusiveJob(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Role',
      employerId: (d['employerId'] as String?) ?? '',
      employerName: (d['employerName'] as String?) ?? 'Employer',
      city: (d['city'] as String?) ?? '',
      workType: (d['workType'] as String?) ?? 'full-time',
      category: (d['category'] as String?) ?? 'Other',
      summary: (d['summary'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      accommodations: List<String>.from(
        d['accommodations'] as List? ?? const [],
      ),
      inclusiveFor: List<String>.from(d['inclusiveFor'] as List? ?? const []),
      salaryLabel: (d['salaryLabel'] as String?) ?? '',
      remote: d['remote'] == true,
      verifiedEmployer: d['verifiedEmployer'] == true,
      postedDaysAgo: (d['postedDaysAgo'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'employerId': employerId,
    'employerName': employerName,
    'city': city,
    'workType': workType,
    'category': category,
    'summary': summary,
    'description': description,
    'accommodations': accommodations,
    'inclusiveFor': inclusiveFor,
    'salaryLabel': salaryLabel,
    'remote': remote,
    'verifiedEmployer': verifiedEmployer,
    'postedDaysAgo': postedDaysAgo,
  };
}

class EmployerProfile {
  const EmployerProfile({
    required this.id,
    required this.name,
    required this.industry,
    required this.city,
    required this.about,
    required this.inclusivePledges,
    this.verified = false,
    this.logoHint = '',
    this.ownerUid = '',
  });

  final String id;
  final String name;
  final String industry;
  final String city;
  final String about;
  final List<String> inclusivePledges;
  final bool verified;
  final String logoHint;
  final String ownerUid;

  factory EmployerProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return EmployerProfile(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Employer',
      industry: (d['industry'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      about: (d['about'] as String?) ?? '',
      inclusivePledges: List<String>.from(
        d['inclusivePledges'] as List? ?? const [],
      ),
      verified: d['verified'] == true,
      logoHint: (d['logoHint'] as String?) ?? '',
      ownerUid: (d['ownerUid'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'industry': industry,
    'city': city,
    'about': about,
    'inclusivePledges': inclusivePledges,
    'verified': verified,
    'logoHint': logoHint,
    'ownerUid': ownerUid,
  };
}

class JobApplication {
  const JobApplication({
    required this.id,
    required this.uid,
    required this.jobId,
    required this.jobTitle,
    required this.employerName,
    required this.status,
    required this.note,
    required this.requestedAccommodations,
    required this.createdAt,
    this.matchScore = 0,
    this.employerId = '',
    this.userName = '',
    this.userEmail = '',
    this.accommodationStatus = 'requested',
  });

  final String id;
  final String uid;
  final String jobId;
  final String jobTitle;
  final String employerName;

  /// submitted | withdrawn
  final String status;
  final String note;
  final List<String> requestedAccommodations;
  final DateTime createdAt;
  final int matchScore;
  final String employerId;
  final String userName;
  final String userEmail;

  /// requested | in_progress | fulfilled
  final String accommodationStatus;

  factory JobApplication.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return JobApplication(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      jobId: (d['jobId'] as String?) ?? '',
      jobTitle: (d['jobTitle'] as String?) ?? '',
      employerName: (d['employerName'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'submitted',
      note: (d['note'] as String?) ?? '',
      requestedAccommodations: List<String>.from(
        d['requestedAccommodations'] as List? ?? const [],
      ),
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      matchScore: (d['matchScore'] as num?)?.toInt() ?? 0,
      employerId: (d['employerId'] as String?) ?? '',
      userName: (d['userName'] as String?) ?? 'Candidate',
      userEmail: (d['userEmail'] as String?) ?? '',
      accommodationStatus:
          (d['accommodationStatus'] as String?) ??
          (List<String>.from(
                d['requestedAccommodations'] as List? ?? const [],
              ).isEmpty
              ? 'none'
              : 'requested'),
    );
  }
}

const kInclusionPledges = [
  'Remote-first by default',
  'Workplace assessment on request',
  'Paid access internships',
  'Captioned meetings',
  'Flexible hours',
  'Caregiver-friendly leave',
  'Screen-reader tooling',
  'Plain-language job posts',
];
