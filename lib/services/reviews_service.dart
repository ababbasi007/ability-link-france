import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/accessibility_review.dart';
import 'place_report_service.dart';

class ReviewsService {
  ReviewsService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    FirebaseStorage? storage,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;

  static const maxPhotos = PlaceReportService.maxPhotos;
  static const maxVideos = PlaceReportService.maxVideos;
  static const maxPhotoBytes = PlaceReportService.maxPhotoBytes;
  static const maxVideoBytes = PlaceReportService.maxVideoBytes;

  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');

  Stream<List<AccessibilityReview>> watchFor({
    required String targetType,
    required String targetId,
  }) {
    return _reviews.where('targetId', isEqualTo: targetId).snapshots().map((
      snap,
    ) {
      final list = snap.docs
          .map(AccessibilityReview.fromDoc)
          .where((r) => r.targetType == targetType)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> ensureSeeded() async {
    for (final review in seedReviews) {
      final ref = _reviews.doc(review.id);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          ...review.toMap(),
          'createdAt': Timestamp.fromDate(review.createdAt),
        });
      }
    }
  }

  Future<void> submit({
    required String targetType,
    required String targetId,
    required String targetName,
    required int overall,
    required String comment,
    required List<String> evidence,
    int? mobility,
    int? vision,
    int? hearing,
    int? cognitive,
    bool visitedInPerson = false,
    List<Uint8List> photoBytes = const [],
    List<ReportVideoAttachment> videoAttachments = const [],
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to write a review');
    }
    if (overall < 1 || overall > 5) {
      throw StateError('Choose a star rating');
    }
    if (photoBytes.length > maxPhotos) {
      throw StateError('You can attach up to $maxPhotos photos');
    }
    if (videoAttachments.length > maxVideos) {
      throw StateError('You can attach up to $maxVideos video');
    }

    final id = '${targetType}_${targetId}_${user.uid}';
    final photoUrls = <String>[];
    for (var i = 0; i < photoBytes.length; i++) {
      final bytes = photoBytes[i];
      if (bytes.length > maxPhotoBytes) {
        throw StateError('Each photo must be under 8 MB');
      }
      final path = 'reviews/${user.uid}/$id/photo_$i.jpg';
      final storageRef = _storage.ref(path);
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      photoUrls.add(await storageRef.getDownloadURL());
    }

    final videoUrls = <String>[];
    for (var i = 0; i < videoAttachments.length; i++) {
      final video = videoAttachments[i];
      if (video.bytes.length > maxVideoBytes) {
        throw StateError('Video must be under 50 MB');
      }
      final ext = video.extension.isEmpty ? 'mp4' : video.extension;
      final path = 'reviews/${user.uid}/$id/video_$i.$ext';
      final storageRef = _storage.ref(path);
      await storageRef.putData(
        video.bytes,
        SettableMetadata(contentType: video.contentType),
      );
      videoUrls.add(await storageRef.getDownloadURL());
    }

    await _reviews.doc(id).set({
      'targetType': targetType,
      'targetId': targetId,
      'targetName': targetName,
      'uid': user.uid,
      'authorName': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Ability Link user',
      'overall': overall,
      'mobility': mobility,
      'vision': vision,
      'hearing': hearing,
      'cognitive': cognitive,
      'comment': comment.trim(),
      'evidence': evidence,
      'photoUrls': photoUrls,
      'videoUrls': videoUrls,
      'visitedInPerson': visitedInPerson,
      'status': 'published',
      'flagCount': 0,
      'helpfulCount': 0,
      'helpfulBy': const [],
      'seeded': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add an upvote indicating this review was helpful (add-once).
  Future<void> helpful(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to upvote reviews');
    }
    final uid = user.uid;
    final ref = _reviews.doc(reviewId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() ?? {};
      if (data['uid'] == uid) return; // no self upvote

      final helpfulBy =
          List<String>.from(data['helpfulBy'] as List? ?? const []);
      if (helpfulBy.contains(uid)) return;

      final oldCount = (data['helpfulCount'] as num?)?.toInt() ?? 0;
      tx.update(ref, {
        'helpfulCount': oldCount + 1,
        'helpfulBy': FieldValue.arrayUnion([uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> flag(String reviewId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to report a review');
    }
    final ref = _reviews.doc(reviewId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final count = ((snap.data()?['flagCount'] as num?)?.toInt() ?? 0) + 1;
      tx.update(ref, {
        'flagCount': count,
        'status': count >= 3 ? 'hidden' : 'published',
      });
    });
  }

  /// Provider / owner response to a community accessibility review.
  Future<void> reply({
    required String reviewId,
    required String reply,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to reply to a review');
    }
    final cleaned = reply.trim();
    if (cleaned.isEmpty) {
      throw StateError('Reply cannot be empty');
    }
    await _reviews.doc(reviewId).update({
      'ownerReply': cleaned,
      'ownerReplyUid': user.uid,
      'ownerRepliedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static ReviewStats statsFor(
    List<AccessibilityReview> all, {
    bool listingVerified = false,
  }) {
    final reviews = all.where((r) => r.isVisible).toList();
    if (reviews.isEmpty) {
      return ReviewStats(
        count: 0,
        average: 0,
        confidence: listingVerified ? 20 : 0,
        lastReviewAt: null,
        recentCount: 0,
        withEvidence: 0,
      );
    }

    final avg =
        reviews.fold<double>(0, (s, r) => s + r.overall) / reviews.length;
    final now = DateTime.now();
    final recent = reviews
        .where((r) => now.difference(r.createdAt).inDays <= 90)
        .length;
    final withEvidence = reviews.where((r) => r.hasEvidence).length;
    final last = reviews
        .map((r) => r.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final mean = avg;
    final variance =
        reviews.fold<double>(
          0,
          (s, r) => s + math.pow(r.overall - mean, 2).toDouble(),
        ) /
        reviews.length;
    final stdev = math.sqrt(variance);

    var confidence = 0;
    confidence += math.min(40, reviews.length * 8);
    confidence += math.min(25, recent * 6);
    confidence += math.min(20, withEvidence * 7);
    if (stdev < 0.7) {
      confidence += 15;
    } else if (stdev < 1.2) {
      confidence += 8;
    }
    if (listingVerified) confidence += 10;
    confidence = confidence.clamp(0, 100);

    return ReviewStats(
      count: reviews.length,
      average: avg,
      confidence: confidence,
      lastReviewAt: last,
      recentCount: recent,
      withEvidence: withEvidence,
    );
  }
}

final seedReviews = <AccessibilityReview>[
  AccessibilityReview(
    id: 'place_city-hospital_seed-1',
    targetType: 'place',
    targetId: 'city-hospital',
    targetName: 'City Hospital',
    uid: 'seed-maya',
    authorName: 'Maya R.',
    overall: 5,
    mobility: 5,
    vision: 4,
    hearing: 5,
    comment:
        'Step-free from the street. Staff offered a quiet room without being asked.',
    evidence: ['Ramp', 'Elevator', 'Staff help'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'place_city-hospital_seed-2',
    targetType: 'place',
    targetId: 'city-hospital',
    targetName: 'City Hospital',
    uid: 'seed-leo',
    authorName: 'Leo K.',
    overall: 4,
    mobility: 5,
    vision: 3,
    comment: 'Great ramps, but wayfinding signs are small in the west wing.',
    evidence: ['Ramp', 'Signage'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 21)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'place_green-cafe_seed-1',
    targetType: 'place',
    targetId: 'green-cafe',
    targetName: 'Green Cafe',
    uid: 'seed-priya',
    authorName: 'Priya S.',
    overall: 5,
    mobility: 5,
    hearing: 4,
    comment: 'Wide aisle to the counter. Hearing loop worked at table 4.',
    evidence: ['Ramp', 'Audio'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'place_grand-mall_seed-1',
    targetType: 'place',
    targetId: 'grand-mall',
    targetName: 'Grand Mall',
    uid: 'seed-jordan',
    authorName: 'Jordan P.',
    overall: 3,
    mobility: 3,
    cognitive: 2,
    comment:
        'Elevators work, but Saturday crowds make it stressful to navigate.',
    evidence: ['Elevator', 'Crowding'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 40)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'place_metro-hub_seed-1',
    targetType: 'place',
    targetId: 'metro-hub',
    targetName: 'Metro Transit Hub',
    uid: 'seed-amira',
    authorName: 'Amira H.',
    overall: 4,
    mobility: 4,
    vision: 5,
    hearing: 4,
    comment:
        'Elevator to platform 5 was in service. Audio announcements were clear.',
    evidence: ['Elevator', 'Audio', 'Signage'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 9)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'provider_dr-sara-ahmed_seed-1',
    targetType: 'provider',
    targetId: 'dr-sara-ahmed',
    targetName: 'Dr. Sara Ahmed',
    uid: 'seed-noah',
    authorName: 'Noah T.',
    overall: 5,
    cognitive: 5,
    hearing: 5,
    comment:
        'Captions on the video visit and a plain-language summary after. Felt respected.',
    evidence: ['Staff help'],
    visitedInPerson: false,
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'provider_pt-james-okonkwo_seed-1',
    targetType: 'provider',
    targetId: 'pt-james-okonkwo',
    targetName: 'James Okonkwo',
    uid: 'seed-elena',
    authorName: 'Elena V.',
    overall: 5,
    mobility: 5,
    comment:
        'Adapted every exercise for my wheelchair. Follow-up plan was easy to follow.',
    evidence: ['Staff help'],
    visitedInPerson: false,
    createdAt: DateTime.now().subtract(const Duration(days: 11)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'provider_care-priya-nair_seed-1',
    targetType: 'provider',
    targetId: 'care-priya-nair',
    targetName: 'Priya Nair',
    uid: 'seed-fatima',
    authorName: 'Fatima A.',
    overall: 5,
    cognitive: 5,
    comment:
        'Hired for evening meds and family briefings. Clear notes after every visit.',
    evidence: ['Staff help'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'provider_care-marcus-lee_seed-1',
    targetType: 'provider',
    targetId: 'care-marcus-lee',
    targetName: 'Marcus Lee',
    uid: 'seed-david',
    authorName: 'David R.',
    overall: 5,
    mobility: 5,
    comment:
        'Safe transfers and respectful personal assistance. Booked recurring weekday slots.',
    evidence: ['Staff help', 'Ramp'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'travel_tv-harbor-inn_seed-1',
    targetType: 'travel',
    targetId: 'tv-harbor-inn',
    targetName: 'Harbor Access Inn',
    uid: 'seed-rita',
    authorName: 'Rita M.',
    overall: 5,
    mobility: 5,
    hearing: 5,
    comment:
        'Roll-in shower worked perfectly. Visual alarms and step-free lobby as listed.',
    evidence: ['Ramp', 'Accessible toilet', 'Staff help'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'travel_tv-sensory-tour_seed-1',
    targetType: 'travel',
    targetId: 'tv-sensory-tour',
    targetName: 'Quiet City Highlights Tour',
    uid: 'seed-lee',
    authorName: 'Lee P.',
    overall: 5,
    mobility: 5,
    cognitive: 5,
    comment:
        'Paced for wheelchair users with real rest stops. Captioned guide was clear.',
    evidence: ['Staff help', 'Step-free entrance'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 3)),
    seeded: true,
  ),
  AccessibilityReview(
    id: 'travel_tv-access-shuttle_seed-1',
    targetType: 'travel',
    targetId: 'tv-access-shuttle',
    targetName: 'AccessLink Airport Shuttle',
    uid: 'seed-omar',
    authorName: 'Omar S.',
    overall: 5,
    mobility: 5,
    comment:
        'Lift van on time. Driver secured my chair correctly door-to-door.',
    evidence: ['Staff help', 'Parking'],
    visitedInPerson: true,
    createdAt: DateTime.now().subtract(const Duration(days: 12)),
    seeded: true,
  ),
];
