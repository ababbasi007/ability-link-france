import 'package:ability_link/models/accessibility_review.dart';
import 'package:ability_link/models/place_barrier_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AccessibilityReview hasEvidence includes photo and video URLs', () {
    final review = AccessibilityReview(
      id: 'r1',
      targetType: 'place',
      targetId: 'city-hospital',
      targetName: 'City Hospital',
      uid: 'u1',
      authorName: 'Alex',
      overall: 4,
      comment: 'Ramp works well',
      evidence: const [],
      photoUrls: ['https://example.com/photo.jpg'],
      videoUrls: const [],
      createdAt: DateTime(2026, 1, 1),
    );
    expect(review.hasEvidence, isTrue);

    final videoOnly = AccessibilityReview(
      id: 'r2',
      targetType: 'place',
      targetId: 'city-hospital',
      targetName: 'City Hospital',
      uid: 'u1',
      authorName: 'Alex',
      overall: 4,
      comment: '',
      evidence: const [],
      photoUrls: const [],
      videoUrls: ['https://example.com/walkthrough.mp4'],
      createdAt: DateTime(2026, 1, 2),
    );
    expect(videoOnly.hasEvidence, isTrue);
  });

  test('feature improvement report uses suggestion type', () {
    final doc = placeReportDocument(
      uid: 'u1',
      placeId: 'p1',
      placeName: 'Place',
      category: PlaceBarrierCategory.featureImprovement.id,
      details: 'Areas: Entry / ramp\n\nAdd a permanent side ramp.',
    );
    expect(doc['type'], 'suggestion');
    expect(doc['category'], 'feature_improvement');
  });

  test('barrier report categories exclude feature improvement', () {
    final ids =
        PlaceBarrierCategory.barrierReportCategories.map((c) => c.id).toSet();
    expect(ids, contains('ramp'));
    expect(ids, isNot(contains('feature_improvement')));
    expect(
      PlaceBarrierCategory.byId('feature_improvement'),
      PlaceBarrierCategory.featureImprovement,
    );
  });
}
