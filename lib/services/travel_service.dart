import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/travel_destination.dart';
import '../models/user_profile.dart';
import 'billing_service.dart';
import 'notification_service.dart';

class PlannedTrip {
  const PlannedTrip({
    required this.title,
    required this.days,
    required this.stops,
    required this.notes,
  });

  final String title;
  final int days;
  final List<TravelDestination> stops;
  final String notes;
}

class TravelService {
  TravelService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    BillingService? billing,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _billing = billing ?? BillingService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final BillingService _billing;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _destinations =>
      _db.collection('travelDestinations');
  CollectionReference<Map<String, dynamic>> get _itineraries =>
      _db.collection('travelItineraries');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('travelBookings');

  CollectionReference<Map<String, dynamic>> get _saved {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    return _db.collection('users').doc(id).collection('savedTravel');
  }

  Stream<List<TravelDestination>> watchDestinations({int limit = 250}) {
    return _destinations
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(TravelDestination.fromDoc).toList());
  }

  Future<TravelDestination?> getDestination(String id) async {
    final doc = await _destinations.doc(id).get();
    if (!doc.exists) return null;
    return TravelDestination.fromDoc(doc);
  }

  Stream<List<TravelItinerary>> watchMyItineraries() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _itineraries.where('uid', isEqualTo: id).snapshots().map((snap) {
      final list = snap.docs
          .map(TravelItinerary.fromDoc)
          .where((i) => !i.archived)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<Set<String>> watchSavedIds() {
    if (uid == null) return Stream.value(const {});
    return _saved.snapshots().map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  Stream<List<TravelDestination>> watchSavedDestinations(
    List<TravelDestination> catalog,
  ) {
    return watchSavedIds().map((ids) {
      return catalog.where((d) => ids.contains(d.id)).toList();
    });
  }

  Future<void> toggleSaved(TravelDestination dest) async {
    final ref = _saved.doc(dest.id);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'destinationId': dest.id,
        'name': dest.name,
        'kind': dest.kind,
        'city': dest.city,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<TravelBooking>> watchMyBookings() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _bookings.where('uid', isEqualTo: id).snapshots().map((snap) {
      final list = snap.docs.map(TravelBooking.fromDoc).toList();
      list.sort((a, b) => b.startAt.compareTo(a.startAt));
      return list;
    });
  }

  Future<int> ensureSeeded() async {
    var n = 0;
    for (final d in seedTravel) {
      final ref = _destinations.doc(d.id);
      final snap = await ref.get();
      if (!snap.exists) {
        await ref.set({
          ...d.toMap(),
          'seeded': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        n++;
      }
    }
    return n;
  }

  int matchScore(TravelDestination dest, UserProfile? profile) {
    var score = 28;
    if (dest.verified) score += 10;
    if (dest.wheelchairAccessible) score += 6;
    if (dest.rating > 0) score += (dest.rating * 4).round().clamp(0, 16);
    final profiles =
        profile?.accessibilityProfiles.map((e) => e.toLowerCase()).toList() ??
        const <String>[];
    for (final tag in dest.inclusiveFor) {
      final t = tag.toLowerCase();
      if (profiles.any((p) => p.contains(t) || t.contains(p))) score += 12;
    }
    final aid = (profile?.mobilityAid ?? '').toLowerCase();
    if (aid.contains('wheelchair') && dest.wheelchairAccessible) score += 10;
    for (final f in dest.accessFeatures) {
      final x = f.toLowerCase();
      if (aid.contains('wheelchair') &&
          (x.contains('wheelchair') ||
              x.contains('roll-in') ||
              x.contains('step-free'))) {
        score += 6;
      }
      if (x.contains('caption') || x.contains('quiet') || x.contains('menu')) {
        score += 3;
      }
    }
    return score.clamp(0, 99);
  }

  List<TravelDestination> filter(
    List<TravelDestination> all, {
    String query = '',
    String kind = 'All',
    bool verifiedOnly = false,
    bool wheelchairOnly = false,
    UserProfile? profile,
  }) {
    var list = all.where((d) {
      if (!d.matchesQuery(query)) return false;
      if (kind != 'All' && d.kind != kind) return false;
      if (verifiedOnly && !d.verified) return false;
      if (wheelchairOnly && !d.wheelchairAccessible) return false;
      return true;
    }).toList();
    list.sort(
      (a, b) => matchScore(b, profile).compareTo(matchScore(a, profile)),
    );
    return list;
  }

  PlannedTrip planTrip({
    required List<TravelDestination> catalog,
    required UserProfile? profile,
    int days = 2,
    TravelDestination? mustInclude,
  }) {
    final ranked = filter(catalog, profile: profile);
    TravelDestination? pick(String kind) {
      for (final d in ranked) {
        if (d.kind == kind) return d;
      }
      return null;
    }

    final hotel = pick('hotel');
    final food = pick('restaurant');
    final tour = pick('tour');
    final transport = pick('transport');
    final attractions = ranked
        .where((d) => d.kind == 'attraction')
        .take(days + 1)
        .toList();
    final stops = <TravelDestination>[
      ?hotel,
      ?transport,
      ...attractions,
      ?tour,
      ?food,
    ];
    if (mustInclude != null && !stops.any((s) => s.id == mustInclude.id)) {
      stops.insert(1, mustInclude);
    }

    final profiles = profile?.accessibilityProfiles ?? const <String>[];
    final notes = StringBuffer()
      ..writeln(
        'AI trip sketch for ${profile?.firstName ?? 'you'} · $days day(s).',
      )
      ..writeln(
        profiles.isEmpty
            ? 'No Passport profiles on file — preferred verified, wheelchair-friendly stops.'
            : 'Tuned for: ${profiles.join(', ')}'
                  '${profile?.mobilityAid.isNotEmpty == true ? ' · ${profile!.mobilityAid}' : ''}.',
      )
      ..writeln(
        'Pace: one main stop per half-day, rest breaks, step-free transfers where listed.',
      )
      ..writeln(
        'Book hotels/tours from destination pages. Hire a Travel Assistant for airport/transit escort.',
      );

    return PlannedTrip(
      title: '$days-day accessible NYC stay',
      days: days,
      stops: stops,
      notes: notes.toString().trim(),
    );
  }

  Future<String> saveItinerary(PlannedTrip trip) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to save an itinerary');
    final ref = _itineraries.doc();
    await ref.set({
      'uid': user.uid,
      'title': trip.title,
      'days': trip.days,
      'stopIds': trip.stops.map((s) => s.id).toList(),
      'stopNames': trip.stops.map((s) => s.name).toList(),
      'notes': trip.notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> archiveItinerary(String id) async {
    await _itineraries.doc(id).update({
      'archived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> bookService({
    required TravelDestination destination,
    required DateTime startAt,
    required String service,
    String notes = '',
    int guests = 1,
    bool payNow = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to book');
    if (!destination.bookable) {
      throw StateError('This listing is not bookable yet — enquire via AI');
    }
    final priceCents =
        (destination.priceFrom > 0 ? destination.priceFrom : 50) * 100 * guests;
    final ref = _bookings.doc();
    var paymentStatus = 'unpaid';
    var invoiceId = '';
    if (payNow) {
      invoiceId = await _billing.payAssistanceBooking(
        bookingId: ref.id,
        providerName: destination.name,
        amountCents: priceCents,
        currency: destination.currency,
      );
      paymentStatus = 'paid';
    }
    await ref.set({
      'uid': user.uid,
      'destinationId': destination.id,
      'destinationName': destination.name,
      'kind': destination.kind,
      'service': service,
      'startAt': Timestamp.fromDate(startAt),
      'status': 'booked',
      'priceCents': priceCents,
      'currency': destination.currency,
      'paymentStatus': paymentStatus,
      'invoiceId': invoiceId,
      'notes': notes.trim(),
      'guests': guests,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService(db: _db, auth: _auth).notifyBooking(
      patientUid: user.uid,
      providerName: destination.name,
      appointmentId: ref.id,
      kind: 'travel',
    );
    return ref.id;
  }

  Future<void> cancelBooking(String id) async {
    await _bookings.doc(id).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

final seedTravel = <TravelDestination>[
  TravelDestination(
    id: 'tv-harbor-inn',
    name: 'Harbor Access Inn',
    kind: 'hotel',
    city: 'New York, NY',
    area: 'Midtown',
    priceLabel: '\$\$',
    verified: true,
    inclusiveFor: ['Mobility', 'Hearing', 'Visual'],
    accessFeatures: [
      'Roll-in shower',
      'Step-free lobby',
      'Visual fire alarms',
      'Captions on TV',
      'Service animal welcome',
      'Wheelchair seating',
    ],
    summary:
        'Midtown hotel with roll-in rooms and a step-free lobby from the street.',
    description:
        'Accessible rooms on floors 2–4 with roll-in showers, lowered switches, and adjoining caregiver rooms on request. Staff trained for quiet check-in.',
    imageUrl:
        'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&h=500&fit=crop',
    wheelchairAccessible: true,
    accessibleRooms: [
      'Roll-in shower king (201–208)',
      'Transfer shower queen (301–304)',
      'Connecting caregiver room on request',
    ],
    accessibleBathrooms: [
      'Roll-in shower with seat',
      'Grab bars both sides',
      'Lowered sink & mirror',
    ],
    routeNotes:
        'Step-free from 7th Ave curb cut → automatic lobby doors → elevator bank. Avoid revolving door on Broadway side.',
    lat: 40.758,
    lng: -73.9855,
    rating: 4.8,
    reviewCount: 96,
    bookable: true,
    priceFrom: 189,
    durationLabel: 'Nightly',
  ),
  TravelDestination(
    id: 'tv-quiet-suites',
    name: 'Quiet Suites Brooklyn',
    kind: 'hotel',
    city: 'Brooklyn, NY',
    area: 'Downtown Brooklyn',
    priceLabel: '\$',
    verified: false,
    inclusiveFor: ['Cognitive', 'Hearing'],
    accessFeatures: ['Quiet floor', 'Step-free entry', 'Plain-language info'],
    summary:
        'Small hotel with a sensory-quiet floor and flexible late checkout.',
    description:
        'Best for travelers who need low noise. Elevator building. Not all rooms are roll-in — request 201 or 203.',
    wheelchairAccessible: true,
    accessibleRooms: ['Quiet-floor roll-in 201', 'Quiet-floor roll-in 203'],
    accessibleBathrooms: ['Transfer shower', 'Grab bars'],
    routeNotes:
        'Jay St–MetroTech elevator to street; hotel is 1 block east on flat sidewalk.',
    lat: 40.692,
    lng: -73.987,
    rating: 4.4,
    reviewCount: 41,
    bookable: true,
    priceFrom: 129,
  ),
  TravelDestination(
    id: 'tv-liberty-museum',
    name: 'Harbor Heritage Museum',
    kind: 'attraction',
    city: 'New York, NY',
    area: 'Battery Park',
    priceLabel: 'Tickets',
    verified: true,
    inclusiveFor: ['Mobility', 'Visual', 'Hearing', 'Cognitive'],
    accessFeatures: [
      'Wheelchair routes',
      'Audio description',
      'Captions',
      'Quiet hour 9–10am',
    ],
    summary: 'Museum with a published wheelchair route and a daily quiet hour.',
    description:
        'Step-free from the ferry plaza elevator. Wheelchairs to borrow. Caption wands at the desk. Quiet hour before general admission.',
    imageUrl:
        'https://images.unsplash.com/photo-1554907984-15263bfd63bd?w=800&h=500&fit=crop',
    wheelchairAccessible: true,
    accessibleBathrooms: ['Lobby accessible restroom', 'Gallery restroom B'],
    routeNotes:
        'Use Battery Place elevator entrance; published blue route skips stairs between galleries 2–4.',
    lat: 40.703,
    lng: -74.016,
    rating: 4.7,
    reviewCount: 210,
    bookable: true,
    priceFrom: 28,
    durationLabel: 'Timed ticket',
  ),
  TravelDestination(
    id: 'tv-high-line',
    name: 'Elevated Park walk',
    kind: 'attraction',
    city: 'New York, NY',
    area: 'Chelsea',
    verified: true,
    inclusiveFor: ['Mobility', 'Cognitive'],
    accessFeatures: [
      'Step-free park',
      'Elevator at 14th & 30th',
      'Benches every block',
      'Wheelchair routes',
    ],
    summary: 'Elevated park with elevator access and frequent rest spots.',
    description:
        'Enter at 14th or 30th Street elevators. Surface is mostly smooth. Avoid peak weekend midday if crowds are hard.',
    wheelchairAccessible: true,
    accessibleBathrooms: ['Restroom near 16th St elevator'],
    routeNotes:
        'Best wheelchair route: 14th St elevator → northbound to 30th. Surfaces are timber/concrete; avoid wet leaves.',
    lat: 40.748,
    lng: -74.005,
    rating: 4.6,
    reviewCount: 180,
  ),
  TravelDestination(
    id: 'tv-central-garden',
    name: 'Conservatory Garden',
    kind: 'attraction',
    city: 'New York, NY',
    area: 'Upper East Side',
    verified: true,
    inclusiveFor: ['Mobility', 'Cognitive'],
    accessFeatures: [
      'Step-free paths',
      'Accessible restroom nearby',
      'Quiet mornings',
    ],
    summary: 'Formal garden with step-free paths and calmer mornings.',
    description:
        'Fifth Ave entrance is the most reliable step-free point. Good rest stop between museum visits.',
    wheelchairAccessible: true,
    accessibleBathrooms: ['Nearby park restroom (seasonal)'],
    routeNotes: 'Enter at Fifth Ave & 105th — curb cut and wide gate.',
    lat: 40.794,
    lng: -73.953,
    rating: 4.5,
    reviewCount: 72,
  ),
  TravelDestination(
    id: 'tv-green-table',
    name: 'Green Table Cafe',
    kind: 'restaurant',
    city: 'New York, NY',
    area: 'Rockefeller',
    priceLabel: '\$\$',
    verified: true,
    inclusiveFor: ['Mobility', 'Hearing'],
    accessFeatures: [
      'Wheelchair seating',
      'Hearing loop',
      'Large-print menu',
      'Step-free restroom',
    ],
    summary: 'Same accessible cafe as Ability Map — loop and wide aisles.',
    description:
        'Reserve table 4 for the hearing loop. Aisles fit a standard wheelchair. Restroom is step-free.',
    wheelchairAccessible: true,
    accessibleBathrooms: ['Step-free restroom with grab bars'],
    routeNotes: 'Street-level entrance on 51st; avoid lower plaza stairs.',
    lat: 40.7587,
    lng: -73.9787,
    rating: 4.6,
    reviewCount: 134,
    bookable: true,
    priceFrom: 45,
    durationLabel: 'Reservation',
  ),
  TravelDestination(
    id: 'tv-plain-kitchen',
    name: 'Plain Kitchen',
    kind: 'restaurant',
    city: 'Brooklyn, NY',
    area: 'Downtown Brooklyn',
    priceLabel: '\$',
    verified: false,
    inclusiveFor: ['Cognitive', 'Visual'],
    accessFeatures: [
      'Plain-language menu',
      'Quiet booths',
      'High-contrast print',
    ],
    summary: 'Casual kitchen with a plain-language menu and quieter booths.',
    description:
        'Staff will read the menu. Booth 1–3 are away from the espresso bar noise.',
    wheelchairAccessible: false,
    accessibleBathrooms: ['Restroom via short ramp'],
    routeNotes:
        'One step at front door — portable ramp on request (call ahead).',
    lat: 40.691,
    lng: -73.986,
    rating: 4.2,
    reviewCount: 38,
    bookable: true,
    priceFrom: 30,
  ),
  TravelDestination(
    id: 'tv-sensory-tour',
    name: 'Quiet City Highlights Tour',
    kind: 'tour',
    city: 'New York, NY',
    area: 'Midtown → Battery',
    priceLabel: 'Group',
    verified: true,
    inclusiveFor: ['Mobility', 'Cognitive', 'Hearing'],
    accessFeatures: [
      'Wheelchair-paced group',
      'Captioned live guide',
      'Rest every 20 min',
      'Step-free itinerary',
    ],
    summary:
        'Small-group accessible tour with rest stops and captioned guiding.',
    description:
        'Max 8 guests. Wheelchair and scooter friendly. Includes Harbor Heritage Museum quiet-hour entry and High Line elevator segment.',
    imageUrl:
        'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800&h=500&fit=crop',
    wheelchairAccessible: true,
    accessibleBathrooms: ['Stops planned near accessible restrooms'],
    routeNotes:
        'Published step-free route PDF; van transfer available between Battery and Chelsea.',
    lat: 40.75,
    lng: -73.99,
    rating: 4.9,
    reviewCount: 63,
    bookable: true,
    priceFrom: 79,
    durationLabel: '3 hours',
  ),
  TravelDestination(
    id: 'tv-asl-evening-tour',
    name: 'ASL Evening Lights Tour',
    kind: 'tour',
    city: 'New York, NY',
    area: 'Times Square → Hudson',
    verified: true,
    inclusiveFor: ['Hearing', 'Mobility'],
    accessFeatures: [
      'Deaf-led ASL guide',
      'Step-free route',
      'Visual cue cards',
    ],
    summary:
        'Deaf-led evening tour with ASL interpretation and step-free stops.',
    description:
        'Designed for Deaf and hard-of-hearing travelers. Hearing guests welcome with note that primary language is ASL.',
    wheelchairAccessible: true,
    routeNotes: 'Elevator-only buildings; no subway stairs on this route.',
    lat: 40.758,
    lng: -73.985,
    rating: 4.8,
    reviewCount: 47,
    bookable: true,
    priceFrom: 65,
    durationLabel: '2.5 hours',
  ),
  TravelDestination(
    id: 'tv-access-shuttle',
    name: 'AccessLink Airport Shuttle',
    kind: 'transport',
    city: 'Newark / NYC',
    area: 'EWR ↔ Midtown',
    priceLabel: 'Per trip',
    verified: true,
    inclusiveFor: ['Mobility'],
    accessFeatures: [
      'Wheelchair lift van',
      'Securement points',
      'Door-to-door',
      'Caregiver seat',
    ],
    summary: 'Wheelchair-accessible shuttle between EWR and Midtown hotels.',
    description:
        'Bookable shared or private van with lift. Drivers trained on securement. Meets at Terminal A arrivals.',
    wheelchairAccessible: true,
    routeNotes:
        'Pickup curb is step-free. Hotel drop-offs prioritized for Harbor Access Inn and Quiet Suites.',
    lat: 40.6895,
    lng: -74.1745,
    rating: 4.7,
    reviewCount: 88,
    bookable: true,
    priceFrom: 55,
    durationLabel: 'One way',
  ),
  TravelDestination(
    id: 'tv-stepfree-ferry',
    name: 'Step-Free Harbor Ferry',
    kind: 'transport',
    city: 'New York, NY',
    area: 'Battery ↔ Governors',
    verified: true,
    inclusiveFor: ['Mobility', 'Visual'],
    accessFeatures: [
      'Level boarding',
      'Audio announcements',
      'Wheelchair spaces',
    ],
    summary: 'Harbor ferry with level boarding and reserved wheelchair spaces.',
    description:
        'Gangway is level at standard tide. Staff assist with boarding. Pairs well with Harbor Heritage Museum.',
    wheelchairAccessible: true,
    accessibleBathrooms: ['Terminal accessible restroom'],
    routeNotes:
        'Use Battery elevator plaza; follow blue tactile path to gate 2.',
    lat: 40.701,
    lng: -74.013,
    rating: 4.5,
    reviewCount: 120,
    bookable: true,
    priceFrom: 18,
    durationLabel: 'Round trip',
  ),
];
