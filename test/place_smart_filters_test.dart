import 'package:ability_link/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isAlwaysOpen detects 24/7 hours text', () {
    const place = AccessiblePlace(
      id: 'x',
      name: 'Test',
      category: 'hospital',
      lat: 0,
      lng: 0,
      score: 90,
      rating: 4,
      reviewCount: 1,
      openNow: false,
      imageUrl: '',
      features: const [],
      needs: const [],
      address: '',
      hours: 'Open 24 hours',
    );
    expect(place.isAlwaysOpen, isTrue);
    expect(place.isOpenNow(), isTrue);
  });

  test('freeParking amenity is distinct from paid parking', () {
    const withFree = AccessiblePlace(
      id: 'a',
      name: 'A',
      category: 'park',
      lat: 0,
      lng: 0,
      score: 80,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: '',
      features: const ['parking', 'freeParking'],
      needs: const [],
      address: '',
    );
    const paidOnly = AccessiblePlace(
      id: 'b',
      name: 'B',
      category: 'mall',
      lat: 0,
      lng: 0,
      score: 80,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: '',
      features: const ['parking'],
      needs: const [],
      address: '',
    );
    expect(withFree.hasAmenity(PlaceAmenities.freeParking), isTrue);
    expect(paidOnly.hasAmenity(PlaceAmenities.freeParking), isFalse);
    expect(paidOnly.hasAmenity(PlaceAmenities.parking), isTrue);
  });

  test('family and pet friendly tags filter independently', () {
    const family = AccessiblePlace(
      id: 'c',
      name: 'C',
      category: 'library',
      lat: 0,
      lng: 0,
      score: 80,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: '',
      features: const ['familyFriendly'],
      needs: const [],
      address: '',
    );
    const pets = AccessiblePlace(
      id: 'd',
      name: 'D',
      category: 'cafe',
      lat: 0,
      lng: 0,
      score: 80,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: '',
      features: const ['petFriendly'],
      needs: const [],
      address: '',
    );
    expect(family.hasAmenity(PlaceAmenities.familyFriendly), isTrue);
    expect(family.hasAmenity(PlaceAmenities.petFriendly), isFalse);
    expect(pets.hasAmenity(PlaceAmenities.petFriendly), isTrue);
    expect(pets.hasAmenity(PlaceAmenities.serviceAnimal), isFalse);
  });
}
