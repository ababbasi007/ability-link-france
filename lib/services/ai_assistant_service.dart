import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/disability_rights.dart';
import '../models/ai_action.dart';
import '../models/ai_safety.dart';
import '../models/benefit_scheme.dart';
import '../models/care_appointment.dart';
import '../models/chat_message.dart';
import '../models/education_program.dart';
import '../models/place.dart';
import '../models/service_provider.dart';
import '../models/transport_option.dart';
import '../models/travel_destination.dart';
import '../models/user_profile.dart';
import 'ai_recommendations_service.dart';
import 'ai_safety_service.dart';
import 'benefits_service.dart';
import 'education_service.dart';
import 'healthcare_service.dart';
import 'location_service.dart';
import 'places_service.dart';
import 'providers_service.dart';
import 'transport_service.dart';
import 'travel_service.dart';
import 'trust_service.dart';

enum AiIntent {
  places,
  routes,
  doctors,
  rehab,
  caregivers,
  tourism,
  education,
  benefits,
  rights,
  accessibilityExplain,
  personalized,
  travelAssist,
  appointments,
  emergency,
  general,
}

class AiReply {
  const AiReply({
    required this.text,
    required this.usedLiveModel,
    this.error,
    this.safety = const SafetyScan(),
    this.actions = const [],
  });

  final String text;
  final bool usedLiveModel;
  final String? error;
  final SafetyScan safety;
  final List<AiAction> actions;
}

class _DomainPack {
  const _DomainPack({
    required this.places,
    required this.providers,
    required this.travel,
    required this.education,
    required this.benefits,
    required this.transport,
    required this.appointments,
    required this.contextBlock,
    required this.actions,
    required this.localText,
  });

  final List<AccessiblePlace> places;
  final List<ServiceProvider> providers;
  final List<TravelDestination> travel;
  final List<EducationProgram> education;
  final List<BenefitScheme> benefits;
  final List<TransportOption> transport;
  final List<CareAppointment> appointments;
  final String contextBlock;
  final List<AiAction> actions;
  final String localText;
}

/// Live Gemini assistant with Passport + live catalog tools and action CTAs.
class AiAssistantService {
  AiAssistantService({
    PlacesService? places,
    LocationService? location,
    ProvidersService? providers,
    TravelService? travel,
    EducationService? education,
    BenefitsService? benefits,
    TransportService? transport,
    HealthcareService? healthcare,
    FirebaseFirestore? db,
  }) : _places = places ?? PlacesService(),
       _location = location ?? LocationService.instance,
       _providers = providers ?? ProvidersService(),
       _travel = travel ?? TravelService(),
       _education = education ?? EducationService(),
       _benefits = benefits ?? BenefitsService(),
       _transport = transport ?? TransportService(),
       _healthcare = healthcare ?? HealthcareService(),
       _db = db ?? FirebaseFirestore.instance;

  final PlacesService _places;
  final LocationService _location;
  final ProvidersService _providers;
  final TravelService _travel;
  final EducationService _education;
  final BenefitsService _benefits;
  final TransportService _transport;
  final HealthcareService _healthcare;
  final FirebaseFirestore _db;
  final _safety = AiSafetyService();
  final _trust = TrustService();

  ChatSession? _session;
  bool _geminiReady = false;
  bool _geminiFailed = false;
  String? lastBackendNote;

