import 'package:ability_link/models/accessibility_audit.dart';
import 'package:ability_link/models/accessibility_review.dart';
import 'package:ability_link/models/place.dart';
import 'package:ability_link/services/audit_place_promotion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AccessibilityReview stores provider owner reply fields', () {
    final review = AccessibilityReview(
      id: 'r1',
      targetType: 'provider',
      targetId: 'dr-sara-ahmed',
      targetName: 'Dr. Sara Ahmed',
      uid: 'u1',
      authorName: 'Alex',
      overall: 4,
      comment: 'Helpful consult',
      evidence: const ['Staff help'],
      createdAt: DateTime(2026, 1, 1),
      ownerReply: 'Thanks for your feedback.',
      ownerReplyUid: 'provider-owner',
    );

    final payload = review.toMap();
    expect(review.ownerReply, 'Thanks for your feedback.');
    expect(review.ownerReplyUid, 'provider-owner');
    expect(payload['ownerReply'], 'Thanks for your feedback.');
    expect(payload['ownerReplyUid'], 'provider-owner');
  });

  test('new audit toggles infer reception and calm waiting amenities', () {
    const audit = AccessibilityAudit(
      id: 'a1',
      uid: 'u1',
      auditorName: 'Auditor',
      placeId: 'p1',
      placeName: 'Place',
      placeAddress: 'Address',
      category: 'Hospital',
      answers: {
        'staff.receptionDesk': 'yes',
        'cognitive.calmWaitingRoom': 'yes',
      },
    );

    final features = audit.inferredFeatures();
    expect(features, contains(PlaceAmenities.receptionDesk));
    expect(features, contains(PlaceAmenities.calmWaitingRoom));
  });

  test('mobility toggles infer corridors, seating, and low counters', () {
    const audit = AccessibilityAudit(
      id: 'a2',
      uid: 'u1',
      auditorName: 'Auditor',
      placeId: 'p1',
      placeName: 'Place',
      placeAddress: 'Address',
      category: 'Clinic',
      answers: {
        'mobility.corridors': 'yes',
        'mobility.seating': 'yes',
        'mobility.counters': 'yes',
      },
    );

    final features = audit.inferredFeatures();
    expect(features, contains(PlaceAmenities.wideCorridors));
    expect(features, contains(PlaceAmenities.accessibleSeating));
    expect(features, contains(PlaceAmenities.lowCounters));
    expect(PlaceAmenities.label(PlaceAmenities.wideCorridors), 'Wide corridors');
    expect(
      PlaceAmenities.label(PlaceAmenities.accessibleSeating),
      'Accessible seating',
    );
    expect(
      PlaceAmenities.label(PlaceAmenities.lowCounters),
      'Low service counters',
    );
  });

  test('visual toggles infer elevator controls, contrast, audio, lighting', () {
    const audit = AccessibilityAudit(
      id: 'a3',
      uid: 'u1',
      auditorName: 'Auditor',
      placeId: 'p1',
      placeName: 'Place',
      placeAddress: 'Address',
      category: 'Mall',
      answers: {
        'entrance.elevatorControls': 'yes',
        'visual.contrast': 'yes',
        'visual.audible': 'yes',
        'visual.lighting': 'yes',
      },
    );

    final features = audit.inferredFeatures();
    expect(features, contains(PlaceAmenities.brailleElevatorControls));
    expect(features, contains(PlaceAmenities.highContrastSignage));
    expect(features, contains(PlaceAmenities.audioAnnouncements));
    expect(features, contains(PlaceAmenities.goodLighting));
    expect(features, contains(PlaceAmenities.visual));
    expect(features, contains(PlaceAmenities.braille));
    expect(audit.inferredNeeds(), contains('visual'));
  });

  test('hearing toggles infer visual alarms and text chat', () {
    const audit = AccessibilityAudit(
      id: 'a4',
      uid: 'u1',
      auditorName: 'Auditor',
      placeId: 'p1',
      placeName: 'Place',
      placeAddress: 'Address',
      category: 'Office',
      answers: {
        'hearing.emergencyAlerts': 'yes',
        'hearing.textChat': 'yes',
      },
    );

    final features = audit.inferredFeatures();
    expect(features, contains(PlaceAmenities.visualEmergencyAlarms));
    expect(features, contains(PlaceAmenities.textChat));
    expect(features, contains(PlaceAmenities.hearing));
    expect(audit.inferredNeeds(), contains('hearing'));
    expect(
      PlaceAmenities.label(PlaceAmenities.visualEmergencyAlarms),
      'Visual emergency alarms',
    );
    expect(
      PlaceAmenities.label(PlaceAmenities.textChat),
      'Text-based communication',
    );
  });

  test('parking drop-off and EV toggles promote with detail fields', () {
    const audit = AccessibilityAudit(
      id: 'a5',
      uid: 'u1',
      auditorName: 'Auditor',
      placeId: 'p1',
      placeName: 'Place',
      placeAddress: 'Address',
      category: 'Mall',
      answers: {
        'parking.dropOff': 'yes',
        'parking.dropOffDistance': 'Under 15 meters',
        'parking.dropOffLocation': 'East curb · Door B',
        'parking.evParking': 'yes',
        'parking.evCharging': 'yes',
        'parking.evSpaces': '3',
      },
    );

    final features = audit.inferredFeatures();
    expect(features, contains(PlaceAmenities.dropOff));
    expect(features, contains(PlaceAmenities.evAccessibleParking));
    expect(features, contains(PlaceAmenities.evCharging));

    final details = AuditPlacePromotion.extractAuditDetails(audit);
    expect(details['parking.dropOffDistance'], 'Under 15 meters');
    expect(details['parking.dropOffLocation'], 'East curb · Door B');
    expect(details['parking.evSpaces'], '3');
  });
}
