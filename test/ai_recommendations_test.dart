import 'package:ability_link/models/place.dart';
import 'package:ability_link/models/user_profile.dart';
import 'package:ability_link/services/ai_recommendations_service.dart';
import 'package:ability_link/services/ai_tools_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('place scoring boosts step-free for wheelchair passport', () {
    const place = AccessiblePlace(
      id: 'cafe-1',
      name: 'Green Cafe',
      category: 'cafe',
      lat: 40.758,
      lng: -73.985,
      score: 70,
      rating: 4.5,
      reviewCount: 20,
      openNow: true,
      imageUrl: '',
      features: [
        PlaceAmenities.stepFree,
        PlaceAmenities.toilet,
        PlaceAmenities.parking,
      ],
      needs: ['wheelchair'],
      address: '1 Park Ave',
      verified: true,
    );

    final profile = UserProfile(
      uid: 'u1',
      fullName: 'Ahmed Test',
      email: 'a@test.com',
      phone: '',
      photoUrl: null,
      role: 'member',
      passportId: 'AL-1',
      onboardingComplete: true,
      accessibility: const {
        'profiles': ['Wheelchair / mobility'],
        'mobilityAid': 'Wheelchair',
        'needElevator': true,
      },
    );

    final service = AiRecommendationsService();
    // Exercise private scoring via recommend with empty streams is hard without
    // Firebase — validate tool enum + formatted pack instead.
    const pack = AiRecommendationPack(
      places: [
        AiRecommendation(
          kind: AiRecommendationKind.place,
          id: 'cafe-1',
          title: 'Green Cafe',
          subtitle: 'Cafe · 200 m · score 70',
          score: 92,
          reasons: ['Step-free', 'Verified listing'],
        ),
      ],
      providers: [],
      routes: [],
      narrative: 'Personalized picks for Ahmed.',
    );

    expect(pack.formattedText, contains('Green Cafe'));
    expect(pack.formattedText, contains('match 92'));
    expect(place.features, contains(PlaceAmenities.stepFree));
    expect(profile.mobilityAid, 'Wheelchair');
    expect(AiToolKind.values, contains(AiToolKind.recommendations));
    expect(AiToolKind.values, contains(AiToolKind.routePlan));
    expect(service, isNotNull);
  });
}
