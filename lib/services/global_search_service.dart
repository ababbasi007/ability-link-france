import 'dart:async';

import '../models/benefit_scheme.dart';
import '../models/community.dart';
import '../models/education_program.dart';
import '../models/global_search.dart';
import '../models/place.dart';
import '../models/service_provider.dart';
import '../models/transport_option.dart';
import '../models/travel_destination.dart';
import 'benefits_service.dart';
import 'community_service.dart';
import 'education_service.dart';
import 'places_service.dart';
import 'providers_service.dart';
import 'transport_service.dart';
import 'travel_service.dart';

class GlobalSearchService {
  GlobalSearchService({
    PlacesService? places,
    ProvidersService? providers,
    TravelService? travel,
    EducationService? education,
    BenefitsService? benefits,
    TransportService? transport,
    CommunityService? community,
  }) : _places = places ?? PlacesService(),
       _providers = providers ?? ProvidersService(),
       _travel = travel ?? TravelService(),
       _education = education ?? EducationService(),
       _benefits = benefits ?? BenefitsService(),
       _transport = transport ?? TransportService(),
       _community = community ?? CommunityService();

  final PlacesService _places;
  final ProvidersService _providers;
  final TravelService _travel;
  final EducationService _education;
  final BenefitsService _benefits;
  final TransportService _transport;
  final CommunityService _community;

  static const synonyms = <GlobalSearchKind, List<String>>{
    GlobalSearchKind.places: ['place', 'places', 'nearby'],
    GlobalSearchKind.doctors: [
      'doctor',
      'doctors',
      'physician',
      'clinic',
      'telehealth',
    ],
    GlobalSearchKind.therapists: [
      'therapist',
      'therapists',
      'physio',
      'physiotherapy',
      'rehab',
      'occupational',
    ],
    GlobalSearchKind.caregivers: [
      'caregiver',
      'caregivers',
      'carer',
      'carers',
      'caregiving',
    ],
    GlobalSearchKind.assistants: [
      'assistant',
      'assistants',
      'aide',
      'assistance',
    ],
    GlobalSearchKind.hotels: ['hotel', 'hotels', 'lodging'],
    GlobalSearchKind.restaurants: ['restaurant', 'restaurants', 'dining'],
    GlobalSearchKind.schools: [
      'school',
      'schools',
      'university',
      'universities',
      'college',
    ],
    GlobalSearchKind.courses: ['course', 'courses'],
    GlobalSearchKind.benefits: [
      'benefit',
      'benefits',
      'mdph',
      'aah',
      'aeeh',
      'government',
    ],
    GlobalSearchKind.transportation: [
      'transport',
      'transportation',
      'transit',
      'taxi',
      'metro',
      'bus',
      'parking',
    ],
    GlobalSearchKind.tourism: [
      'tourism',
      'tour',
      'tours',
      'attraction',
      'attractions',
      'travel',
    ],
    GlobalSearchKind.community: [
      'community',
      'forum',
      'group',
      'groups',
      'event',
      'events',
    ],
  };

  Future<void> ensureSeeded() async {
    await Future.wait<void>([
      _places.ensureSeeded().then((_) {}),
      _providers.ensureSeeded().then((_) {}),
      _travel.ensureSeeded().then((_) {}),
      _education.ensureSeeded().then((_) {}),
      _benefits.ensureSeeded().then((_) {}),
      _transport.ensureSeeded().then((_) {}),
      _community.ensureSeeded(),
    ]);
  }

