import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/route_step.dart';

class WalkingRoute {
  const WalkingRoute({
    required this.points,
    required this.meters,
    required this.seconds,
    required this.source,
    this.steps = const [],
    this.profile = 'walking',
    this.appliedPrefs = const [],
    this.viaPlaceId,
  });

  final List<LatLng> points;
  final double meters;
  final double seconds;
  final String source;
  final List<RouteStep> steps;

  /// `walking` | `wheelchair` | `accessible-detour`
  final String profile;
  final List<String> appliedPrefs;
  final String? viaPlaceId;

  String get distanceLabel {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String get durationLabel {
    final m = (seconds / 60).round().clamp(1, 180);
    return '~$m min';
  }

  bool get isLive => source == 'osrm' || source == 'ors-wheelchair';
  bool get hasSteps => steps.isNotEmpty;
  bool get isAccessibleProfile =>
      profile == 'wheelchair' || profile == 'accessible-detour';

  WalkingRoute copyWith({
    List<LatLng>? points,
    double? meters,
    double? seconds,
    String? source,
    List<RouteStep>? steps,
    String? profile,
    List<String>? appliedPrefs,
    String? viaPlaceId,
  }) {
    return WalkingRoute(
      points: points ?? this.points,
      meters: meters ?? this.meters,
      seconds: seconds ?? this.seconds,
      source: source ?? this.source,
      steps: steps ?? this.steps,
      profile: profile ?? this.profile,
      appliedPrefs: appliedPrefs ?? this.appliedPrefs,
      viaPlaceId: viaPlaceId ?? this.viaPlaceId,
    );
  }

  Map<String, dynamic> toJson() => {
    'points': [
      for (final p in points) {'lat': p.latitude, 'lng': p.longitude},
    ],
    'meters': meters,
    'seconds': seconds,
    'source': source,
    'steps': steps.map((s) => s.toJson()).toList(),
    'profile': profile,
    'appliedPrefs': appliedPrefs,
    'viaPlaceId': viaPlaceId,
  };

  factory WalkingRoute.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List? ?? const [];
    final points = <LatLng>[
      for (final p in rawPoints)
        if (p is Map<String, dynamic>)
          LatLng(
            ((p['lat'] as num?) ?? 0).toDouble(),
            ((p['lng'] as num?) ?? 0).toDouble(),
          ),
    ];
    final rawSteps = json['steps'] as List? ?? const [];
    return WalkingRoute(
      points: points,
      meters: ((json['meters'] as num?) ?? 0).toDouble(),
      seconds: ((json['seconds'] as num?) ?? 0).toDouble(),
      source: (json['source'] as String?) ?? 'cached',
      steps: [
        for (final s in rawSteps)
          if (s is Map<String, dynamic>) RouteStep.fromJson(s),
      ],
      profile: (json['profile'] as String?) ?? 'walking',
      appliedPrefs: List<String>.from(
        json['appliedPrefs'] as List? ?? const [],
      ),
      viaPlaceId: json['viaPlaceId'] as String?,
    );
  }
}

/// Walking geometry from the public OSRM demo server, with a straight-line fallback.
class RoutingService {
  static const endpoint = 'https://router.project-osrm.org/route/v1/walking';

