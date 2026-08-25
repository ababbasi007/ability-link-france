import 'package:ability_link/models/accessibility_audit.dart';
import 'package:ability_link/models/place.dart';
import 'package:ability_link/services/audit_place_promotion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extractAuditDetails pulls text and measurement fields', () {
    const audit = AccessibilityAudit(
      id: 'a1',
      uid: 'u1',
      auditorName: 'Alex',
      placeId: 'city-hospital',
      placeName: 'City Hospital',
      placeAddress: '525 E 68th St',
      category: 'Hospital',
      answers: {
        'entrance.rampGradient': '1:12',
        'entrance.doorWidth': '96',
        'entrance.doorType': 'Automatic',
        'parking.spaces': '4',
        'toilet.doorWidth': '90',
      },
      measurements: {'doorWidthCm': '96', 'rampSlopePercent': '5'},
    );

    final details = AuditPlacePromotion.extractAuditDetails(audit);
    expect(details['entrance.rampGradient'], '1:12');
    expect(details['entrance.doorWidth'], '96');
    expect(details['parking.spaces'], '4');
    expect(details['measurement.doorWidthCm'], '96');
  });

  test('buildPlaceUpdate merges features, contact, score, and photos', () {
    const place = AccessiblePlace(
      id: 'city-hospital',
      name: 'City Hospital',
      category: 'hospital',
      lat: 40.77,
      lng: -73.95,
      score: 70,
      rating: 4.5,
      reviewCount: 12,
      openNow: true,
      imageUrl: 'https://example.com/a.jpg',
      features: const ['parking'],
      needs: const ['wheelchair'],
      address: '525 E 68th St',
      photoUrls: ['https://example.com/a.jpg'],
    );
    const audit = AccessibilityAudit(
      id: 'audit-1',
      uid: 'u1',
      auditorName: 'Field team',
      placeId: 'city-hospital',
      placeName: 'City Hospital',
      placeAddress: '525 E 68th St',
      category: 'Hospital',
      phone: '+1 212-555-0100',
      hours: 'Open 24 hours',
      website: 'https://example.org/hospital',
      score: 92,
      answers: {
        'entrance.elevator': 'yes',
        'entrance.ramp': 'yes',
        'toilet.available': 'yes',
        'hearing.loop': 'yes',
        'hearing.captions': 'yes',
        'parking.dropOff': 'yes',
        'entrance.doorWidth': '96',
      },
      photos: const [
        AuditPhoto(
          uri: 'https://example.com/ramp.jpg',
          caption: 'Main ramp',
        ),
      ],
    );

    final patch = AuditPlacePromotion.buildPlaceUpdate(audit: audit, place: place);
    expect(patch['score'], 92);
    expect(patch['phone'], '+1 212-555-0100');
    expect(patch['hours'], 'Open 24 hours');
    expect(patch['website'], 'https://example.org/hospital');
    expect(patch['lastAuditScore'], 92);
    expect(patch['accessibleParkingSpaces'], isNull);

    final features = patch['features'] as List<String>;
    expect(features, contains('elevator'));
    expect(features, contains('ramp'));
    expect(features, contains('toilet'));
    expect(features, contains('captions'));
    expect(features, contains('dropOff'));

    final photos = patch['photoUrls'] as List<String>;
    expect(photos, contains('https://example.com/ramp.jpg'));

    final details = patch['auditDetails'] as Map<String, String>;
    expect(details['entrance.doorWidth'], '96');
  });

  test('labeledDetails returns readable rows', () {
    final rows = AuditPlacePromotion.labeledDetails({
      'entrance.doorWidth': '96',
      'entrance.doorType': 'Automatic',
      'measurement.rampSlopePercent': '5',
    });
    expect(rows.any((r) => r.label == 'Main door width' && r.value == '96'), isTrue);
    expect(rows.any((r) => r.label == 'Door type' && r.value == 'Automatic'), isTrue);
    expect(rows.any((r) => r.label == 'Ramp slope' && r.value == '5'), isTrue);
  });
}
