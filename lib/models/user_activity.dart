import 'package:cloud_firestore/cloud_firestore.dart';

/// One accessibility / map activity event for the signed-in user.
class ActivityEvent {
  const ActivityEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.createdAt,
    this.placeId = '',
    this.category = '',
    this.meters = 0,
    this.fromScore = 0,
    this.toScore = 0,
  });

  /// visit | search | trip | score | audit | other
  final String id;
  final String kind;
  final String title;
  final String detail;
  final DateTime createdAt;
  final String placeId;
  final String category;
  final double meters;
  final int fromScore;
  final int toScore;

  factory ActivityEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return ActivityEvent(
      id: doc.id,
      kind: (d['kind'] as String?) ?? 'other',
      title: (d['title'] as String?) ?? '',
      detail: (d['detail'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      placeId: (d['placeId'] as String?) ?? '',
      category: (d['category'] as String?) ?? '',
      meters: (d['meters'] as num?)?.toDouble() ?? 0,
      fromScore: (d['fromScore'] as num?)?.toInt() ?? 0,
      toScore: (d['toScore'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Roll-up of personal accessibility analytics.
class UserActivityStats {
  const UserActivityStats({
    this.visitCount = 0,
    this.searchCount = 0,
    this.tripCount = 0,
    this.totalMeters = 0,
    this.scoreImprovements = 0,
    this.avgScoreDelta = 0,
    this.topCategories = const {},
    this.recentVisits = const [],
  });

  final int visitCount;
  final int searchCount;
  final int tripCount;
  final double totalMeters;
  final int scoreImprovements;
  final double avgScoreDelta;
  final Map<String, int> topCategories;
  final List<ActivityEvent> recentVisits;

  String get distanceLabel {
    if (totalMeters < 1000) return '${totalMeters.round()} m';
    return '${(totalMeters / 1000).toStringAsFixed(1)} km';
  }

  factory UserActivityStats.fromMap(
    Map<String, dynamic>? raw, {
    List<ActivityEvent> recentVisits = const [],
  }) {
    if (raw == null) {
      return UserActivityStats(recentVisits: recentVisits);
    }
    final cats = <String, int>{};
    final top = raw['topCategories'];
    if (top is Map) {
      for (final e in top.entries) {
        cats[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
      }
    }
    return UserActivityStats(
      visitCount: (raw['visitCount'] as num?)?.toInt() ?? 0,
      searchCount: (raw['searchCount'] as num?)?.toInt() ?? 0,
      tripCount: (raw['tripCount'] as num?)?.toInt() ?? 0,
      totalMeters: (raw['totalMeters'] as num?)?.toDouble() ?? 0,
      scoreImprovements: (raw['scoreImprovements'] as num?)?.toInt() ?? 0,
      avgScoreDelta: (raw['avgScoreDelta'] as num?)?.toDouble() ?? 0,
      topCategories: cats,
      recentVisits: recentVisits,
    );
  }
}

/// Infer a place category bucket from free-text search.
String inferSearchCategory(String query) {
  final q = query.toLowerCase();
  if (q.contains('hospital') ||
      q.contains('clinic') ||
      q.contains('doctor') ||
      q.contains('pharmacy')) {
    return 'hospital';
  }
  if (q.contains('cafe') ||
      q.contains('coffee') ||
      q.contains('restaurant') ||
      q.contains('food')) {
    return 'cafe';
  }
  if (q.contains('library') || q.contains('book')) return 'library';
  if (q.contains('mall') || q.contains('shop') || q.contains('store')) {
    return 'mall';
  }
  if (q.contains('park') || q.contains('garden')) return 'park';
  if (q.contains('transit') ||
      q.contains('metro') ||
      q.contains('station') ||
      q.contains('bus') ||
      q.contains('train')) {
    return 'transit';
  }
  if (q.contains('wheelchair') || q.contains('ramp') || q.contains('toilet')) {
    return 'accessibility';
  }
  return 'other';
}
