import 'package:latlong2/latlong.dart';

/// One turn-by-turn instruction from OSRM.
class RouteStep {
  const RouteStep({
    required this.instruction,
    required this.location,
    required this.distanceMeters,
    required this.durationSeconds,
    this.streetName = '',
    this.maneuverType = '',
    this.maneuverModifier = '',
  });

  final String instruction;
  final LatLng location;
  final double distanceMeters;
  final double durationSeconds;
  final String streetName;
  final String maneuverType;
  final String maneuverModifier;

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters.round()} m';
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  Map<String, dynamic> toJson() => {
    'instruction': instruction,
    'lat': location.latitude,
    'lng': location.longitude,
    'distanceMeters': distanceMeters,
    'durationSeconds': durationSeconds,
    'streetName': streetName,
    'maneuverType': maneuverType,
    'maneuverModifier': maneuverModifier,
  };

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      instruction: (json['instruction'] as String?) ?? '',
      location: LatLng(
        ((json['lat'] as num?) ?? 0).toDouble(),
        ((json['lng'] as num?) ?? 0).toDouble(),
      ),
      distanceMeters: ((json['distanceMeters'] as num?) ?? 0).toDouble(),
      durationSeconds: ((json['durationSeconds'] as num?) ?? 0).toDouble(),
      streetName: (json['streetName'] as String?) ?? '',
      maneuverType: (json['maneuverType'] as String?) ?? '',
      maneuverModifier: (json['maneuverModifier'] as String?) ?? '',
    );
  }
}
