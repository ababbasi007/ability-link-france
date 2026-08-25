import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/accessible_routing_prefs.dart';
import '../models/place.dart';
import '../models/route_step.dart';
import 'routing_service.dart';

/// Accessibility-aware routing on top of OSRM + optional OpenRouteService wheelchair.
///
/// Provide an ORS key at build time:
///   `--dart-define=ORS_API_KEY=your_key`
/// Without a key, wheelchair graph options fall back to OSRM walking + local
/// barrier detours / step-free waypoint scoring.
class AccessibleRoutingService {
  AccessibleRoutingService({
    RoutingService? walking,
    String? orsApiKey,
  })  : _walking = walking ?? RoutingService(),
        _orsApiKey = orsApiKey ??
            const String.fromEnvironment('ORS_API_KEY', defaultValue: '');

  final RoutingService _walking;
  final String _orsApiKey;

  bool get hasOrsKey => _orsApiKey.trim().isNotEmpty;

  static const _orsEndpoint =
      'https://api.openrouteservice.org/v2/directions/wheelchair/geojson';

  Future<WalkingRoute> route({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    AccessibleRoutingPrefs prefs = AccessibleRoutingPrefs.defaults,
    List<LatLng> avoidPoints = const [],
    List<AccessiblePlace> nearbyPlaces = const [],
  }) async {
    WalkingRoute? best;

    if (prefs.wheelchairFriendly && hasOrsKey) {
      best = await _orsWheelchair(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        prefs: prefs,
        avoidPoints: avoidPoints,
      );
    }

    best ??= await _walking.walking(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );

    if (avoidPoints.isEmpty && !prefs.wantsAccessibleProfile) {
      return best.copyWith(
        profile: prefs.wheelchairFriendly ? 'wheelchair' : 'walking',
        appliedPrefs: prefs.activeLabels,
      );
    }

    final candidates = <WalkingRoute>[
      best.copyWith(
        profile: best.source == 'ors-wheelchair'
            ? 'wheelchair'
            : 'walking',
        appliedPrefs: prefs.activeLabels,
      ),
    ];

    final vias = _candidateVias(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      prefs: prefs,
      nearbyPlaces: nearbyPlaces,
    );

    for (final via in vias.take(8)) {
      final detour = await _walking.walking(
        fromLat: fromLat,
        fromLng: fromLng,
        toLat: toLat,
        toLng: toLng,
        viaPoints: [LatLng(via.lat, via.lng)],
      );
      candidates.add(
        detour.copyWith(
          profile: 'accessible-detour',
          appliedPrefs: prefs.activeLabels,
          viaPlaceId: via.id,
        ),
      );
    }

    candidates.sort(
      (a, b) => _score(b, prefs, avoidPoints, nearbyPlaces).compareTo(
        _score(a, prefs, avoidPoints, nearbyPlaces),
      ),
    );

    return candidates.first;
  }

