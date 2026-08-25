import 'package:ability_link/services/place_contact_actions.dart';
import 'package:ability_link/services/places_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeWebsite accepts bare domains and https URLs', () {
    expect(
      PlaceContactActions.normalizeWebsite('greencafe.example')?.toString(),
      'https://greencafe.example',
    );
    expect(
      PlaceContactActions.normalizeWebsite(
        'https://cityhospital.example/access',
      )?.toString(),
      'https://cityhospital.example/access',
    );
    expect(PlaceContactActions.normalizeWebsite(''), isNull);
    expect(PlaceContactActions.normalizeWebsite('ftp://bad.example'), isNull);
  });

  test('seed places include phone, hours, and website', () {
    expect(seedPlaces, isNotEmpty);
    for (final place in seedPlaces) {
      expect(place.phone, isNotEmpty, reason: place.name);
      expect(place.hours, isNotEmpty, reason: place.name);
      expect(place.website, isNotEmpty, reason: place.name);
      expect(place.hasContactInfo, isTrue);
      expect(place.catalogVersion, PlacesService.catalogVersion);
    }
  });
}