  Stream<GlobalSearchCatalog> watchCatalog() {
    late final StreamController<GlobalSearchCatalog> controller;
    var places = const <AccessiblePlace>[];
    var providers = const <ServiceProvider>[];
    var destinations = const <TravelDestination>[];
    var programs = const <EducationProgram>[];
    var schemes = const <BenefitScheme>[];
    var offices = const <GovernmentOffice>[];
    var transport = const <TransportOption>[];
    var posts = const <CommunityPost>[];
    var groups = const <CommunityGroup>[];
    var events = const <CommunityEvent>[];
    final subs = <StreamSubscription<dynamic>>[];

    void emit() {
      if (controller.isClosed) return;
      controller.add(
        GlobalSearchCatalog(
          places: places,
          providers: providers,
          destinations: destinations,
          programs: programs,
          schemes: schemes,
          offices: offices,
          transport: transport,
          posts: posts,
          groups: groups,
          events: events,
        ),
      );
    }

    controller = StreamController<GlobalSearchCatalog>(
      onListen: () {
        subs.add(
          _places.watchPlaces().listen((v) {
            places = v;
            emit();
          }),
        );
        subs.add(
          _providers.watchProviders().listen((v) {
            providers = v;
            emit();
          }),
        );
        subs.add(
          _travel.watchDestinations().listen((v) {
            destinations = v;
            emit();
          }),
        );
        subs.add(
          _education.watchPrograms().listen((v) {
            programs = v;
            emit();
          }),
        );
        subs.add(
          _benefits.watchSchemes().listen((v) {
            schemes = v;
            emit();
          }),
        );
        subs.add(
          _benefits.watchOffices().listen((v) {
            offices = v;
            emit();
          }),
        );
        subs.add(
          _transport.watchOptions().listen((v) {
            transport = v;
            emit();
          }),
        );
        subs.add(
          _community.watchPosts().listen((v) {
            posts = v;
            emit();
          }),
        );
        subs.add(
          _community.watchGroups().listen((v) {
            groups = v;
            emit();
          }),
        );
        subs.add(
          _community.watchEvents().listen((v) {
            events = v;
            emit();
          }),
        );
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return controller.stream;
  }

  List<GlobalSearchHit> search(
    GlobalSearchCatalog catalog, {
    required String query,
    required GlobalSearchKind scope,
    String need = 'all',
    Set<String> amenities = const {},
    bool openNowOnly = false,
    bool alwaysOpenOnly = false,
    bool verifiedOnly = false,
    bool fullyAccessibleOnly = false,
    double? maxKm,
    double originLat = PlacesService.defaultOriginLat,
    double originLng = PlacesService.defaultOriginLng,
    PlaceSort placeSort = PlaceSort.distance,
  }) {
    final intents = scope == GlobalSearchKind.all
        ? intentsOf(query)
        : <GlobalSearchKind>{};
    final remainder = scope == GlobalSearchKind.all
        ? remainderAfterIntents(query, intents)
        : query;
    final hits = <GlobalSearchHit>[];

    bool want(GlobalSearchKind kind) =>
        scope == GlobalSearchKind.all || scope == kind;

    if (want(GlobalSearchKind.places)) {
      final q = _queryFor(GlobalSearchKind.places, remainder, intents, query);
      final places = _places.search(
        catalog.places,
        query: q,
        need: need,
        amenities: amenities,
        openNowOnly: openNowOnly,
        alwaysOpenOnly: alwaysOpenOnly,
        verifiedOnly: verifiedOnly,
        fullyAccessibleOnly: fullyAccessibleOnly,
        maxKm: maxKm,
        originLat: originLat,
        originLng: originLng,
        sort: placeSort,
      );
      for (final p in places) {
        hits.add(
          GlobalSearchHit(
            key: 'place:${p.id}',
            kind: GlobalSearchKind.places,
            title: p.name,
            subtitle:
                '${p.categoryLabel} · ${p.distanceLabel(originLat, originLng)}',
            imageUrl: p.imageUrl,
            rank: _rank(p.name, query) + p.score,
            payload: p,
          ),
        );
      }
    }

    if (want(GlobalSearchKind.doctors) ||
        want(GlobalSearchKind.therapists) ||
        want(GlobalSearchKind.caregivers) ||
        want(GlobalSearchKind.assistants) ||
        want(GlobalSearchKind.schools)) {
      for (final p in catalog.providers) {
        if (p.hidden) continue;
        if (verifiedOnly && !p.verified) continue;
        final kind = providerKind(p);
        if (kind == null) continue;
        if (!want(kind)) continue;
        final q = _queryFor(kind, remainder, intents, query);
        if (!_providerMatches(p, q, kind, intents)) continue;
        hits.add(
          GlobalSearchHit(
            key: 'provider:${p.id}',
            kind: kind,
            title: p.name,
            subtitle: '${p.specialty} · ${p.city} · ${p.priceLabel}',
            imageUrl: p.photoUrl,
            rank:
                _rank(p.name, query) +
                (p.rating * 12).round() +
                (p.verified ? 8 : 0),
            payload: p,
          ),
        );
      }
    }

    if (want(GlobalSearchKind.hotels) ||
        want(GlobalSearchKind.restaurants) ||
        want(GlobalSearchKind.tourism) ||
        want(GlobalSearchKind.transportation)) {
      for (final d in catalog.destinations) {
        if (verifiedOnly && !d.verified) continue;
        final kind = travelKind(d);
        if (!want(kind)) continue;
        if (kind == GlobalSearchKind.transportation &&
            scope == GlobalSearchKind.tourism) {
          continue;
        }
        final q = _queryFor(kind, remainder, intents, query);
        if (!_textOrIntent(d.matchesQuery(q), kind, intents, q)) continue;
        hits.add(
          GlobalSearchHit(
            key: 'travel:${d.id}',
            kind: kind,
            title: d.name,
            subtitle: '${d.kindLabel} · ${d.city}',
            imageUrl: d.imageUrl,
            rank:
                _rank(d.name, query) +
                (d.verified ? 10 : 0) +
                (d.rating * 8).round(),
            payload: d,
          ),
        );
      }
    }

    if (want(GlobalSearchKind.schools) || want(GlobalSearchKind.courses)) {
      for (final p in catalog.programs) {
        if (verifiedOnly && !p.verified) continue;
        final kind = educationKind(p);
        if (!want(kind)) continue;
        final q = _queryFor(kind, remainder, intents, query);
        if (!_textOrIntent(p.matchesQuery(q), kind, intents, q)) continue;
        hits.add(
          GlobalSearchHit(
            key: 'edu:${p.id}',
            kind: kind,
            title: p.name,
            subtitle: '${p.kindLabel} · ${p.institution} · ${p.city}',
            rank: _rank(p.name, query) + (p.verified ? 8 : 0),
            payload: p,
          ),
        );
      }
    }

    if (want(GlobalSearchKind.benefits)) {
      final q = _queryFor(GlobalSearchKind.benefits, remainder, intents, query);
      for (final s in catalog.schemes) {
        if (!_textOrIntent(
          s.matchesQuery(q),
          GlobalSearchKind.benefits,
          intents,
          q,
        )) {
          continue;
        }
        hits.add(
          GlobalSearchHit(
            key: 'benefit:${s.id}',
            kind: GlobalSearchKind.benefits,
            title: s.name,
            subtitle:
                '${s.categoryLabel} · ${s.agency.isEmpty ? s.country : s.agency}',
            rank: _rank(s.name, query) + 6,
            payload: s,
          ),
        );
      }
      for (final o in catalog.offices) {
        if (!_textOrIntent(
          o.matchesQuery(q),
          GlobalSearchKind.benefits,
          intents,
          q,
        )) {
          continue;
        }
        hits.add(
          GlobalSearchHit(
            key: 'office:${o.id}',
            kind: GlobalSearchKind.benefits,
            title: o.name,
            subtitle: 'Office · ${o.city} · ${o.agency}',
            rank: _rank(o.name, query) + 4,
            payload: o,
          ),
        );
      }
    }

    if (want(GlobalSearchKind.transportation)) {
      final q = _queryFor(
        GlobalSearchKind.transportation,
        remainder,
        intents,
        query,
      );
      for (final o in catalog.transport) {
        if (verifiedOnly && !o.verified) continue;
        if (maxKm != null && o.distanceKm(originLat, originLng) > maxKm) {
          continue;
        }
        if (!_textOrIntent(
          o.matchesQuery(q),
          GlobalSearchKind.transportation,
          intents,
          q,
        )) {
          continue;
        }
        hits.add(
          GlobalSearchHit(
            key: 'transit:${o.id}',
            kind: GlobalSearchKind.transportation,
            title: o.name,
            subtitle:
                '${o.kindLabel} · ${o.distanceLabel(originLat, originLng)}',
            rank:
                _rank(o.name, query) +
                (100 - o.distanceKm(originLat, originLng).clamp(0, 50)).round(),
            payload: o,
          ),
        );
      }
      if (scope == GlobalSearchKind.transportation) {
        final transitPlaces = _places.search(
          catalog.places,
          query: q,
          need: need,
          amenities: amenities,
          openNowOnly: openNowOnly,
          alwaysOpenOnly: alwaysOpenOnly,
          verifiedOnly: verifiedOnly,
          fullyAccessibleOnly: fullyAccessibleOnly,
          maxKm: maxKm,
          originLat: originLat,
          originLng: originLng,
          sort: placeSort,
        );
        for (final p in transitPlaces.where((p) => p.category == 'transit')) {
          hits.add(
            GlobalSearchHit(
              key: 'place:${p.id}',
              kind: GlobalSearchKind.transportation,
              title: p.name,
              subtitle:
                  '${p.categoryLabel} · ${p.distanceLabel(originLat, originLng)}',
              imageUrl: p.imageUrl,
              rank: _rank(p.name, query) + p.score,
              payload: p,
            ),
          );
        }
      }
    }

    if (want(GlobalSearchKind.community)) {
      final q = _queryFor(
        GlobalSearchKind.community,
        remainder,
        intents,
        query,
      );
      final needle = q.trim().toLowerCase();
      bool communityMatch(String haystack) =>
          needle.isEmpty || haystack.toLowerCase().contains(needle);

      for (final p in catalog.posts.where((p) => p.isVisible)) {
        final match =
            communityMatch(p.title) ||
            communityMatch(p.body) ||
            communityMatch(p.city) ||
            communityMatch(p.topic) ||
            communityMatch(p.authorName) ||
            communityMatch(p.typeLabel);
        if (!_textOrIntent(match, GlobalSearchKind.community, intents, q)) {
          continue;
        }
        hits.add(
          GlobalSearchHit(
            key: 'post:${p.id}',
            kind: GlobalSearchKind.community,
            title: p.title,
            subtitle: '${p.typeLabel} · ${p.city} · ${p.topic}',
            rank: _rank(p.title, query) + 2,
            payload: p,
          ),
        );
      }
      for (final g in catalog.groups) {
        final match =
            communityMatch(g.name) ||
            communityMatch(g.summary) ||
            communityMatch(g.city) ||
            communityMatch(g.topic) ||
            communityMatch(g.kindLabel);
        if (!_textOrIntent(match, GlobalSearchKind.community, intents, q)) {
          continue;
        }
        hits.add(
          GlobalSearchHit(
            key: 'group:${g.id}',
            kind: GlobalSearchKind.community,
            title: g.name,
            subtitle: '${g.kindLabel} · ${g.city}',
            rank: _rank(g.name, query) + 3,
            payload: g,
          ),
        );
      }
      for (final e in catalog.events) {
        final match =
            communityMatch(e.title) ||
            communityMatch(e.body) ||
            communityMatch(e.city) ||
            communityMatch(e.venue) ||
            communityMatch(e.topic);
        if (!_textOrIntent(match, GlobalSearchKind.community, intents, q)) {
          continue;
        }
        hits.add(
          GlobalSearchHit(
            key: 'event:${e.id}',
            kind: GlobalSearchKind.community,
            title: e.title,
            subtitle: '${e.whenLabel} · ${e.city} · ${e.venue}',
            rank: _rank(e.title, query) + 3,
            payload: e,
          ),
        );
      }
    }

    hits.sort((a, b) => b.rank.compareTo(a.rank));
    if (query.trim().isEmpty && scope == GlobalSearchKind.all) {
      return _capPerKind(hits, 3);
    }
    if (query.trim().isEmpty) {
      return hits.take(40).toList();
    }
    return hits.take(60).toList();
  }

  String _queryFor(
    GlobalSearchKind kind,
    String remainder,
    Set<GlobalSearchKind> intents,
    String original,
  ) {
    if (intents.contains(kind) && remainder.isEmpty) return '';
    if (intents.contains(kind)) return remainder;
    return original;
  }

  bool _textOrIntent(
    bool textMatch,
    GlobalSearchKind kind,
    Set<GlobalSearchKind> intents,
    String queryForKind,
  ) {
    if (intents.contains(kind) && queryForKind.trim().isEmpty) return true;
    return textMatch;
  }

  bool _providerMatches(
    ServiceProvider p,
    String query,
    GlobalSearchKind kind,
    Set<GlobalSearchKind> intents,
  ) {
    if (_textOrIntent(p.matchesQuery(query), kind, intents, query)) return true;
    return false;
  }

  static GlobalSearchKind? providerKind(ServiceProvider p) {
    if (p.category == 'healthcare') return GlobalSearchKind.doctors;
    if (p.category == 'rehab') return GlobalSearchKind.therapists;
    if (p.category == 'education') return GlobalSearchKind.schools;
    if (p.category == 'caregiving' ||
        p.assistanceType == 'personal_assistant' ||
        p.specialty.toLowerCase().contains('caregiver') ||
        p.services.any((s) => s.toLowerCase().contains('caregiver'))) {
      return GlobalSearchKind.caregivers;
    }
    if (p.isAssistance) return GlobalSearchKind.assistants;
    return null;
  }

  static GlobalSearchKind travelKind(TravelDestination d) {
    return switch (d.kind) {
      'hotel' => GlobalSearchKind.hotels,
      'restaurant' => GlobalSearchKind.restaurants,
      'transport' => GlobalSearchKind.transportation,
      _ => GlobalSearchKind.tourism,
    };
  }

  static GlobalSearchKind educationKind(EducationProgram p) {
    return switch (p.kind) {
      'course' || 'scholarship' => GlobalSearchKind.courses,
      _ => GlobalSearchKind.schools,
    };
  }

  static Set<GlobalSearchKind> intentsOf(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return {};
    final tokens = q
        .split(RegExp(r'[^a-z0-9+]+'))
        .where((t) => t.isNotEmpty)
        .toSet();
    final out = <GlobalSearchKind>{};
    for (final entry in synonyms.entries) {
      for (final syn in entry.value) {
        if (q == syn || tokens.contains(syn)) {
          out.add(entry.key);
          break;
        }
      }
    }
    return out;
  }

  static String remainderAfterIntents(
    String query,
    Set<GlobalSearchKind> intents,
  ) {
    var q = ' ${query.toLowerCase()} ';
    for (final kind in intents) {
      for (final syn in synonyms[kind] ?? const <String>[]) {
        q = q.replaceAll(RegExp('\\b${RegExp.escape(syn)}\\b'), ' ');
      }
    }
    return q.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static int _rank(String title, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 20;
    final t = title.toLowerCase();
    if (t == q) return 120;
    if (t.startsWith(q)) return 90;
    if (t.contains(q)) return 50;
    return 10;
  }

  static List<GlobalSearchHit> _capPerKind(List<GlobalSearchHit> hits, int n) {
    final counts = <GlobalSearchKind, int>{};
    final out = <GlobalSearchHit>[];
    for (final h in hits) {
      final c = counts[h.kind] ?? 0;
      if (c >= n) continue;
      counts[h.kind] = c + 1;
      out.add(h);
    }
    return out;
  }
}
