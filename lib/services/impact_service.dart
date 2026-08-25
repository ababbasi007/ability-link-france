import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/impact_report.dart';
import '../models/inclusive_job.dart';
import '../models/place.dart';
import '../models/service_provider.dart';
import '../models/user_profile.dart';

class ImpactService {
  ImpactService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> get _latest =>
      _db.collection('impactSnapshots').doc('latest');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('impactReports');

  Stream<ImpactSnapshot?> watchLatest() {
    return _latest.snapshots().map((snap) {
      if (!snap.exists) return null;
      return ImpactSnapshot.fromDoc(snap);
    });
  }

  Stream<List<SavedImpactReport>> watchMyReports() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _reports.where('uid', isEqualTo: id).snapshots().map((snap) {
      final list = snap.docs.map(SavedImpactReport.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Caps how many place/provider/job docs we pull for coverage math.
  /// Counts for the other collections use aggregation queries so they do
  /// not download every document.
  static const sampleLimit = 400;

  Future<int> _count(String collection) async {
    final snap = await _db.collection(collection).count().get();
    return snap.count ?? 0;
  }

  Future<void> refreshSnapshot() async {
    final counted = await Future.wait<Object>([
      _count('reviews'),
      _count('communityPosts'),
      _count('educationPrograms'),
      _count('travelDestinations'),
      _count('barrierAlerts'),
      _db
          .collection('barrierAlerts')
          .where('status', isEqualTo: 'resolved')
          .count()
          .get(),
      _db
          .collection('places')
          .orderBy('score', descending: true)
          .limit(sampleLimit)
          .get(),
      _db
          .collection('providers')
          .orderBy('rating', descending: true)
          .limit(sampleLimit)
          .get(),
      _db.collection('jobs').limit(sampleLimit).get(),
    ]);
    final reviewCount = counted[0] as int;
    final posts = counted[1] as int;
    final education = counted[2] as int;
    final destinations = counted[3] as int;
    final barrierTotal = counted[4] as int;
    final resolvedCount = (counted[5] as AggregateQuerySnapshot).count ?? 0;
    final places = (counted[6] as QuerySnapshot<Map<String, dynamic>>).docs
        .map(AccessiblePlace.fromDoc)
        .toList();
    final providers = (counted[7] as QuerySnapshot<Map<String, dynamic>>).docs
        .map(ServiceProvider.fromDoc)
        .toList();
    final jobs = (counted[8] as QuerySnapshot<Map<String, dynamic>>).docs
        .map(InclusiveJob.fromDoc)
        .toList();
    final open = barrierTotal > resolvedCount
        ? barrierTotal - resolvedCount
        : 0;

    final visible = places.where((p) => !p.hidden).toList();
    final verifiedPlaces = visible.where((p) => p.verified).length;
    final avg = visible.isEmpty
        ? 0.0
        : visible.fold<int>(0, (s, p) => s + p.score) / visible.length;
    final verifiedProviders = providers.where((p) => p.verified).length;
    final jobsAcc = jobs.where((j) => j.accommodations.isNotEmpty).length;

    final coverage = <String, double>{};
    for (final need in const ['wheelchair', 'visual', 'hearing', 'cognitive']) {
      if (visible.isEmpty) {
        coverage[need] = 0;
        continue;
      }
      final n = visible.where((p) => _covers(p, need)).length;
      coverage[need] = n / visible.length;
    }

    final cells = _cellsFor(visible);
    final gaps = _gapsFor(
      visible: visible,
      providers: providers,
      coverage: coverage,
      openBarriers: open,
    );

    final snap = ImpactSnapshot(
      places: visible.length,
      placesVerified: verifiedPlaces,
      avgPlaceScore: avg,
      providers: providers.length,
      providersVerified: verifiedProviders,
      reviews: reviewCount,
      jobs: jobs.length,
      jobsWithAccommodations: jobsAcc,
      barriersOpen: open,
      barriersResolved: resolvedCount,
      communityPosts: posts,
      educationPrograms: education,
      destinations: destinations,
      needCoverage: coverage,
      cells: cells,
      gaps: gaps,
      topSearchedCategories: await _topSearchedCategories(),
      scoreImprovements: await _countScoreImprovements(),
      avgScoreDelta: await _avgScoreDelta(),
    );
    await _latest.set(snap.toMap(), SetOptions(merge: true));
  }

  Future<Map<String, int>> _topSearchedCategories() async {
    try {
      final snap = await _db
          .collection('searchEvents')
          .orderBy('createdAt', descending: true)
          .limit(400)
          .get();
      final counts = <String, int>{};
      for (final doc in snap.docs) {
        final cat = (doc.data()['category'] as String?)?.trim() ?? 'other';
        counts[cat] = (counts[cat] ?? 0) + 1;
      }
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return {
        for (final e in sorted.take(8)) e.key: e.value,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<int> _countScoreImprovements() async {
    try {
      final snap = await _db
          .collectionGroup('activityEvents')
          .where('kind', isEqualTo: 'score')
          .limit(200)
          .get();
      return snap.docs.length;
    } catch (_) {
      return 0;
    }
  }

  Future<double> _avgScoreDelta() async {
    try {
      final snap = await _db
          .collectionGroup('activityEvents')
          .where('kind', isEqualTo: 'score')
          .limit(200)
          .get();
      if (snap.docs.isEmpty) return 0;
      var sum = 0.0;
      var n = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        final from = (d['fromScore'] as num?)?.toInt() ?? 0;
        final to = (d['toScore'] as num?)?.toInt() ?? 0;
        if (to > from) {
          sum += to - from;
          n++;
        }
      }
      return n == 0 ? 0 : sum / n;
    } catch (_) {
      return 0;
    }
  }

  Future<void> saveReport(ImpactSnapshot snapshot) async {
    final id = uid;
    if (id == null) throw StateError('Sign in to save a report');
    final stamp = DateTime.now();
    await _reports.add({
      'uid': id,
      'title':
          'Impact ${stamp.year}-${stamp.month.toString().padLeft(2, '0')}-${stamp.day.toString().padLeft(2, '0')}',
      'body': snapshot.summaryText,
      'shared': false,
      'kpis': {
        'places': snapshot.places,
        'reviews': snapshot.reviews,
        'socialReach': snapshot.socialReach,
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setShared(String id, bool shared) async {
    await _reports.doc(id).update({'shared': shared});
  }

  Future<void> deleteReport(String id) async {
    await _reports.doc(id).delete();
  }

  List<String> passportNeeds(UserProfile? profile) {
    final raw = profile?.accessibilityProfiles ?? const <String>[];
    final out = <String>{};
    for (final p in raw) {
      final x = p.toLowerCase();
      if (x.contains('mobility') || x.contains('wheelchair')) {
        out.add('wheelchair');
      }
      if (x.contains('visual') || x.contains('vision') || x.contains('blind')) {
        out.add('visual');
      }
      if (x.contains('hearing') || x.contains('deaf')) out.add('hearing');
      if (x.contains('cognitive') || x.contains('neuro')) out.add('cognitive');
    }
    return out.toList();
  }

  static bool _covers(AccessiblePlace p, String need) {
    if (p.needs.contains(need)) return true;
    if (need == 'wheelchair' &&
        (p.features.contains('ramp') || p.features.contains('elevator'))) {
      return true;
    }
    if (need == 'visual' && p.features.contains('visual')) return true;
    if (need == 'hearing' && p.features.contains('hearing')) return true;
    return false;
  }

  static List<CoverageCell> _cellsFor(List<AccessiblePlace> places) {
    final buckets = <String, List<AccessiblePlace>>{};
    for (final p in places) {
      final la = (p.lat / 0.08).floor();
      final ln = (p.lng / 0.08).floor();
      final key = '$la,$ln';
      buckets.putIfAbsent(key, () => []).add(p);
    }
    final cells = buckets.entries.map((e) {
      final list = e.value;
      final avg = list.fold<int>(0, (s, p) => s + p.score) / list.length;
      return CoverageCell(
        key: e.key,
        lat: list.fold<double>(0, (s, p) => s + p.lat) / list.length,
        lng: list.fold<double>(0, (s, p) => s + p.lng) / list.length,
        placeCount: list.length,
        verified: list.where((p) => p.verified).length,
        avgScore: avg,
      );
    }).toList()..sort((a, b) => b.placeCount.compareTo(a.placeCount));
    return cells.take(24).toList();
  }

  static List<GapItem> _gapsFor({
    required List<AccessiblePlace> visible,
    required List<ServiceProvider> providers,
    required Map<String, double> coverage,
    required int openBarriers,
  }) {
    final gaps = <GapItem>[];
    for (final e in coverage.entries) {
      if (e.value < 0.4) {
        gaps.add(
          GapItem(
            title: '${_needLabel(e.key)} coverage is thin',
            detail:
                '${(e.value * 100).round()}% of mapped places note ${e.key} access.',
            severity: e.value < 0.2 ? 'high' : 'medium',
            need: e.key,
          ),
        );
      }
    }
    final byCity = <String, int>{};
    for (final p in providers) {
      final city = p.city.trim().isEmpty ? 'Unknown' : p.city.trim();
      byCity[city] = (byCity[city] ?? 0) + 1;
    }
    for (final e in byCity.entries) {
      if (e.value < 2) {
        gaps.add(
          GapItem(
            title: 'Few providers in ${e.key}',
            detail:
                '${e.value} listing${e.value == 1 ? '' : 's'} in that city.',
            severity: 'medium',
          ),
        );
      }
    }
    final cats = <String>{for (final p in visible) p.category};
    for (final cat in ['hospital', 'transit', 'library']) {
      if (!cats.contains(cat)) {
        gaps.add(
          GapItem(
            title: 'No $cat places mapped',
            detail: 'Add verified $cat listings to close a coverage hole.',
            severity: 'high',
          ),
        );
      }
    }
    if (openBarriers > 0) {
      gaps.add(
        GapItem(
          title:
              '$openBarriers open barrier alert${openBarriers == 1 ? '' : 's'}',
          detail: 'Unresolved mobility or access issues still need a fix.',
          severity: openBarriers > 3 ? 'high' : 'low',
        ),
      );
    }
    gaps.sort((a, b) => _rank(b.severity).compareTo(_rank(a.severity)));
    return gaps.take(12).toList();
  }

  static int _rank(String s) => switch (s) {
    'high' => 3,
    'medium' => 2,
    _ => 1,
  };

  static String _needLabel(String need) => switch (need) {
    'wheelchair' => 'Wheelchair / mobility',
    'visual' => 'Visual',
    'hearing' => 'Hearing',
    'cognitive' => 'Cognitive',
    _ => need,
  };
}