  Future<WalkingRoute> walking({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    List<LatLng> viaPoints = const [],
  }) async {
    try {
      final coords = <LatLng>[
        LatLng(fromLat, fromLng),
        ...viaPoints,
        LatLng(toLat, toLng),
      ];
      final coordStr = coords
          .map((c) => '${c.longitude},${c.latitude}')
          .toList()
          .join(';');

      final uri = Uri.parse(
        '$endpoint/$coordStr?overview=full&geometries=geojson&steps=true',
      );
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'com.abilitylink.app');
      final res = await req.close().timeout(const Duration(seconds: 10));
      final body = await res.transform(utf8.decoder).join();
      client.close(force: true);
      if (res.statusCode != 200) {
        return _straight(fromLat, fromLng, toLat, toLng);
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        return _straight(fromLat, fromLng, toLat, toLng);
      }
      final route = routes.first as Map<String, dynamic>;
      final geom = route['geometry'] as Map<String, dynamic>?;
      final routeCoords = geom?['coordinates'] as List? ?? const [];
      final points = <LatLng>[
        for (final c in routeCoords)
          if (c is List && c.length >= 2)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
      if (points.length < 2) {
        return _straight(fromLat, fromLng, toLat, toLng, viaPoints: viaPoints);
      }
      final legs = route['legs'] as List? ?? const [];
      final steps = <RouteStep>[];
      for (final leg in legs) {
        if (leg is! Map<String, dynamic>) continue;
        final legSteps = leg['steps'] as List? ?? const [];
        for (final raw in legSteps) {
          final step = _parseStep(raw);
          if (step != null) steps.add(step);
        }
      }
      if (steps.isEmpty) {
        steps.add(
          RouteStep(
            instruction: 'Head to your destination',
            location: LatLng(toLat, toLng),
            distanceMeters: (route['distance'] as num?)?.toDouble() ?? 0,
            durationSeconds: (route['duration'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
      return WalkingRoute(
        points: points,
        meters: (route['distance'] as num?)?.toDouble() ?? 0,
        seconds: (route['duration'] as num?)?.toDouble() ?? 0,
        source: 'osrm',
        steps: steps,
      );
    } catch (_) {
      return _straight(fromLat, fromLng, toLat, toLng, viaPoints: viaPoints);
    }
  }

  RouteStep? _parseStep(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final maneuver = raw['maneuver'] as Map<String, dynamic>?;
    if (maneuver == null) return null;
    final loc = maneuver['location'] as List?;
    if (loc == null || loc.length < 2) return null;
    final instruction = (maneuver['instruction'] as String?)?.trim();
    return RouteStep(
      instruction: instruction?.isNotEmpty == true
          ? instruction!
          : _fallbackInstruction(maneuver, raw),
      location: LatLng(
        (loc[1] as num).toDouble(),
        (loc[0] as num).toDouble(),
      ),
      distanceMeters: (raw['distance'] as num?)?.toDouble() ?? 0,
      durationSeconds: (raw['duration'] as num?)?.toDouble() ?? 0,
      streetName: (raw['name'] as String?) ?? '',
      maneuverType: (maneuver['type'] as String?) ?? '',
      maneuverModifier: (maneuver['modifier'] as String?) ?? '',
    );
  }

  String _fallbackInstruction(
    Map<String, dynamic> maneuver,
    Map<String, dynamic> step,
  ) {
    final type = (maneuver['type'] as String?) ?? 'continue';
    final modifier = (maneuver['modifier'] as String?) ?? '';
    final street = (step['name'] as String?)?.trim() ?? '';
    final streetPart = street.isNotEmpty ? ' onto $street' : '';
    return switch (type) {
      'depart' => 'Head$streetPart',
      'arrive' => 'Arrive at destination',
      'turn' => 'Turn $modifier$streetPart'.trim(),
      'new name' => 'Continue$streetPart',
      'continue' => 'Continue$streetPart',
      'roundabout' => 'Take the roundabout$streetPart',
      _ => 'Continue$streetPart',
    };
  }

  Future<bool> ping() async {
    final route = await walking(
      fromLat: 40.758,
      fromLng: -73.9855,
      toLat: 40.761,
      toLng: -73.98,
    );
    return route.isLive;
  }

  WalkingRoute _straight(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    {List<LatLng> viaPoints = const []}
  ) {
    const earth = 6371000.0;
    final coords = <LatLng>[
      LatLng(fromLat, fromLng),
      ...viaPoints,
      LatLng(toLat, toLng),
    ];

    double meters = 0;
    for (var i = 0; i < coords.length - 1; i++) {
      final aLat = coords[i].latitude;
      final aLng = coords[i].longitude;
      final bLat = coords[i + 1].latitude;
      final bLng = coords[i + 1].longitude;

      final dLat = _rad(bLat - aLat);
      final dLng = _rad(bLng - aLng);
      final a =
          math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(_rad(aLat)) *
              math.cos(_rad(bLat)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
      meters += earth * c;
    }
    final end = LatLng(toLat, toLng);
    return WalkingRoute(
      points: coords,
      meters: meters,
      seconds: meters / 1.2,
      source: 'straight',
      steps: [
        RouteStep(
          instruction: 'Head toward your destination',
          location: end,
          distanceMeters: meters,
          durationSeconds: meters / 1.2,
        ),
        RouteStep(
          instruction: 'Arrive at destination',
          location: end,
          distanceMeters: 0,
          durationSeconds: 0,
          maneuverType: 'arrive',
        ),
      ],
    );
  }

  double _rad(double d) => d * math.pi / 180;
}
