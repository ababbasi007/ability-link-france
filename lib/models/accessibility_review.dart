import 'package:cloud_firestore/cloud_firestore.dart';

class AccessibilityReview {
  const AccessibilityReview({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.uid,
    required this.authorName,
    required this.overall,
    required this.comment,
    required this.evidence,
    required this.createdAt,
    this.photoUrls = const [],
    this.videoUrls = const [],
    this.helpfulCount = 0,
    this.helpfulBy = const [],
    this.ownerReply = '',
    this.ownerReplyUid = '',
    this.ownerRepliedAt,
    this.mobility,
    this.vision,
    this.hearing,
    this.cognitive,
    this.visitedInPerson = false,
    this.status = 'published',
    this.flagCount = 0,
    this.seeded = false,
  });

  /// `place` or `provider`
  final String id;
  final String targetType;
  final String targetId;
  final String targetName;
  final String uid;
  final String authorName;
  final int overall;
  final int? mobility;
  final int? vision;
  final int? hearing;
  final int? cognitive;
  final String comment;
  final List<String> evidence;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final DateTime createdAt;
  final int helpfulCount;
  /// UIDs that have marked this review as helpful (add-only).
  final List<String> helpfulBy;
  final String ownerReply;
  final String ownerReplyUid;
  final DateTime? ownerRepliedAt;
  final bool visitedInPerson;
  final String status;
  final int flagCount;
  final bool seeded;

  bool get isVisible => status != 'hidden' && flagCount < 3;

  bool get hasEvidence =>
      evidence.isNotEmpty ||
      photoUrls.isNotEmpty ||
      videoUrls.isNotEmpty ||
      visitedInPerson;

  int get completeness {
    var n = 1; // overall
    if (mobility != null) n++;
    if (vision != null) n++;
    if (hearing != null) n++;
    if (cognitive != null) n++;
    return n;
  }

  factory AccessibilityReview.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    final rt = d['ownerRepliedAt'];
    return AccessibilityReview(
      id: doc.id,
      targetType: (d['targetType'] as String?) ?? 'place',
      targetId: (d['targetId'] as String?) ?? '',
      targetName: (d['targetName'] as String?) ?? '',
      uid: (d['uid'] as String?) ?? '',
      authorName: (d['authorName'] as String?) ?? 'Community member',
      overall: (d['overall'] as num?)?.toInt() ?? 0,
      mobility: (d['mobility'] as num?)?.toInt(),
      vision: (d['vision'] as num?)?.toInt(),
      hearing: (d['hearing'] as num?)?.toInt(),
      cognitive: (d['cognitive'] as num?)?.toInt(),
      comment: (d['comment'] as String?) ?? '',
      evidence: List<String>.from(d['evidence'] as List? ?? const []),
      photoUrls: List<String>.from(d['photoUrls'] as List? ?? const []),
      videoUrls: List<String>.from(d['videoUrls'] as List? ?? const []),
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      ownerReply: (d['ownerReply'] as String?) ?? '',
      ownerReplyUid: (d['ownerReplyUid'] as String?) ?? '',
      ownerRepliedAt: rt is Timestamp ? rt.toDate() : null,
      visitedInPerson: d['visitedInPerson'] == true,
      status: (d['status'] as String?) ?? 'published',
      flagCount: (d['flagCount'] as num?)?.toInt() ?? 0,
      helpfulCount: (d['helpfulCount'] as num?)?.toInt() ?? 0,
      helpfulBy: List<String>.from(d['helpfulBy'] as List? ?? const []),
      seeded: d['seeded'] == true,
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    return {
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'uid': uid,
      'authorName': authorName,
      'overall': overall,
      'mobility': mobility,
      'vision': vision,
      'hearing': hearing,
      'cognitive': cognitive,
      'comment': comment,
      'evidence': evidence,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'visitedInPerson': visitedInPerson,
      'status': status,
      'flagCount': flagCount,
      'helpfulCount': helpfulCount,
      'helpfulBy': helpfulBy,
      'seeded': seeded,
      'ownerReply': ownerReply,
      'ownerReplyUid': ownerReplyUid,
      if (ownerRepliedAt != null)
        'ownerRepliedAt': Timestamp.fromDate(ownerRepliedAt!),
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class ReviewStats {
  const ReviewStats({
    required this.count,
    required this.average,
    required this.confidence,
    required this.lastReviewAt,
    required this.recentCount,
    required this.withEvidence,
  });

  final int count;
  final double average;
  final int confidence;
  final DateTime? lastReviewAt;
  final int recentCount;
  final int withEvidence;

  String get freshnessLabel {
    final last = lastReviewAt;
    if (last == null) return 'No community reviews yet';
    final days = DateTime.now().difference(last).inDays;
    if (days <= 0) return 'Updated today';
    if (days == 1) return 'Last review 1 day ago';
    if (days < 30) return 'Last review $days days ago';
    final months = (days / 30).floor();
    return 'Last review $months mo ago';
  }

  String get confidenceLabel {
    if (confidence >= 75) return 'High confidence';
    if (confidence >= 45) return 'Moderate confidence';
    if (count == 0) return 'Unverified by community';
    return 'Early signals';
  }
}
