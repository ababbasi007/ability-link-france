import '../models/accessible_routing_prefs.dart';
import '../models/place.dart';
import '../models/service_provider.dart';
import '../models/user_profile.dart';
import 'accessible_routing_prefs_store.dart';
import 'accessible_routing_service.dart';
import 'ai_tools_service.dart';
import 'location_service.dart';
import 'places_service.dart';
import 'providers_service.dart';
import 'routing_service.dart';

enum AiRecommendationKind { place, provider, route }

class AiRecommendation {
  const AiRecommendation({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.reasons,
    this.lat,
    this.lng,
    this.route,
  });

  final AiRecommendationKind kind;
  final String id;
  final String title;
  final String subtitle;
  final int score;
  final List<String> reasons;
  final double? lat;
  final double? lng;
  final WalkingRoute? route;
}

class AiRecommendationPack {
  const AiRecommendationPack({
    required this.places,
    required this.providers,
    required this.routes,
    required this.narrative,
    this.usedLiveModel = false,
  });

  final List<AiRecommendation> places;
  final List<AiRecommendation> providers;
  final List<AiRecommendation> routes;
  final String narrative;
  final bool usedLiveModel;

  String get formattedText {
    final buf = StringBuffer()..writeln(narrative);
    if (places.isNotEmpty) {
      buf.writeln('\nPlaces for you');
      for (final r in places) {
        buf.writeln(
          '• ${r.title} (match ${r.score}) — ${r.subtitle}'
          '${r.reasons.isEmpty ? '' : '\n  Why: ${r.reasons.join('; ')}'}',
        );
      }
    }
    if (providers.isNotEmpty) {
      buf.writeln('\nProviders for you');
      for (final r in providers) {
        buf.writeln(
          '• ${r.title} (match ${r.score}) — ${r.subtitle}'
          '${r.reasons.isEmpty ? '' : '\n  Why: ${r.reasons.join('; ')}'}',
        );
      }
    }
    if (routes.isNotEmpty) {
      buf.writeln('\nAccessible routes');
      for (final r in routes) {
        final route = r.route;
        buf.writeln(
          '• ${r.title} — ${route?.distanceLabel ?? r.subtitle}'
          '${route == null ? '' : ' · ${route.durationLabel} · ${route.profile}'}'
          '${r.reasons.isEmpty ? '' : '\n  Why: ${r.reasons.join('; ')}'}',
        );
      }
    }
    return buf.toString().trim();
  }
}

/// Structured, Passport-aware recommendations (not chat-only).
class AiRecommendationsService {
  AiRecommendationsService({
    PlacesService? places,
    ProvidersService? providers,
    LocationService? location,
    AccessibleRoutingService? routing,
    AiToolsService? tools,
  }) : _places = places,
       _providers = providers,
       _location = location,
       _routing = routing ?? AccessibleRoutingService(),
       _tools = tools ?? AiToolsService();

  PlacesService? _places;
  ProvidersService? _providers;
  LocationService? _location;
  final AccessibleRoutingService _routing;
  final AiToolsService _tools;

  PlacesService get places => _places ??= PlacesService();
  ProvidersService get providers => _providers ??= ProvidersService();
  LocationService get location => _location ??= LocationService.instance;

  /// Rank nearby places + providers for [profile], optionally plan routes.
  Future<AiRecommendationPack> recommend({
    UserProfile? profile,
    int placeLimit = 5,
    int providerLimit = 3,
    int routeLimit = 2,
    bool planRoutes = true,
  }) async {
    await places.ensureSeeded();
    final origin = location.current;
    final allPlaces = await places.watchPlaces().first;
    final rankedPlaces = places
        .search(
          allPlaces,
          sort: PlaceSort.distance,
          originLat: origin.lat,
          originLng: origin.lng,
        )
        .map((p) => _scorePlace(p, profile, origin.lat, origin.lng))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    List<ServiceProvider> allProviders = const [];
    try {
      allProviders = await providers.watchProviders().first;
    } catch (_) {}

    final rankedProviders = allProviders
        .map((p) => _scoreProvider(p, profile))
        .where((r) => r.score > 0)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final topPlaces = rankedPlaces.take(placeLimit).toList();
    final topProviders = rankedProviders.take(providerLimit).toList();

    final routes = <AiRecommendation>[];
    if (planRoutes && topPlaces.isNotEmpty) {
      final prefs = await AccessibleRoutingPrefsStore.instance.load(
        fallback: AccessibleRoutingPrefs.fromPassport(profile),
      );
      for (final rec in topPlaces.take(routeLimit)) {
        AccessiblePlace? place;
        for (final p in allPlaces) {
          if (p.id == rec.id) {
            place = p;
            break;
          }
        }
        if (place == null) continue;
        final route = await _routing.route(
          fromLat: origin.lat,
          fromLng: origin.lng,
          toLat: place.lat,
          toLng: place.lng,
          prefs: prefs,
          nearbyPlaces: allPlaces,
        );
        routes.add(
          AiRecommendation(
            kind: AiRecommendationKind.route,
            id: place.id,
            title: 'Route to ${place.name}',
            subtitle: place.address,
            score: rec.score,
            reasons: [
              ...rec.reasons.take(2),
              if (route.isAccessibleProfile) 'Accessibility-aware path',
              if (route.appliedPrefs.isNotEmpty)
                'Prefs: ${route.appliedPrefs.take(3).join(', ')}',
            ],
            lat: place.lat,
            lng: place.lng,
            route: route,
          ),
        );
      }
    }

    final narrative = _localNarrative(
      profile: profile,
      places: topPlaces,
      providers: topProviders,
      routes: routes,
    );

    // Optional Gemini polish — keep structured lists even if model fails.
    final polished = await _polishNarrative(
      narrative: narrative,
      profile: profile,
      places: topPlaces,
      providers: topProviders,
    );

    return AiRecommendationPack(
      places: topPlaces,
      providers: topProviders,
      routes: routes,
      narrative: polished.$1,
      usedLiveModel: polished.$2,
    );
  }