  List<AccessiblePlace> _candidateVias({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required AccessibleRoutingPrefs prefs,
    required List<AccessiblePlace> nearbyPlaces,
  }) {
    final midLat = (fromLat + toLat) / 2;
    final midLng = (fromLng + toLng) / 2;
    final scored = <(AccessiblePlace, double)>[];

    for (final p in nearbyPlaces) {
      var s = 0.0;
      if (prefs.preferElevators &&
          (p.features.contains(PlaceAmenities.elevator) ||
              p.features.contains(PlaceAmenities.stepFree) ||
              p.features.contains(PlaceAmenities.ramp))) {
        s += 40;
      }
      if (prefs.preferQuiet && p.features.contains(PlaceAmenities.quiet)) {
        s += 25;
      }
      if (prefs.preferredTransportMode == PreferredTransportMode.transit &&
          p.features.contains(PlaceAmenities.accessibleTransit)) {
        s += 35;
      }
      if (prefs.preferSafe) {
        s += p.score.clamp(0, 100) / 4;
      }
      if (s <= 0) continue;
      // Prefer places near the corridor midpoint.
      final dMid = _distanceMeters(midLat, midLng, p.lat, p.lng);
      s -= dMid / 80;
      scored.add((p, s));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final e in scored.take(10)) e.$1];
  }

  double _score(
    WalkingRoute route,
    AccessibleRoutingPrefs prefs,
    List<LatLng> avoidPoints,
    List<AccessiblePlace> nearbyPlaces,
  ) {
    var s = 0.0;
    if (routeConflicts(route, avoidPoints)) {
      s -= 1000;
    }
    if (route.source == 'ors-wheelchair') s += 120;
    if (route.profile == 'accessible-detour') s += 20;

    // Prefer shorter among accessible candidates.
    s -= route.meters / 40;

    if (prefs.preferElevators || prefs.preferQuiet || prefs.preferSafe) {
      for (final p in nearbyPlaces) {
        final near = route.points.any(
          (pt) => _distanceMeters(pt.latitude, pt.longitude, p.lat, p.lng) < 60,
        );
        if (!near) continue;
        if (prefs.preferElevators &&
            (p.features.contains(PlaceAmenities.elevator) ||
                p.features.contains(PlaceAmenities.stepFree))) {
          s += 15;
        }
        if (prefs.preferQuiet && p.features.contains(PlaceAmenities.quiet)) {
          s += 12;
        }
        if (prefs.preferSafe) s += p.score / 20;
      }
    }
    return s;
  }

  bool routeConflicts(WalkingRoute route, List<LatLng> avoidPoints) {
    if (avoidPoints.isEmpty) return false;
    const thresholdM = 40.0;
    for (final p in route.points) {
      for (final a in avoidPoints) {
        if (_distanceMeters(p.latitude, p.longitude, a.latitude, a.longitude) <=
            thresholdM) {
          return true;
        }
      }
    }
    return false;
  }

  Future<WalkingRoute?> _orsWheelchair({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required AccessibleRoutingPrefs prefs,
    required List<LatLng> avoidPoints,
  }) async {
    try {
      final avoidFeatures = <String>['ferries'];
      if (prefs.avoidStairs) avoidFeatures.add('steps');

      final restrictions = <String, dynamic>{};
      if (prefs.avoidSteepSlopes) restrictions['maximum_incline'] = 6;
      if (prefs.avoidRoughTerrain) {
        restrictions['surface_type'] = 'asphalt';
        restrictions['smoothness_type'] = 'good';
      }

      final body = <String, dynamic>{
        'coordinates': [
          [fromLng, fromLat],
          [toLng, toLat],
        ],
        'instructions': true,
        'elevation': prefs.avoidSteepSlopes,
        'options': {
          'avoid_features': avoidFeatures,
          if (restrictions.isNotEmpty)
            'profile_params': {'restrictions': restrictions},
          if (avoidPoints.isNotEmpty)
            'avoid_polygons': _avoidBufferPolygons(avoidPoints),
        },
      };

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final req = await client.postUrl(Uri.parse(_orsEndpoint));
      req.headers.set('Authorization', _orsApiKey);
      req.headers.set('Content-Type', 'application/json; charset=utf-8');
      req.headers.set('Accept', 'application/json, application/geo+json');
      req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close().timeout(const Duration(seconds: 14));
      final raw = await res.transform(utf8.decoder).join();
      client.close(force: true);
      if (res.statusCode < 200 || res.statusCode >= 300) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final features = json['features'] as List? ?? const [];
      if (features.isEmpty) return null;
      final feature = features.first as Map<String, dynamic>;
      final geom = feature['geometry'] as Map<String, dynamic>?;
      final coords = geom?['coordinates'] as List? ?? const [];
      final points = <LatLng>[
        for (final c in coords)
          if (c is List && c.length >= 2)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (points.length < 2) return null;

      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final summary = props['summary'] as Map<String, dynamic>? ?? {};
      final segments = props['segments'] as List? ?? const [];
      final steps = <RouteStep>[];
      for (final seg in segments) {
        if (seg is! Map<String, dynamic>) continue;
        final segSteps = seg['steps'] as List? ?? const [];
        for (final rawStep in segSteps) {
          if (rawStep is! Map<String, dynamic>) continue;
          final wp = (rawStep['way_points'] as List?) ?? const [];
          LatLng loc = points.last;
          if (wp.isNotEmpty) {
            final idx = (wp.first as num).toInt().clamp(0, points.length - 1);
            loc = points[idx];
          }
          steps.add(
            RouteStep(
              instruction: (rawStep['instruction'] as String?)?.trim().isNotEmpty ==
                      true
                  ? (rawStep['instruction'] as String).trim()
                  : 'Continue',
              location: loc,
              distanceMeters: (rawStep['distance'] as num?)?.toDouble() ?? 0,
              durationSeconds: (rawStep['duration'] as num?)?.toDouble() ?? 0,
              streetName: (rawStep['name'] as String?) ?? '',
              maneuverType: (rawStep['type'] as num?)?.toString() ?? '',
            ),
          );
        }
      }

      return WalkingRoute(
        points: points,
        meters: (summary['distance'] as num?)?.toDouble() ?? 0,
        seconds: (summary['duration'] as num?)?.toDouble() ?? 0,
        source: 'ors-wheelchair',
        steps: steps,
        profile: 'wheelchair',
        appliedPrefs: prefs.activeLabels,
      );
    } catch (_) {
      return null;
    }
  }

  /// Soft circular buffers around known barrier points as GeoJSON MultiPolygon.
  Map<String, dynamic> _avoidBufferPolygons(List<LatLng> points) {
    final polygons = <List<List<List<double>>>>[];
    for (final p in points.take(8)) {
      polygons.add([_circleRing(p.latitude, p.longitude, 35)]);
    }
    return {
      'type': 'MultiPolygon',
      'coordinates': polygons,
    };
  }

  List<List<double>> _circleRing(double lat, double lng, double radiusM) {
    const n = 12;
    final ring = <List<double>>[];
    final dLat = radiusM / 111320.0;
    final dLng = radiusM / (111320.0 * math.cos(lat * math.pi / 180));
    for (var i = 0; i <= n; i++) {
      final a = (i / n) * math.pi * 2;
      ring.add([lng + dLng * math.cos(a), lat + dLat * math.sin(a)]);
    }
    return ring;
  }

  double _distanceMeters(
    double aLat,
    double aLng,
    double bLat,
    double bLng,
  ) {
    const earth = 6371000.0;
    final dLat = _rad(bLat - aLat);
    final dLng = _rad(bLng - aLng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(aLat)) *
            math.cos(_rad(bLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earth * c;
  }

  double _rad(double d) => d * math.pi / 180;
}
