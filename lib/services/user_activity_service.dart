import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_activity.dart';
import 'place_visit_stats_service.dart';

/// Personal visits, searches, trips, and accessibility score deltas.
class UserActivityService {
  UserActivityService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const _maxLog = 80;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _events {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('activityEvents');
  }

  DocumentReference<Map<String, dynamic>>? get _statsDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('stats').doc('activity');
  }

  CollectionReference<Map<String, dynamic>> get _platformSearches =>
      _db.collection('searchEvents');

  Stream<UserActivityStats> watchStats() {
    final statsRef = _statsDoc;
    final eventsRef = _events;
    if (statsRef == null || eventsRef == null) {
      return Stream.value(const UserActivityStats());
    }
    return statsRef.snapshots().asyncMap((snap) async {
      final visitSnap = await eventsRef
          .where('kind', isEqualTo: 'visit')
          .orderBy('createdAt', descending: true)
          .limit(12)
          .get();
      final visits = visitSnap.docs.map(ActivityEvent.fromDoc).toList();
      return UserActivityStats.fromMap(snap.data(), recentVisits: visits);
    });
  }

  Stream<List<ActivityEvent>> watchRecentActivity({int limit = 40}) {
    final eventsRef = _events;
    if (eventsRef == null) return Stream.value(const []);
    return eventsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ActivityEvent.fromDoc).toList());
  }

  Future<void> recordVisit({
    required String placeId,
    required String placeName,
    required String category,
  }) async {
    if (_uid == null || placeId.isEmpty) return;
    await _append(
      kind: 'visit',
      title: 'Visited $placeName',
      detail: category,
      placeId: placeId,
      category: category.isEmpty ? 'other' : category,
      statsPatch: {'visitCount': FieldValue.increment(1)},
    );
    unawaited(PlaceVisitStatsService().recordVisit(placeId));
  }

  Future<void> recordSearch({
    required String query,
    String? category,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final cat = (category ?? inferSearchCategory(q)).trim();
    final resolved = cat.isEmpty ? 'other' : cat;

    // Platform-level event for "most searched categories" analytics.
    try {
      await _platformSearches.add({
        'uid': _uid ?? '',
        'query': q,
        'category': resolved,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}

    if (_uid == null) return;
    await _append(
      kind: 'search',
      title: 'Searched “$q”',
      detail: resolved,
      category: resolved,
      statsPatch: {
        'searchCount': FieldValue.increment(1),
        'topCategories.$resolved': FieldValue.increment(1),
      },
    );
  }

  Future<void> recordTrip({
    required double meters,
    required String destinationName,
    String placeId = '',
  }) async {
    if (_uid == null || meters <= 0) return;
    await _append(
      kind: 'trip',
      title: 'Traveled to $destinationName',
      detail: '${meters.round()} m',
      placeId: placeId,
      meters: meters,
      statsPatch: {
        'tripCount': FieldValue.increment(1),
        'totalMeters': FieldValue.increment(meters),
      },
    );
  }

  Future<void> recordScoreImprovement({
    required String placeId,
    required String placeName,
    required int fromScore,
    required int toScore,
  }) async {
    if (_uid == null || toScore <= fromScore) return;
    final delta = toScore - fromScore;
    final statsRef = _statsDoc;
    Map<String, dynamic> patch = {
      'scoreImprovements': FieldValue.increment(1),
      'scoreDeltaSum': FieldValue.increment(delta),
    };
    if (statsRef != null) {
      final snap = await statsRef.get();
      final data = snap.data() ?? {};
      final improvements =
          ((data['scoreImprovements'] as num?)?.toInt() ?? 0) + 1;
      final sum = ((data['scoreDeltaSum'] as num?)?.toDouble() ?? 0) + delta;
      patch = {
        'scoreImprovements': improvements,
        'scoreDeltaSum': sum,
        'avgScoreDelta': sum / improvements,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await statsRef.set(patch, SetOptions(merge: true));
    }
    await _append(
      kind: 'score',
      title: 'Score up at $placeName',
      detail: '$fromScore → $toScore (+$delta)',
      placeId: placeId,
      fromScore: fromScore,
      toScore: toScore,
      statsPatch: const {},
    );
  }

  Future<void> _append({
    required String kind,
    required String title,
    required String detail,
    String placeId = '',
    String category = '',
    double meters = 0,
    int fromScore = 0,
    int toScore = 0,
    Map<String, dynamic> statsPatch = const {},
  }) async {
    final eventsRef = _events;
    final statsRef = _statsDoc;
    if (eventsRef == null || statsRef == null) return;

    await eventsRef.add({
      'kind': kind,
      'title': title,
      'detail': detail,
      'placeId': placeId,
      'category': category,
      'meters': meters,
      'fromScore': fromScore,
      'toScore': toScore,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (statsPatch.isNotEmpty) {
      await statsRef.set({
        ...statsPatch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // Soft trim — keep recent window bounded.
    try {
      final all = await eventsRef
          .orderBy('createdAt', descending: true)
          .limit(_maxLog + 25)
          .get();
      if (all.docs.length > _maxLog) {
        for (final d in all.docs.skip(_maxLog)) {
          await d.reference.delete();
        }
      }
    } catch (_) {}
  }
}