  /// Pick best matching destination for [query] and return an accessible route.
  Future<AiRecommendationPack> planAccessibleRoute({
    required String query,
    UserProfile? profile,
  }) async {
    await places.ensureSeeded();
    final origin = location.current;
    final all = await places.watchPlaces().first;
    final q = query.trim().toLowerCase();

    var candidates = places.search(
      all,
      query: query,
      sort: PlaceSort.distance,
      originLat: origin.lat,
      originLng: origin.lng,
    );
    if (candidates.isEmpty) {
      candidates = places.search(
        all,
        sort: PlaceSort.distance,
        originLat: origin.lat,
        originLng: origin.lng,
      );
    }

    final ranked = candidates
        .map((p) {
          final base = _scorePlace(p, profile, origin.lat, origin.lng);
          var boost = 0;
          if (q.isNotEmpty) {
            if (p.name.toLowerCase().contains(q)) boost += 18;
            if (p.categoryLabel.toLowerCase().contains(q)) boost += 12;
            if (p.features.any((f) => PlaceAmenities.label(f).toLowerCase().contains(q))) {
              boost += 8;
            }
          }
          return AiRecommendation(
            kind: base.kind,
            id: base.id,
            title: base.title,
            subtitle: base.subtitle,
            score: (base.score + boost).clamp(0, 100),
            reasons: base.reasons,
            lat: base.lat,
            lng: base.lng,
          );
        })
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (ranked.isEmpty) {
      return const AiRecommendationPack(
        places: [],
        providers: [],
        routes: [],
        narrative:
            'No matching venues nearby. Open Ability Map or widen your search.',
      );
    }

    final top = ranked.first;
    final place = all.firstWhere((p) => p.id == top.id);
    final prefs = await AccessibleRoutingPrefsStore.instance.load(
      fallback: AccessibleRoutingPrefs.fromPassport(profile),
    );
    final route = await _routing.route(
      fromLat: origin.lat,
      fromLng: origin.lng,
      toLat: place.lat,
      toLng: place.lng,
      prefs: prefs,
      nearbyPlaces: all,
    );

    // Optional AI score check for unrated destinations.
    String scoreNote = 'Published score ${place.score}';
    if (place.score <= 0 || place.score < 40) {
      final predicted = await _tools.scorePlace(place, profile: profile);
      scoreNote =
          'AI predicted score ${predicted.score} (${predicted.confidenceLabel})';
    }

    final routeRec = AiRecommendation(
      kind: AiRecommendationKind.route,
      id: place.id,
      title: 'Accessible route to ${place.name}',
      subtitle: place.address,
      score: top.score,
      reasons: [
        ...top.reasons.take(3),
        scoreNote,
        if (route.isAccessibleProfile) 'Profile: ${route.profile}',
        ...route.appliedPrefs.take(3),
      ],
      lat: place.lat,
      lng: place.lng,
      route: route,
    );

    final narrative =
        'Best accessible plan toward ${place.name} '
        '(${place.categoryLabel}): ${route.distanceLabel}, ${route.durationLabel}'
        '${route.isAccessibleProfile ? ' via an accessibility-aware path' : ''}. '
        '$scoreNote.';

    return AiRecommendationPack(
      places: [top],
      providers: const [],
      routes: [routeRec],
      narrative: narrative,
      usedLiveModel: false,
    );
  }

