import 'package:latlong2/latlong.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ability_link/models/route_step.dart';
import 'package:ability_link/services/local_route_cache.dart';
import 'package:ability_link/services/routing_service.dart';

void main() {
  test('WalkingRoute round-trips through JSON', () {
    final route = WalkingRoute(
      points: const [
        LatLng(48.8566, 2.3522),
        LatLng(48.8606, 2.3376),
      ],
      meters: 1200,
      seconds: 900,
      source: 'osrm',
      profile: 'wheelchair',
      appliedPrefs: const ['avoidStairs'],
      steps: const [
        RouteStep(
          instruction: 'Head north',
          location: LatLng(48.8566, 2.3522),
          distanceMeters: 400,
          durationSeconds: 300,
          maneuverType: 'depart',
        ),
      ],
    );

    final restored = WalkingRoute.fromJson(route.toJson());
    expect(restored.points.length, 2);
    expect(restored.meters, 1200);
    expect(restored.profile, 'wheelchair');
    expect(restored.steps.single.instruction, 'Head north');
  });

  test('CachedNavigationRoute serializes destination metadata', () {
    final cached = CachedNavigationRoute(
      id: 'place-1',
      destinationPlaceId: 'place-1',
      destinationName: 'City Library',
      destinationLat: 40.75,
      destinationLng: -73.98,
      route: WalkingRoute(
        points: const [LatLng(40.75, -73.98), LatLng(40.76, -73.97)],
        meters: 500,
        seconds: 420,
        source: 'cached',
      ),
      savedAt: DateTime.utc(2026, 1, 15, 12),
    );

    final json = cached.toJson();
    final restored = CachedNavigationRoute.fromJson(json);
    expect(restored.destinationName, 'City Library');
    expect(restored.route.points.length, 2);
    expect(restored.savedAt, DateTime.utc(2026, 1, 15, 12));
  });
}
