import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../services/routing_service.dart';

/// A walking/accessible route shared with the Care Circle.
class CareSharedRoute {
  const CareSharedRoute({
    required this.id,
    required this.title,
    required this.destinationName,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.meters,
    required this.seconds,
    this.destinationPlaceId = '',
    this.profile = 'walking',
    this.steps = const [],
    this.pointLats = const [],
    this.pointLngs = const [],
    this.createdByName = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String destinationName;
  final String destinationPlaceId;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final double meters;
  final double seconds;
  final String profile;
  final List<String> steps;
  final List<double> pointLats;
  final List<double> pointLngs;
  final String createdByName;
  final DateTime? createdAt;

  String get distanceLabel {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final m = (seconds / 60).round().clamp(1, 180);
    return '~$m min';
  }

  List<LatLng> get points {
    final out = <LatLng>[];
    final n = pointLats.length < pointLngs.length
        ? pointLats.length
        : pointLngs.length;
    for (var i = 0; i < n; i++) {
      out.add(LatLng(pointLats[i], pointLngs[i]));
    }
    return out;
  }

  factory CareSharedRoute.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final created = d['createdAt'];
    return CareSharedRoute(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Shared route',
      destinationName: (d['destinationName'] as String?) ?? '',
      destinationPlaceId: (d['destinationPlaceId'] as String?) ?? '',
      fromLat: (d['fromLat'] as num?)?.toDouble() ?? 0,
      fromLng: (d['fromLng'] as num?)?.toDouble() ?? 0,
      toLat: (d['toLat'] as num?)?.toDouble() ?? 0,
      toLng: (d['toLng'] as num?)?.toDouble() ?? 0,
      meters: (d['meters'] as num?)?.toDouble() ?? 0,
      seconds: (d['seconds'] as num?)?.toDouble() ?? 0,
      profile: (d['profile'] as String?) ?? 'walking',
      steps: List<String>.from(d['steps'] as List? ?? const []),
      pointLats: [
        for (final v in d['pointLats'] as List? ?? const [])
          (v as num).toDouble(),
      ],
      pointLngs: [
        for (final v in d['pointLngs'] as List? ?? const [])
          (v as num).toDouble(),
      ],
      createdByName: (d['createdByName'] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  static Map<String, dynamic> payloadFromWalkingRoute({
    required WalkingRoute route,
    required String destinationName,
    String destinationPlaceId = '',
    String title = '',
    String createdByName = '',
    double? fromLat,
    double? fromLng,
  }) {
    final points = route.points;
    // Downsample long polylines for Firestore size.
    final sampled = <LatLng>[];
    if (points.isEmpty) {
      // keep empty
    } else if (points.length <= 40) {
      sampled.addAll(points);
    } else {
      final step = (points.length / 40).ceil();
      for (var i = 0; i < points.length; i += step) {
        sampled.add(points[i]);
      }
      if (sampled.last != points.last) sampled.add(points.last);
    }

    final origin = points.isNotEmpty
        ? points.first
        : LatLng(fromLat ?? 0, fromLng ?? 0);
    final dest = points.length > 1
        ? points.last
        : LatLng(fromLat ?? 0, fromLng ?? 0);

    return {
      'title': title.trim().isEmpty
          ? 'Route to $destinationName'
          : title.trim(),
      'destinationName': destinationName,
      'destinationPlaceId': destinationPlaceId,
      'fromLat': fromLat ?? origin.latitude,
      'fromLng': fromLng ?? origin.longitude,
      'toLat': dest.latitude,
      'toLng': dest.longitude,
      'meters': route.meters,
      'seconds': route.seconds,
      'profile': route.profile,
      'steps': [
        for (final s in route.steps.take(20)) s.instruction,
      ],
      'pointLats': [for (final p in sampled) p.latitude],
      'pointLngs': [for (final p in sampled) p.longitude],
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