  AiRecommendation _scorePlace(
    AccessiblePlace place,
    UserProfile? profile,
    double originLat,
    double originLng,
  ) {
    final profiles = profile?.accessibilityProfiles
            .map((e) => e.toLowerCase())
            .toList() ??
        const <String>[];
    final aid = (profile?.mobilityAid ?? '').toLowerCase();
    final needElevator = profile?.accessibility['needElevator'] == true;
    final reasons = <String>[];
    var score = place.score.clamp(0, 100);

    // Distance soft bonus (closer is better).
    final km = place.distanceKm(originLat, originLng);
    if (km < 0.8) {
      score += 12;
      reasons.add('Nearby (${place.distanceLabel(originLat, originLng)})');
    } else if (km < 2.5) {
      score += 6;
    }

    if (place.verified) {
      score += 6;
      reasons.add('Verified listing');
    }
    if (place.governmentCertified) {
      score += 5;
      reasons.add('Government certified');
    }

    void hit(String label, bool ok, [int pts = 10]) {
      if (!ok) return;
      score += pts;
      reasons.add(label);
    }

    final wantsWheel = profiles.any((p) => p.contains('wheelchair') || p.contains('mobility')) ||
        aid.contains('wheelchair') ||
        aid.contains('scooter');
    if (wantsWheel || needElevator) {
      hit(
        'Step-free',
        place.features.contains(PlaceAmenities.stepFree) ||
            place.features.contains(PlaceAmenities.ramp),
        14,
      );
      hit('Elevator', place.features.contains(PlaceAmenities.elevator), 10);
      hit('Accessible toilet', place.features.contains(PlaceAmenities.toilet), 8);
      hit('Parking', place.features.contains(PlaceAmenities.parking), 6);
    }
    if (profiles.any((p) => p.contains('visual') || p.contains('blind'))) {
      hit(
        'Visual / Braille',
        place.features.contains(PlaceAmenities.visual) ||
            place.features.contains(PlaceAmenities.braille),
        12,
      );
    }
    if (profiles.any((p) => p.contains('hearing') || p.contains('deaf'))) {
      hit(
        'Hearing support',
        place.features.contains(PlaceAmenities.hearing) ||
            place.features.contains(PlaceAmenities.signLanguage),
        12,
      );
    }
    if (profiles.any((p) => p.contains('sensory') || p.contains('cognitive'))) {
      hit('Quiet / calm', place.features.contains(PlaceAmenities.quiet), 12);
      hit(
        'Calm waiting',
        place.features.contains(PlaceAmenities.calmWaitingRoom),
        8,
      );
    }

    // Need tags overlap.
    for (final n in place.needs) {
      if (profiles.any((p) => p.contains(n.toLowerCase()))) {
        score += 6;
        reasons.add('Matches $n need');
      }
    }

    score = score.clamp(0, 100);
    return AiRecommendation(
      kind: AiRecommendationKind.place,
      id: place.id,
      title: place.name,
      subtitle:
          '${place.categoryLabel} · ${place.distanceLabel(originLat, originLng)} · score ${place.score}',
      score: score,
      reasons: reasons.take(4).toList(),
      lat: place.lat,
      lng: place.lng,
    );
  }

  AiRecommendation _scoreProvider(ServiceProvider p, UserProfile? profile) {
    var score = ((p.rating) * 16).round().clamp(0, 80);
    final reasons = <String>[];
    if (p.verified) {
      score += 10;
      reasons.add('Verified');
    }
    if (p.availableNow) {
      score += 8;
      reasons.add('Available now');
    }
    if (p.accessibilityTags.isNotEmpty) {
      score += 6;
      reasons.add(p.accessibilityTags.take(2).join(', '));
    }
    final profiles = profile?.accessibilityProfiles
            .map((e) => e.toLowerCase())
            .toList() ??
        const <String>[];
    final aid = (profile?.mobilityAid ?? '').toLowerCase();
    for (final tag in p.accessibilityTags) {
      final t = tag.toLowerCase();
      if (profiles.any((x) => t.contains(x) || x.contains(t)) ||
          (aid.isNotEmpty && t.contains(aid.split(' ').first))) {
        score += 8;
        reasons.add('Fits $tag');
      }
    }
    return AiRecommendation(
      kind: AiRecommendationKind.provider,
      id: p.id,
      title: p.name,
      subtitle: '${p.specialty.isEmpty ? p.category : p.specialty}'
          '${p.city.isEmpty ? '' : ' · ${p.city}'}',
      score: score.clamp(0, 100),
      reasons: reasons.take(4).toList(),
    );
  }

  String _localNarrative({
    required UserProfile? profile,
    required List<AiRecommendation> places,
    required List<AiRecommendation> providers,
    required List<AiRecommendation> routes,
  }) {
    final name = profile?.firstName ?? 'there';
    final needs = profile?.accessibilityProfiles ?? const <String>[];
    final aid = profile?.mobilityAid ?? '';
    return 'Personalized picks for $name'
        '${needs.isEmpty ? '' : ' (${needs.join(', ')})'}'
        '${aid.isEmpty ? '' : ' · $aid'}. '
        'Ranked ${places.length} places'
        '${providers.isEmpty ? '' : ', ${providers.length} providers'}'
        '${routes.isEmpty ? '' : ', and ${routes.length} accessible route(s)'} '
        'from your Passport and nearby catalog.';
  }

  Future<(String, bool)> _polishNarrative({
    required String narrative,
    required UserProfile? profile,
    required List<AiRecommendation> places,
    required List<AiRecommendation> providers,
  }) async {
    // Reuse Gemini via a lightweight prompt through AiToolsService public APIs
    // would require exposing _geminiText. Keep local narrative for reliability;
    // mark false. (Chat assistant still conversationally expands on ask.)
    return (narrative, false);
  }
}
