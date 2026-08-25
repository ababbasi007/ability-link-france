import 'package:ability_link/models/accessibility_audit.dart';
import 'package:ability_link/models/place.dart';
import 'package:ability_link/models/place_photo_section.dart';
import 'package:ability_link/models/route_step.dart';
import 'package:ability_link/services/audit_place_promotion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('RouteStep formats short distances', () {
    const step = RouteStep(
      instruction: 'Turn right',
      location: LatLng(40.758, -73.9855),
      distanceMeters: 250,
      durationSeconds: 60,
    );
    expect(step.distanceLabel, '250 m');
  });

  test('isFullyAccessible requires score and core features', () {
    const fully = AccessiblePlace(
      id: 'a',
      name: 'A',
      category: 'cafe',
      lat: 0,
      lng: 0,
      score: 90,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: '',
      features: ['stepFree', 'toilet'],
      needs: ['wheelchair'],
      address: '',
    );
    const partial = AccessiblePlace(
      id: 'b',
      name: 'B',
      category: 'cafe',
      lat: 0,
      lng: 0,
      score: 90,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: '',
      features: ['stepFree'],
      needs: ['wheelchair'],
      address: '',
    );
    expect(fully.isFullyAccessible(), isTrue);
    expect(partial.isFullyAccessible(), isFalse);
  });

  test('labeledPhotos prefers photoSections over flat urls', () {
    const place = AccessiblePlace(
      id: 'a',
      name: 'A',
      category: 'hospital',
      lat: 0,
      lng: 0,
      score: 90,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: 'https://example.com/main.jpg',
      features: const [],
      needs: const [],
      address: '',
      photoSections: [
        PlacePhotoSection(
          url: 'https://example.com/ramp.jpg',
          label: 'Step-free ramp',
          source: 'audit',
        ),
      ],
    );
    expect(place.labeledPhotos.length, 1);
    expect(place.labeledPhotos.first.label, 'Step-free ramp');
  });

  test('mergePhotoSections uses audit captions', () {
    const place = AccessiblePlace(
      id: 'city-hospital',
      name: 'City Hospital',
      category: 'hospital',
      lat: 0,
      lng: 0,
      score: 70,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: '',
      features: const [],
      needs: const [],
      address: '',
    );
    const audit = AccessibilityAudit(
      id: 'audit-1',
      uid: 'u1',
      auditorName: 'Alex',
      placeId: 'city-hospital',
      placeName: 'City Hospital',
      placeAddress: 'Addr',
      category: 'Hospital',
      photos: const [
        AuditPhoto(
          uri: 'https://example.com/door.jpg',
          caption: 'Automatic door',
        ),
      ],
    );
    final sections = AuditPlacePromotion.mergePhotoSections(place, audit);
    expect(
      sections.any(
        (s) => s.url.contains('door.jpg') && s.label == 'Automatic door',
      ),
      isTrue,
    );
  });
}
