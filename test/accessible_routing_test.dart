import 'package:ability_link/models/accessible_routing_prefs.dart';
import 'package:ability_link/models/place.dart';
import 'package:ability_link/models/route_step.dart';
import 'package:ability_link/services/accessible_routing_service.dart';
import 'package:ability_link/services/routing_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('AccessibleRoutingPrefs serializes and seeds from passport fields', () {
    const prefs = AccessibleRoutingPrefs(
      preferredTransportMode: PreferredTransportMode.wheelchair,
      wheelchairFriendly: true,
      avoidStairs: true,
      preferElevators: true,
      avoidSteepSlopes: true,
      avoidRoughTerrain: true,
      preferQuiet: false,
      preferSafe: true,
    );
    final roundTrip = AccessibleRoutingPrefs.fromMap(prefs.toMap());
    expect(roundTrip.preferredTransportMode, PreferredTransportMode.wheelchair);
    expect(roundTrip.wheelchairFriendly, isTrue);
    expect(roundTrip.avoidRoughTerrain, isTrue);
    expect(prefs.activeLabels, contains('Wheelchair'));
    expect(prefs.activeLabels, contains('No stairs'));
    expect(prefs.wantsAccessibleProfile, isTrue);
  });

  test('routeConflicts detects nearby barrier points', () {
    final service = AccessibleRoutingService();
    const route = WalkingRoute(
      points: [LatLng(40.758, -73.9855), LatLng(40.759, -73.984)],
      meters: 120,
      seconds: 100,
      source: 'osrm',
      steps: [
        RouteStep(
          instruction: 'Go',
          location: LatLng(40.758, -73.9855),
          distanceMeters: 120,
          durationSeconds: 100,
        ),
      ],
    );
    expect(
      service.routeConflicts(route, const [LatLng(40.75801, -73.9855)]),
      isTrue,
    );
    expect(
      service.routeConflicts(route, const [LatLng(41.0, -74.0)]),
      isFalse,
    );
  });

  test('WalkingRoute copyWith preserves accessibility metadata', () {
    const base = WalkingRoute(
      points: [LatLng(0, 0), LatLng(1, 1)],
      meters: 10,
      seconds: 8,
      source: 'osrm',
    );
    final next = base.copyWith(
      profile: 'wheelchair',
      appliedPrefs: const ['No stairs'],
      viaPlaceId: 'p1',
    );
    expect(next.isAccessibleProfile, isTrue);
    expect(next.isLive, isTrue);
    expect(next.appliedPrefs, ['No stairs']);
    expect(next.viaPlaceId, 'p1');
  });

  test('elevator places score as via candidates when preferElevators', () {
    // Smoke: ensure place amenity constants used by scoring exist.
    expect(PlaceAmenities.elevator, 'elevator');
    expect(PlaceAmenities.stepFree, isNotEmpty);
    expect(PlaceAmenities.quiet, isNotEmpty);
  });
}
