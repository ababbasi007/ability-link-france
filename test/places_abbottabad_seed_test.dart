import 'package:ability_link/models/place.dart';
import 'package:ability_link/services/places_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mergeWithSeedCatalog keeps remote and adds missing seed places', () {
    final remote = [
      AccessiblePlace(
        id: 'city-hospital',
        name: 'Remote City Hospital',
        category: 'hospital',
        lat: 40.769,
        lng: -73.954,
        score: 95,
        rating: 4.8,
        reviewCount: 1,
        openNow: true,
        imageUrl: '',
        features: const [],
        needs: const [],
        address: 'NYC',
      ),
    ];

    final merged = PlacesService.mergeWithSeedCatalog(remote);
    final byId = {for (final p in merged) p.id: p};

    expect(byId['city-hospital']!.name, 'Remote City Hospital');
    expect(byId.containsKey('abb-ayub-teaching-hospital'), isTrue);
    expect(byId['abb-ayub-teaching-hospital']!.address, contains('Abbottabad'));
  });

  test('Abbottabad seed places exist near city center', () {
    final abb = seedPlaces.where((p) => p.id.startsWith('abb-')).toList();
    expect(abb.length, greaterThanOrEqualTo(8));
    for (final p in abb) {
      expect(p.lat, inInclusiveRange(34.14, 34.22));
      expect(p.lng, inInclusiveRange(73.20, 73.27));
      expect(
        p.distanceKm(
          PlacesService.defaultOriginLat,
          PlacesService.defaultOriginLng,
        ),
        lessThan(12),
      );
    }
  });
}
