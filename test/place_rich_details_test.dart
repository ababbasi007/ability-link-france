import 'package:ability_link/models/accessible_service.dart';
import 'package:ability_link/models/place.dart';
import 'package:ability_link/models/place_video_section.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolvedServices prefers explicit listing over derived chips', () {
    const place = AccessiblePlace(
      id: 'hospital',
      name: 'City Hospital',
      category: 'hospital',
      lat: 0,
      lng: 0,
      score: 90,
      rating: 4.5,
      reviewCount: 10,
      openNow: true,
      imageUrl: '',
      features: const ['stepFree', 'elevator'],
      needs: const ['wheelchair'],
      address: '',
      accessibleServices: [
        AccessibleServiceItem(
          id: 'escort',
          label: 'Wheelchair escort',
          description: 'Meet at main entrance.',
        ),
      ],
    );
    final services = place.resolvedServices;
    expect(services.length, 1);
    expect(services.first.label, 'Wheelchair escort');
  });

  test('derived services include audit staff toggles', () {
    const place = AccessiblePlace(
      id: 'clinic',
      name: 'Clinic',
      category: 'clinic',
      lat: 0,
      lng: 0,
      score: 80,
      rating: 4,
      reviewCount: 2,
      openNow: true,
      imageUrl: '',
      features: const ['stepFree'],
      needs: const [],
      address: '',
      auditDetails: {'staff.wheelchairAssist': 'yes'},
    );
    final labels = place.resolvedServices.map((s) => s.label).toList();
    expect(labels, contains('Wheelchair escort'));
  });

  test('place exposes walkthrough and navigation videos', () {
    const place = AccessiblePlace(
      id: 'x',
      name: 'X',
      category: 'mall',
      lat: 0,
      lng: 0,
      score: 80,
      rating: 4,
      reviewCount: 1,
      openNow: true,
      imageUrl: '',
      features: const [],
      needs: const [],
      address: '',
      videoSections: [
        PlaceVideoSection(
          url: 'https://example.com/walk.mp4',
          label: 'Entrance tour',
          kind: 'walkthrough',
        ),
        PlaceVideoSection(
          url: 'https://example.com/nav.mp4',
          label: 'Elevator route',
          kind: 'navigation',
        ),
      ],
    );
    expect(place.hasVideos, isTrue);
    expect(place.videoSections.length, 2);
    expect(place.videoSections.last.isNavigation, isTrue);
  });
}
