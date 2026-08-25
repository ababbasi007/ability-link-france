import 'package:ability_link/data/indoor_venues.dart';
import 'package:ability_link/models/indoor_venue.dart';
import 'package:ability_link/services/indoor_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late IndoorNavigationService nav;
  late IndoorVenue hospital;

  setUp(() {
    nav = IndoorNavigationService();
    hospital = seedIndoorVenues.firstWhere((v) => v.placeId == 'city-hospital');
  });

  test('seed venues cover hospital and mall', () {
    expect(indoorVenueForPlace('city-hospital'), isNotNull);
    expect(indoorVenueForPlace('grand-mall'), isNotNull);
    expect(hospital.floors.length, greaterThanOrEqualTo(3));
  });

  test('room-to-room route uses elevator when step-free', () {
    final route = nav.route(
      venue: hospital,
      fromNodeId: 'ch-g-entrance',
      toNodeId: 'ch-2-therapy',
      preferAccessible: true,
    );
    expect(route, isNotNull);
    expect(route!.nodes.length, greaterThan(2));
    expect(
      route.nodes.any((n) => n.kind == IndoorPoiKind.elevator),
      isTrue,
      reason: 'Accessible path should go via elevator',
    );
    expect(
      route.nodes.any((n) => n.kind == IndoorPoiKind.stairs),
      isFalse,
    );
    expect(route.steps.any((s) => s.instruction.contains('elevator')), isTrue);
  });

  test('accessible restrooms exist per floor', () {
    for (final floor in hospital.floors) {
      final restrooms = hospital.nodes.where(
        (n) => n.floorId == floor.id && n.kind == IndoorPoiKind.restroom,
      );
      expect(restrooms, isNotEmpty, reason: 'Missing restroom on ${floor.label}');
    }
  });

  test('elevators and exits are mapped', () {
    expect(hospital.nodesOfKind(IndoorPoiKind.elevator), isNotEmpty);
    expect(hospital.nodesOfKind(IndoorPoiKind.exit), isNotEmpty);
    expect(hospital.nodesOfKind(IndoorPoiKind.reception), isNotEmpty);
    expect(hospital.nodesOfKind(IndoorPoiKind.help), isNotEmpty);
  });

  test('evacuate finds nearest emergency exit', () {
    final route = nav.evacuate(
      venue: hospital,
      fromNodeId: 'ch-2-therapy',
      preferAccessible: true,
    );
    expect(route, isNotNull);
    expect(route!.nodes.last.kind, IndoorPoiKind.exit);
  });
}
