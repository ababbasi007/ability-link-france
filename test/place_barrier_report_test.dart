import 'package:ability_link/models/place_barrier_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeReportDocument sets barrier vs listing type', () {
    final barrier = placeReportDocument(
      uid: 'u1',
      placeId: 'p1',
      placeName: 'Cafe',
      category: PlaceBarrierCategory.elevator.id,
      details: 'Lift out of service',
      photoUrls: const ['https://example.com/1.jpg'],
    );
    expect(barrier['type'], 'barrier');
    expect(barrier['category'], 'elevator');
    expect(barrier['photoUrls'], ['https://example.com/1.jpg']);
    expect(barrier['status'], 'open');

    final listing = placeReportDocument(
      uid: 'u1',
      placeId: 'p1',
      placeName: 'Cafe',
      category: PlaceBarrierCategory.incorrectInfo.id,
      details: 'Wrong hours',
    );
    expect(listing['type'], 'listing');
  });

  test('PlaceBarrierCategory includes audit barrier types', () {
    final ids = PlaceBarrierCategory.all.map((c) => c.id).toSet();
    expect(ids, contains('elevator'));
    expect(ids, contains('ramp'));
    expect(ids, contains('toilet'));
    expect(ids, contains('parking'));
    expect(ids, contains('construction'));
    expect(ids, contains('incorrect_info'));
    expect(PlaceBarrierCategory.byId('ramp')?.label, contains('ramp'));
  });
}