  AiIntent detectIntent(String message) {
    final q = message.toLowerCase();
    if (_any(q, [
      'emergency',
      'sos',
      'crisis',
      'danger',
      'help now',
      'ambulance',
    ])) {
      return AiIntent.emergency;
    }
    if (_any(q, [
      'right',
      'rights',
      'discrimination',
      'crpd',
      'law',
      'legal',
    ])) {
      return AiIntent.rights;
    }
    if (_any(q, [
      'benefit',
      'aah',
      'pch',
      'rqth',
      'government',
      'allowance',
      'eligible',
      'mdph',
      'caf',
    ])) {
      return AiIntent.benefits;
    }
    if (_any(q, [
      'appointment',
      'reschedule',
      'book visit',
      'my visit',
      'upcoming visit',
      'consult slot',
    ])) {
      return AiIntent.appointments;
    }
    if (_any(q, [
      'route',
      'step-free',
      'step free',
      'directions',
      'how do i get',
      'navigate to',
      'walking path',
    ])) {
      return AiIntent.routes;
    }
    if (_any(q, [
      'caregiver',
      'carer',
      'personal assistant',
      'home help',
      'find assistance',
    ])) {
      return AiIntent.caregivers;
    }
    if (_any(q, [
      'rehab',
      'physiotherap',
      'occupational therap',
      'speech therap',
      'exercise for',
    ])) {
      return AiIntent.rehab;
    }
    if (_any(q, [
      'doctor',
      'telehealth',
      'clinic',
      'hospital',
      'physician',
      'neurolog',
      'cardiolog',
      'psychiatr',
    ])) {
      return AiIntent.doctors;
    }
    if (_any(q, [
      'school',
      'course',
      'scholarship',
      'education',
      'university',
      'learn',
      'study',
    ])) {
      return AiIntent.education;
    }
    if (_any(q, [
      'hotel',
      'tourism',
      'attraction',
      'restaurant trip',
      'vacation',
      'holiday',
      'destination',
    ])) {
      return AiIntent.tourism;
    }
    if (_any(q, [
      'travel',
      'trip',
      'itinerary',
      'airport',
      'metro',
      'transit',
      'bus',
      'train',
    ])) {
      return AiIntent.travelAssist;
    }
    if (_any(q, [
      'recommend',
      'for me',
      'personalized',
      'based on my',
      'my needs',
      'passport',
      'profile',
    ])) {
      return AiIntent.personalized;
    }
    if (_any(q, [
      'explain',
      'what does',
      'accessibility score',
      'is this place',
      'wheelchair accessible',
      'features mean',
    ])) {
      return AiIntent.accessibilityExplain;
    }
    if (_any(q, [
      'place',
      'nearby',
      'near me',
      'cafe',
      'restaurant',
      'washroom',
      'toilet',
      'library',
      'map',
    ])) {
      return AiIntent.places;
    }
    return AiIntent.general;
  }

  bool _any(String q, List<String> keys) => keys.any(q.contains);

