import 'package:ability_link/models/place.dart';
import 'package:ability_link/services/ai_tools_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const place = AccessiblePlace(
    id: 'p1',
    name: 'City Hospital',
    category: 'hospital',
    lat: 40.75,
    lng: -73.98,
    score: 0,
    rating: 4.2,
    reviewCount: 12,
    openNow: true,
    imageUrl: '',
    features: [
      PlaceAmenities.stepFree,
      PlaceAmenities.elevator,
      PlaceAmenities.toilet,
      PlaceAmenities.parking,
      PlaceAmenities.hearing,
    ],
    needs: ['wheelchair', 'hearing'],
    address: '123 Main',
    verified: true,
    description: 'Step-free hospital with elevators.',
  );

  test('heuristicScore predicts a high score for rich access features', () {
    final prediction = AiToolsService().heuristicScore(place);
    expect(prediction.score, greaterThanOrEqualTo(70));
    expect(prediction.score, lessThanOrEqualTo(100));
    expect(prediction.breakdown.keys, contains('entrance'));
    expect(prediction.gaps, isNotEmpty);
    expect(prediction.usedLiveModel, isFalse);
    expect(prediction.formattedText, contains('Predicted accessibility score'));
  });

  test('fromJson parses model score payload', () {
    final prediction = AiAccessibilityScorePrediction.fromJson({
      'score': 82,
      'confidence': 0.7,
      'summary': 'Mostly accessible.',
      'breakdown': {'entrance': 90, 'restroom': 80},
      'gaps': ['Confirm hearing loop coverage'],
    });
    expect(prediction.score, 82);
    expect(prediction.confidenceLabel, 'Medium confidence');
    expect(prediction.breakdown['entrance'], 90);
    expect(prediction.gaps.first, contains('hearing'));
  });

  test('scorePrediction is part of AiToolKind', () {
    expect(AiToolKind.values, contains(AiToolKind.scorePrediction));
  });
}
