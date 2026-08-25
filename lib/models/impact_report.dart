import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class CoverageCell {
  const CoverageCell({
    required this.key,
    required this.lat,
    required this.lng,
    required this.placeCount,
    required this.verified,
    required this.avgScore,
  });

  final String key;
  final double lat;
  final double lng;
  final int placeCount;
  final int verified;
  final double avgScore;

  LatLng get point => LatLng(lat, lng);

  String get label =>
      '$placeCount place${placeCount == 1 ? '' : 's'} · ${avgScore.round()} avg score';

  Map<String, dynamic> toMap() => {
    'key': key,
    'lat': lat,
    'lng': lng,
    'placeCount': placeCount,
    'verified': verified,
    'avgScore': avgScore,
  };

  factory CoverageCell.fromMap(Map<String, dynamic> d) {
    return CoverageCell(
      key: (d['key'] as String?) ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      placeCount: (d['placeCount'] as num?)?.toInt() ?? 0,
      verified: (d['verified'] as num?)?.toInt() ?? 0,
      avgScore: (d['avgScore'] as num?)?.toDouble() ?? 0,
    );
  }
}

class GapItem {
  const GapItem({
    required this.title,
    required this.detail,
    required this.severity,
    this.need = '',
  });

  final String title;
  final String detail;
  final String severity; // high | medium | low
  final String need;

  Map<String, dynamic> toMap() => {
    'title': title,
    'detail': detail,
    'severity': severity,
    'need': need,
  };

  factory GapItem.fromMap(Map<String, dynamic> d) {
    return GapItem(
      title: (d['title'] as String?) ?? 'Gap',
      detail: (d['detail'] as String?) ?? '',
      severity: (d['severity'] as String?) ?? 'medium',
      need: (d['need'] as String?) ?? '',
    );
  }
}

class ImpactSnapshot {
  const ImpactSnapshot({
    required this.places,
    required this.placesVerified,
    required this.avgPlaceScore,
    required this.providers,
    required this.providersVerified,
    required this.reviews,
    required this.jobs,
    required this.jobsWithAccommodations,
    required this.barriersOpen,
    required this.barriersResolved,
    required this.communityPosts,
    required this.educationPrograms,
    required this.destinations,
    required this.needCoverage,
    required this.cells,
    required this.gaps,
    this.topSearchedCategories = const {},
    this.scoreImprovements = 0,
    this.avgScoreDelta = 0,
    this.updatedAt,
  });

  final int places;
  final int placesVerified;
  final double avgPlaceScore;
  final int providers;
  final int providersVerified;
  final int reviews;
  final int jobs;
  final int jobsWithAccommodations;
  final int barriersOpen;
  final int barriersResolved;
  final int communityPosts;
  final int educationPrograms;
  final int destinations;
  final Map<String, double> needCoverage;
  final List<CoverageCell> cells;
  final List<GapItem> gaps;
  final Map<String, int> topSearchedCategories;
  final int scoreImprovements;
  final double avgScoreDelta;
  final DateTime? updatedAt;

  int get socialReach => reviews + jobsWithAccommodations + communityPosts;

  Map<String, dynamic> toMap() => {
    'places': places,
    'placesVerified': placesVerified,
    'avgPlaceScore': avgPlaceScore,
    'providers': providers,
    'providersVerified': providersVerified,
    'reviews': reviews,
    'jobs': jobs,
    'jobsWithAccommodations': jobsWithAccommodations,
    'barriersOpen': barriersOpen,
    'barriersResolved': barriersResolved,
    'communityPosts': communityPosts,
    'educationPrograms': educationPrograms,
    'destinations': destinations,
    'needCoverage': needCoverage,
    'cells': cells.map((c) => c.toMap()).toList(),
    'gaps': gaps.map((g) => g.toMap()).toList(),
    'topSearchedCategories': topSearchedCategories,
    'scoreImprovements': scoreImprovements,
    'avgScoreDelta': avgScoreDelta,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  factory ImpactSnapshot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['updatedAt'];
    final cov = d['needCoverage'];
    final coverage = <String, double>{};
    if (cov is Map) {
      for (final e in cov.entries) {
        coverage[e.key.toString()] = (e.value as num?)?.toDouble() ?? 0;
      }
    }
    final searched = <String, int>{};
    final top = d['topSearchedCategories'];
    if (top is Map) {
      for (final e in top.entries) {
        searched[e.key.toString()] = (e.value as num?)?.toInt() ?? 0;
      }
    }
    return ImpactSnapshot(
      places: (d['places'] as num?)?.toInt() ?? 0,
      placesVerified: (d['placesVerified'] as num?)?.toInt() ?? 0,
      avgPlaceScore: (d['avgPlaceScore'] as num?)?.toDouble() ?? 0,
      providers: (d['providers'] as num?)?.toInt() ?? 0,
      providersVerified: (d['providersVerified'] as num?)?.toInt() ?? 0,
      reviews: (d['reviews'] as num?)?.toInt() ?? 0,
      jobs: (d['jobs'] as num?)?.toInt() ?? 0,
      jobsWithAccommodations:
          (d['jobsWithAccommodations'] as num?)?.toInt() ?? 0,
      barriersOpen: (d['barriersOpen'] as num?)?.toInt() ?? 0,
      barriersResolved: (d['barriersResolved'] as num?)?.toInt() ?? 0,
      communityPosts: (d['communityPosts'] as num?)?.toInt() ?? 0,
      educationPrograms: (d['educationPrograms'] as num?)?.toInt() ?? 0,
      destinations: (d['destinations'] as num?)?.toInt() ?? 0,
      needCoverage: coverage,
      cells: [
        for (final raw in (d['cells'] as List? ?? const []))
          if (raw is Map) CoverageCell.fromMap(Map<String, dynamic>.from(raw)),
      ],
      gaps: [
        for (final raw in (d['gaps'] as List? ?? const []))
          if (raw is Map) GapItem.fromMap(Map<String, dynamic>.from(raw)),
      ],
      topSearchedCategories: searched,
      scoreImprovements: (d['scoreImprovements'] as num?)?.toInt() ?? 0,
      avgScoreDelta: (d['avgScoreDelta'] as num?)?.toDouble() ?? 0,
      updatedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  String get summaryText {
    final buf = StringBuffer()
      ..writeln('Ability Link impact report')
      ..writeln(
        'Places ${placesVerified}/$places verified · avg score ${avgPlaceScore.round()}',
      )
      ..writeln('Providers ${providersVerified}/$providers verified')
      ..writeln('$reviews accessibility reviews')
      ..writeln(
        '$jobs inclusive jobs ($jobsWithAccommodations with accommodations listed)',
      )
      ..writeln('Barriers $barriersOpen open / $barriersResolved resolved')
      ..writeln('$communityPosts community posts')
      ..writeln('Social-reach index: $socialReach');
    for (final g in gaps.take(5)) {
      buf.writeln('- ${g.title}: ${g.detail}');
    }
    return buf.toString();
  }
}

class SavedImpactReport {
  const SavedImpactReport({
    required this.id,
    required this.uid,
    required this.title,
    required this.body,
    required this.createdAt,
    this.shared = false,
  });

  final String id;
  final String uid;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool shared;

  factory SavedImpactReport.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return SavedImpactReport(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      title: (d['title'] as String?) ?? 'Impact report',
      body: (d['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      shared: d['shared'] == true,
    );
  }
}