  Future<void> _ensureSession(UserProfile? profile) async {
    if (_geminiReady && _session != null) return;
    if (_geminiFailed) return;

    try {
      final system = Content.system(_systemPrompt(profile));
      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: system,
        generationConfig: GenerationConfig(
          temperature: 0.5,
          maxOutputTokens: 1100,
        ),
      );
      _session = model.startChat();
      _geminiReady = true;
      lastBackendNote = 'Gemini (Firebase AI)';
    } catch (_) {
      _geminiFailed = true;
      _session = null;
      lastBackendNote = 'Local assistant (Gemini unavailable)';
    }
  }

  String _systemPrompt(UserProfile? profile) {
    final lang = profile?.preferredLanguage ?? 'English';
    final name = profile?.firstName ?? 'friend';
    final passport = profile == null
        ? 'No passport loaded yet.'
        : '''
Name: ${profile.displayName}
Role: ${profile.role ?? 'member'}
Passport ID: ${profile.passportId}
Location preference: ${profile.city}
Language: ${profile.preferredLanguage}
Accessibility profiles: ${profile.accessibilityProfiles.join(', ')}
Mobility aid: ${profile.mobilityAid}
Needs caregiver: ${profile.needCaregiver}
Assistance: ${profile.assistanceNeeds.join(', ')}
Communication: ${profile.communicationSummary}
Sign language: ${profile.signLanguage}
Interpreter: ${profile.needsInterpreter}
Preferred contact: ${profile.preferredContactMethod}
Blood group: ${profile.bloodGroup}
Emergency contact: ${(profile.emergency['name'] as String?) ?? 'n/a'} (${(profile.emergency['phone'] as String?) ?? 'n/a'})
Preferences: largeText=${profile.preferences['largeText']}, captions=${profile.preferences['captions']}, screenReader=${profile.preferences['screenReader']}
''';

    return '''
You are Ability Link's AI Accessibility Assistant.
Help with accessible places, step-free routes, doctors, rehab, caregivers, tourism, education, government benefits, disability rights, appointments, and emergencies.

Speak warmly to $name. Prefer short practical answers with bullets.
Respond in $lang unless asked otherwise.
Always respect the Accessibility Passport.
Only recommend catalog items listed in the domain context. Cite their exact names.
Never invent medical diagnoses. For emergencies, urge SOS / local emergency numbers.
Do not use ableist language.

ACCESSIBILITY PASSPORT:
$passport
''';
  }

  Future<_DomainPack> _buildDomain(
    String message,
    AiIntent intent,
    UserProfile? profile,
  ) async {
    await Future.wait([
      _places.ensureSeeded().catchError((_) => 0),
      _providers.ensureSeeded().catchError((_) => 0),
      _travel.ensureSeeded().catchError((_) => 0),
      _education.ensureSeeded().catchError((_) => 0),
      _benefits.ensureSeeded().catchError((_) => 0),
      _transport.ensureSeeded().catchError((_) => 0),
    ]);

    final origin = _location.current;
    final name = profile?.firstName ?? 'there';
    final needs = profile?.accessibilityProfiles ?? const <String>[];
    final aid = profile?.mobilityAid ?? '';

    final placesAll = await _places.watchPlaces().first.catchError(
      (_) => const <AccessiblePlace>[],
    );
    final places = _places.search(
      placesAll,
      sort: PlaceSort.distance,
      originLat: origin.lat,
      originLng: origin.lng,
      need:
          needs.any((n) => n.toLowerCase().contains('mobility')) ||
              aid.toLowerCase().contains('wheelchair')
          ? 'wheelchair'
          : 'all',
    );

    final providersAll = await _providers.watchProviders().first.catchError(
      (_) => const <ServiceProvider>[],
    );
    final travelAll = await _travel.watchDestinations().first.catchError(
      (_) => const <TravelDestination>[],
    );
    final educationAll = await _education.watchPrograms().first.catchError(
      (_) => const <EducationProgram>[],
    );
    final benefitsAll = await _benefits.watchSchemes().first.catchError(
      (_) => seedBenefits,
    );
    final transportAll = await _transport.watchOptions().first.catchError(
      (_) => const <TransportOption>[],
    );
    final appointments = await _healthcare.watchAppointments().first.catchError(
      (_) => const <CareAppointment>[],
    );

    final doctors = _providers.filter(
      providersAll,
      category: 'Healthcare',
      query: message,
    );
    final rehab = _providers.filter(
      providersAll,
      category: 'Rehabilitation',
      query: message,
    );
    final caregivers = _providers.filter(
      providersAll,
      category: 'Assistance',
      query: message,
    );
    final travel = _travel.filter(travelAll, query: message, profile: profile);
    final education = _education.filter(
      educationAll,
      query: message,
      profile: profile,
    );
    final benefits = _benefits.filter(
      benefitsAll,
      query: message,
      profile: profile,
    );
    final transport = _transport.filter(
      transportAll,
      query: message,
      stepFreeOnly: true,
      originLat: origin.lat,
      originLng: origin.lng,
    );
    final upcoming = appointments.where((a) => a.isUpcoming).toList();

    String placeLine(AccessiblePlace p) =>
        '• ${p.name} (${p.categoryLabel}) — ${p.distanceLabel(origin.lat, origin.lng)}, '
        'score ${p.score}, ${p.features.take(3).join(', ')}'
        '${p.verified ? ', verified' : ''}';

    String providerLine(ServiceProvider p) =>
        '• ${p.name} · ${p.specialty} (${p.categoryLabel}) · ${p.city}'
        '${p.availableNow ? ' · available now' : ''}'
        '${p.verified ? ' · verified' : ''} · ${p.priceLabel}';

    final buf = StringBuffer();
    final actions = <AiAction>[];
    late final String localText;

    switch (intent) {
      case AiIntent.places:
        final list = places.take(5).toList();
        buf.writeln('Places:\n${list.map(placeLine).join('\n')}');
        actions.addAll([
          const AiAction(
            id: 'map',
            label: 'Open Ability Map',
            type: AiActionType.map,
          ),
          const AiAction(
            id: 'search',
            label: 'Search places',
            type: AiActionType.search,
          ),
        ]);
        localText =
            'Nearby accessible places for $name${aid.isEmpty ? '' : ' (aid: $aid)'}:\n\n'
            '${list.map(placeLine).join('\n')}\n\n'
            'Open the map for filters, reviews, and routes.';

      case AiIntent.routes:
        final routePack = await AiRecommendationsService(
          places: _places,
          providers: _providers,
          location: _location,
        ).planAccessibleRoute(query: message, profile: profile);
        buf.writeln(routePack.formattedText);
        if (routePack.routes.isNotEmpty) {
          final r = routePack.routes.first;
          actions.add(
            AiAction(
              id: 'ai-route-${r.id}',
              label: r.title,
              type: AiActionType.map,
              payload: {
                'placeId': r.id,
                if (r.lat != null) 'lat': '${r.lat}',
                if (r.lng != null) 'lng': '${r.lng}',
              },
            ),
          );
        }
        actions.add(
          const AiAction(
            id: 'transport',
            label: 'Transport hub',
            type: AiActionType.transport,
          ),
        );
        localText = routePack.formattedText;

      case AiIntent.doctors:
        final list =
            (doctors.isEmpty
                    ? _providers.filter(providersAll, category: 'Healthcare')
                    : doctors)
                .take(5)
                .toList();
        buf.writeln('Doctors:\n${list.map(providerLine).join('\n')}');
        actions.addAll([
          const AiAction(
            id: 'docs',
            label: 'Find doctors',
            type: AiActionType.providers,
            payload: {'category': 'Healthcare'},
          ),
          const AiAction(
            id: 'tele',
            label: 'Open Telehealth',
            type: AiActionType.telehealth,
          ),
          if (list.isNotEmpty)
            AiAction(
              id: 'book-${list.first.id}',
              label: 'Book ${list.first.name}',
              type: AiActionType.bookProvider,
              payload: {'providerId': list.first.id},
            ),
        ]);
        localText =
            'Doctors matched for $name:\n\n${list.map(providerLine).join('\n')}\n\n'
            'Book a video/audio/chat visit or open Telehealth for Instant Consult.';

      case AiIntent.rehab:
        final list =
            (rehab.isEmpty
                    ? _providers.filter(
                        providersAll,
                        category: 'Rehabilitation',
                      )
                    : rehab)
                .take(5)
                .toList();
        buf.writeln('Rehab providers:\n${list.map(providerLine).join('\n')}');
        actions.addAll([
          const AiAction(
            id: 'rehab-dir',
            label: 'Rehab providers',
            type: AiActionType.providers,
            payload: {'category': 'Rehabilitation'},
          ),
          const AiAction(
            id: 'rehab-hub',
            label: 'Tele-Rehabilitation',
            type: AiActionType.rehab,
          ),
          if (list.isNotEmpty)
            AiAction(
              id: 'book-${list.first.id}',
              label: 'Book ${list.first.name}',
              type: AiActionType.bookProvider,
              payload: {'providerId': list.first.id},
            ),
        ]);
        localText =
            'Rehabilitation providers for $name:\n\n${list.map(providerLine).join('\n')}\n\n'
            'Open Tele-Rehab for exercises and live sessions.';

      case AiIntent.caregivers:
        final list =
            (caregivers.isEmpty
                    ? _providers.filter(providersAll, category: 'Assistance')
                    : caregivers)
                .take(5)
                .toList();
        buf.writeln('Caregivers:\n${list.map(providerLine).join('\n')}');
        actions.addAll([
          const AiAction(
            id: 'care-dir',
            label: 'Find caregivers',
            type: AiActionType.providers,
            payload: {'category': 'Assistance'},
          ),
          const AiAction(
            id: 'care-hub',
            label: 'Caregiver Hub',
            type: AiActionType.caregiverHub,
          ),
        ]);
        localText =
            'Caregivers / assistance matches:\n\n${list.map(providerLine).join('\n')}\n\n'
            'Use Find caregivers to enquire, or Caregiver Hub for your care circle.';

      case AiIntent.tourism:
        final list = travel.take(5).toList();
        buf.writeln(
          'Tourism:\n${list.map((d) => '• ${d.name} (${d.kind}) · score ${_travel.matchScore(d, profile)}').join('\n')}',
        );
        actions.add(
          const AiAction(
            id: 'travel',
            label: 'Accessible Tourism',
            type: AiActionType.travel,
          ),
        );
        localText = list.isEmpty
            ? 'No tourism matches yet. Open Accessible Tourism to browse hotels and attractions.'
            : 'Accessible tourism picks for $name:\n\n'
                  '${list.map((d) => '• ${d.name} — ${d.kind}').join('\n')}\n\n'
                  'Open Tourism to plan an itinerary.';

      case AiIntent.education:
        final list = education.take(5).toList();
        buf.writeln(
          'Education:\n${list.map((p) => '• ${p.name} (${p.kind}) · match ${_education.matchScore(p, profile)}').join('\n')}',
        );
        actions.add(
          const AiAction(
            id: 'edu',
            label: 'Education opportunities',
            type: AiActionType.education,
          ),
        );
        localText = list.isEmpty
            ? 'No programs matched. Open Accessible Education to browse schools and courses.'
            : 'Education opportunities for $name:\n\n'
                  '${list.map((p) => '• ${p.name} — ${p.kind}').join('\n')}\n\n'
                  'Open Education to save interest.';

      case AiIntent.benefits:
        final list = benefits.take(5).toList();
        buf.writeln(
          'Benefits:\n${list.map((b) => '• ${b.name} (${b.country}) — ${b.summary}').join('\n')}',
        );
        actions.add(
          const AiAction(
            id: 'ben',
            label: 'Government Benefits',
            type: AiActionType.benefits,
          ),
        );
        localText = list.isEmpty
            ? 'I could not match a scheme. Open Government Benefits for the full checklist.'
            : 'Benefits relevant to your Passport (${profile?.city ?? 'your area'}):\n\n'
                  '${list.map((b) => '• ${b.name}\n  ${b.summary}\n  Next: ${b.steps.first}').join('\n\n')}\n\n'
                  'Confirm on the official agency site before applying.';

      case AiIntent.rights:
        final topic = matchRightsTopic(message) ?? disabilityRightsTopics.first;
        buf.writeln('Rights topic: ${topic.title}\n${topic.summary}');
        for (final p in topic.points) {
          buf.writeln('- $p');
        }
        actions.add(
          AiAction(
            id: 'rights',
            label: 'Rights: ${topic.title}',
            type: AiActionType.rights,
            payload: {'topicId': topic.id},
          ),
        );
        localText =
            '${topic.title}\n\n${topic.summary}\n\n${topic.points.map((p) => '• $p').join('\n')}\n\n'
            'This is general guidance, not legal advice.';

      case AiIntent.accessibilityExplain:
        final p = places.isNotEmpty ? places.first : null;
        buf.writeln(p == null ? 'No place' : 'Explain place ${p.name}');
        actions.addAll([
          const AiAction(
            id: 'map2',
            label: 'Ability Map',
            type: AiActionType.map,
          ),
          const AiAction(
            id: 'search2',
            label: 'Search places',
            type: AiActionType.search,
          ),
        ]);
        localText = p == null
            ? 'Ask about a venue, or open Ability Map and pick a place to audit.'
            : 'Accessibility snapshot for ${p.name}:\n'
                  '• Category: ${p.categoryLabel}\n'
                  '• Score: ${p.score} · Rating: ${p.rating}\n'
                  '• Features: ${p.features.isEmpty ? 'not listed' : p.features.join(', ')}\n'
                  '• Supported needs: ${p.needs.isEmpty ? 'general' : p.needs.join(', ')}\n'
                  '• Verified: ${p.verified ? 'yes' : 'not yet'}\n\n'
                  'Open the place on the map for reviews and full audits.';

      case AiIntent.personalized:
        final pack = await AiRecommendationsService(
          places: _places,
          providers: _providers,
          location: _location,
        ).recommend(profile: profile, planRoutes: true);
        buf.writeln(pack.formattedText);
        actions.addAll([
          const AiAction(
            id: 'p-map',
            label: 'Places for you',
            type: AiActionType.map,
          ),
          const AiAction(
            id: 'p-docs',
            label: 'Doctors for you',
            type: AiActionType.providers,
            payload: {'category': 'Healthcare'},
          ),
          const AiAction(
            id: 'p-travel',
            label: 'Travel for you',
            type: AiActionType.travel,
          ),
          const AiAction(
            id: 'p-ben',
            label: 'Benefits for you',
            type: AiActionType.benefits,
          ),
          if (pack.routes.isNotEmpty)
            AiAction(
              id: 'p-route',
              label: pack.routes.first.title,
              type: AiActionType.map,
              payload: {
                if (pack.routes.first.lat != null)
                  'lat': '${pack.routes.first.lat}',
                if (pack.routes.first.lng != null)
                  'lng': '${pack.routes.first.lng}',
                'placeId': pack.routes.first.id,
              },
            ),
        ]);
        localText = pack.formattedText;

      case AiIntent.travelAssist:
        final list = travel.take(3).toList();
        final stops = transport.take(3).toList();
        buf.writeln('Travel assist pack.');
        actions.addAll([
          const AiAction(
            id: 't-hub',
            label: 'Tourism planner',
            type: AiActionType.travel,
          ),
          const AiAction(
            id: 't-trans',
            label: 'Transport & step-free',
            type: AiActionType.transport,
          ),
          if (stops.isNotEmpty)
            AiAction(
              id: 't-route',
              label: 'Route to ${stops.first.name}',
              type: AiActionType.stepFreeRoute,
              payload: {
                'id': stops.first.id,
                'name': stops.first.name,
                'lat': '${stops.first.lat}',
                'lng': '${stops.first.lng}',
                'kind': stops.first.kind,
                'summary': stops.first.summary,
                'stepFree': '1',
              },
            ),
        ]);
        localText =
            'Travel assistance for $name:\n\n'
            'Destinations\n${list.map((d) => '• ${d.name} (${d.kind})').join('\n')}\n\n'
            'Step-free stops\n${stops.map((t) => '• ${t.name}').join('\n')}\n\n'
            'Plan a trip in Tourism or get a walking path in Transport.';

      case AiIntent.appointments:
        buf.writeln(
          'Upcoming:\n${upcoming.take(4).map((a) => '• ${a.providerName} · ${a.whenLabel} · ${a.modeLabel}').join('\n')}',
        );
        actions.addAll([
          const AiAction(
            id: 'appts',
            label: 'My appointments',
            type: AiActionType.appointments,
          ),
          const AiAction(
            id: 'tele2',
            label: 'Book telehealth',
            type: AiActionType.telehealth,
          ),
        ]);
        localText = upcoming.isEmpty
            ? 'You have no upcoming visits. Open Telehealth to book video, audio, or chat.'
            : 'Your upcoming appointments:\n\n'
                  '${upcoming.take(5).map((a) => '• ${a.providerName} — ${a.whenLabel} (${a.modeLabel})').join('\n')}\n\n'
                  'Open Appointments to join, reschedule, or cancel.';

      case AiIntent.emergency:
        buf.writeln('Emergency guidance requested.');
        actions.add(
          const AiAction(
            id: 'sos',
            label: 'Open Emergency SOS',
            type: AiActionType.emergency,
          ),
        );
        final contact = profile?.emergency;
        final cName = (contact?['name'] as String?) ?? '';
        final cPhone = (contact?['phone'] as String?) ?? '';
        localText =
            'If you are in immediate danger, tap Call Emergency on Home (one-tap dial of your local number: 112 in France, 911 in the US).\n\n'
            'Ability Link SOS:\n'
            '1. SOS saves GPS, medical, and accessibility details.\n'
            '2. Contacts get an SMS compose + in-app alert if they are linked.\n'
            '3. Share Location sends a 2-hour maps pin by SMS.\n'
            '4. Nearby hospitals and 15/17/18/114 are sorted by GPS.\n\n'
            '${cName.isEmpty ? 'Add an emergency contact in your Passport.' : 'Passport contact: $cName${cPhone.isEmpty ? '' : ' · $cPhone'}.'}';

      case AiIntent.general:
        buf.writeln(
          'General help. Top places:\n${places.take(3).map(placeLine).join('\n')}',
        );
        actions.addAll([
          const AiAction(
            id: 'g-map',
            label: 'Find places',
            type: AiActionType.map,
          ),
          const AiAction(
            id: 'g-docs',
            label: 'Find doctors',
            type: AiActionType.providers,
            payload: {'category': 'Healthcare'},
          ),
          const AiAction(
            id: 'g-ben',
            label: 'Benefits',
            type: AiActionType.benefits,
          ),
        ]);
        localText =
            'Hi $name — I can find places, routes, doctors, rehab, caregivers, '
            'tourism, education, benefits, explain rights, help with appointments, '
            'and guide emergencies.\n\n'
            'Nearby highlights:\n${places.take(3).map(placeLine).join('\n')}\n\n'
            'Try: “Find doctors”, “Step-free route”, or “What benefits am I eligible for?”';
    }

    return _DomainPack(
      places: places,
      providers: providersAll,
      travel: travelAll,
      education: educationAll,
      benefits: benefitsAll,
      transport: transportAll,
      appointments: appointments,
      contextBlock: buf.toString(),
      actions: actions,
      localText: localText,
    );
  }

  Future<AiReply> send({
    required String userMessage,
    required List<ChatMessage> history,
    UserProfile? profile,
  }) async {
    final trimmed = userMessage.trim();
    if (trimmed.isEmpty) {
      return const AiReply(
        text: 'Ask me anything about accessibility.',
        usedLiveModel: false,
      );
    }

    final intent = detectIntent(trimmed);
    final pack = await _buildDomain(trimmed, intent, profile);
    await _ensureSession(profile);

    if (_session != null && _geminiReady) {
      try {
        final recent = history.length > 6
            ? history.sublist(history.length - 6)
            : history;
        final prompt = StringBuffer()
          ..writeln(trimmed)
          ..writeln()
          ..writeln('Detected intent: $intent')
          ..writeln('--- recent chat ---');
        for (final m in recent) {
          prompt.writeln('${m.role.name}: ${m.text}');
        }
        prompt
          ..writeln('--- domain catalog (use only these names) ---')
          ..writeln(pack.contextBlock)
          ..writeln(
            'User GPS: ${_location.current.fromDevice ? 'available' : 'fallback'} '
            '(${_location.current.lat.toStringAsFixed(4)}, ${_location.current.lng.toStringAsFixed(4)})',
          )
          ..writeln(
            'Draft answer the user can act on. Mention 2–4 catalog items by exact name.',
          );

        final response = await _session!.sendMessage(
          Content.text(prompt.toString()),
        );
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          await _persistTurn(userMessage: trimmed, assistantText: text);
          return _finish(text, true, pack, trimmed);
        }
      } catch (e) {
        _geminiFailed = true;
        _geminiReady = false;
        _session = null;
        lastBackendNote = 'Local assistant (Gemini error)';
        await _persistTurn(userMessage: trimmed, assistantText: pack.localText);
        return _finish(
          pack.localText,
          false,
          pack,
          trimmed,
          error: e.toString(),
        );
      }
    }

    await _persistTurn(userMessage: trimmed, assistantText: pack.localText);
    return _finish(pack.localText, false, pack, trimmed);
  }

  Future<AiReply> _finish(
    String text,
    bool live,
    _DomainPack pack,
    String prompt, {
    String? error,
  }) async {
    final scan = _safety.scan(reply: text, places: pack.places);
    if (scan.needsOversight) {
      await _trust.queueOversight(prompt: prompt, reply: text, scan: scan);
    }
    return AiReply(
      text: text,
      usedLiveModel: live,
      error: error,
      safety: scan,
      actions: pack.actions,
    );
  }

  Future<void> _persistTurn({
    required String userMessage,
    required String assistantText,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final conv = _db
          .collection('users')
          .doc(uid)
          .collection('aiConversations')
          .doc('current');
      await conv.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'title': userMessage.length > 40
            ? '${userMessage.substring(0, 40)}…'
            : userMessage,
      }, SetOptions(merge: true));
      final messages = conv.collection('messages');
      final now = DateTime.now();
      await messages.add({
        'role': 'user',
        'text': userMessage,
        'createdAt': now.toIso8601String(),
      });
      await messages.add({
        'role': 'assistant',
        'text': assistantText,
        'createdAt': now.add(const Duration(seconds: 1)).toIso8601String(),
      });
    } catch (_) {}
  }

  Future<List<ChatMessage>> loadRecent({int limit = 40}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const [];
    try {
      final snap = await _db
          .collection('users')
          .doc(uid)
          .collection('aiConversations')
          .doc('current')
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      final messages = snap.docs.reversed.map((d) {
        final data = d.data();
        return ChatMessage(
          id: d.id,
          role: data['role'] == 'user' ? ChatRole.user : ChatRole.assistant,
          text: (data['text'] as String?) ?? '',
          createdAt:
              DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
      return messages;
    } catch (_) {
      return const [];
    }
  }

  Future<void> clearCurrentConversation() async {
    _session = null;
    _geminiReady = false;
    _geminiFailed = false;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final messages = await _db
          .collection('users')
          .doc(uid)
          .collection('aiConversations')
          .doc('current')
          .collection('messages')
          .get();
      for (final d in messages.docs) {
        await d.reference.delete();
      }
    } catch (_) {}
  }

  void resetModel() {
    _session = null;
    _geminiReady = false;
    _geminiFailed = false;
  }
}
