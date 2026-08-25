import 'package:ability_link/models/place.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccessiblePlace.isOpenNow', () {
    test('Open 24 hours is always open', () {
      const place = AccessiblePlace(
        id: 'a',
        name: 'A',
        category: 'cafe',
        lat: 0,
        lng: 0,
        score: 10,
        rating: 4,
        reviewCount: 1,
        openNow: false, // Should be ignored if schedule parses.
        imageUrl: '',
        features: const [],
        needs: const [],
        address: '',
        hours: 'Open 24 hours',
      );

      expect(
        place.isOpenNow(now: DateTime(2026, 8, 19, 3, 0)),
        isTrue,
      );
      expect(
        place.isOpenNow(now: DateTime(2026, 8, 19, 23, 59)),
        isTrue,
      );
    });

    test('Parses Mon-Fri and Sat-Sun ranges (English)', () {
      const place = AccessiblePlace(
        id: 'b',
        name: 'B',
        category: 'cafe',
        lat: 0,
        lng: 0,
        score: 10,
        rating: 4,
        reviewCount: 1,
        openNow: false,
        imageUrl: '',
        features: const [],
        needs: const [],
        address: '',
        hours: 'Mon–Fri 7:00–20:00 · Sat–Sun 8:00–18:00',
      );

      // 2026-08-17 is a Monday.
      expect(
        place.isOpenNow(now: DateTime(2026, 8, 17, 10, 0)),
        isTrue,
      );
      expect(
        place.isOpenNow(now: DateTime(2026, 8, 17, 21, 0)),
        isFalse,
      );

      // 2026-08-16 is a Sunday.
      expect(
        place.isOpenNow(now: DateTime(2026, 8, 16, 9, 0)),
        isTrue,
      );
      expect(
        place.isOpenNow(now: DateTime(2026, 8, 16, 19, 0)),
        isFalse,
      );
    });

    test('Parses French abbreviations (Lun-Ven, Sam-Dim)', () {
      const place = AccessiblePlace(
        id: 'c',
        name: 'C',
        category: 'cafe',
        lat: 0,
        lng: 0,
        score: 10,
        rating: 4,
        reviewCount: 1,
        openNow: false,
        imageUrl: '',
        features: const [],
        needs: const [],
        address: '',
        hours: 'Lun–Ven 7:00–20:00 · Sam–Dim 8:00–18:00',
      );

      // 2026-08-17 is Monday.
      expect(place.isOpenNow(now: DateTime(2026, 8, 17, 10, 0)), isTrue);
      expect(place.isOpenNow(now: DateTime(2026, 8, 17, 21, 0)), isFalse);
    });
  });
}

