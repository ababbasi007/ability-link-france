import 'package:cloud_firestore/cloud_firestore.dart';

class TravelDestination {
  const TravelDestination({
    required this.id,
    required this.name,
    required this.kind,
    required this.city,
    required this.summary,
    required this.description,
    required this.accessFeatures,
    required this.inclusiveFor,
    this.area = '',
    this.priceLabel = '',
    this.verified = false,
    this.imageUrl = '',
    this.wheelchairAccessible = false,
    this.accessibleRooms = const [],
    this.accessibleBathrooms = const [],
    this.routeNotes = '',
    this.lat = 0,
    this.lng = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.bookable = false,
    this.priceFrom = 0,
    this.currency = '\$',
    this.durationLabel = '',
  });

  final String id;
  final String name;

  /// hotel | attraction | restaurant | tour | transport
  final String kind;
  final String city;
  final String summary;
  final String description;
  final List<String> accessFeatures;
  final List<String> inclusiveFor;
  final String area;
  final String priceLabel;
  final bool verified;
  final String imageUrl;
  final bool wheelchairAccessible;
  final List<String> accessibleRooms;
  final List<String> accessibleBathrooms;
  final String routeNotes;
  final double lat;
  final double lng;
  final double rating;
  final int reviewCount;
  final bool bookable;
  final int priceFrom;
  final String currency;
  final String durationLabel;

  bool get hasCoords => lat != 0 || lng != 0;

  String get kindLabel => switch (kind) {
    'hotel' => 'Hotel',
    'restaurant' => 'Restaurant',
    'tour' => 'Tour',
    'transport' => 'Transport',
    _ => 'Attraction',
  };

  String get bookPriceLabel {
    if (priceFrom > 0) return '$currency$priceFrom+';
    if (priceLabel.isNotEmpty) return priceLabel;
    return 'Quote';
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        area.toLowerCase().contains(q) ||
        summary.toLowerCase().contains(q) ||
        kind.toLowerCase().contains(q) ||
        accessFeatures.any((f) => f.toLowerCase().contains(q)) ||
        accessibleRooms.any((f) => f.toLowerCase().contains(q)) ||
        accessibleBathrooms.any((f) => f.toLowerCase().contains(q)) ||
        routeNotes.toLowerCase().contains(q);
  }

  factory TravelDestination.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return TravelDestination(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Place',
      kind: (d['kind'] as String?) ?? 'attraction',
      city: (d['city'] as String?) ?? '',
      summary: (d['summary'] as String?) ?? '',
      description: (d['description'] as String?) ?? '',
      accessFeatures: List<String>.from(
        d['accessFeatures'] as List? ?? const [],
      ),
      inclusiveFor: List<String>.from(d['inclusiveFor'] as List? ?? const []),
      area: (d['area'] as String?) ?? '',
      priceLabel: (d['priceLabel'] as String?) ?? '',
      verified: d['verified'] == true,
      imageUrl: (d['imageUrl'] as String?) ?? '',
      wheelchairAccessible:
          d['wheelchairAccessible'] == true ||
          List<String>.from(
            d['accessFeatures'] as List? ?? const [],
          ).any((f) => f.toLowerCase().contains('wheelchair')),
      accessibleRooms: List<String>.from(
        d['accessibleRooms'] as List? ?? const [],
      ),
      accessibleBathrooms: List<String>.from(
        d['accessibleBathrooms'] as List? ?? const [],
      ),
      routeNotes: (d['routeNotes'] as String?) ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      bookable: d['bookable'] == true,
      priceFrom: (d['priceFrom'] as num?)?.toInt() ?? 0,
      currency: (d['currency'] as String?) ?? '\$',
      durationLabel: (d['durationLabel'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'kind': kind,
    'city': city,
    'summary': summary,
    'description': description,
    'accessFeatures': accessFeatures,
    'inclusiveFor': inclusiveFor,
    'area': area,
    'priceLabel': priceLabel,
    'verified': verified,
    'imageUrl': imageUrl,
    'wheelchairAccessible': wheelchairAccessible,
    'accessibleRooms': accessibleRooms,
    'accessibleBathrooms': accessibleBathrooms,
    'routeNotes': routeNotes,
    'lat': lat,
    'lng': lng,
    'rating': rating,
    'reviewCount': reviewCount,
    'bookable': bookable,
    'priceFrom': priceFrom,
    'currency': currency,
    'durationLabel': durationLabel,
  };
}

class TravelItinerary {
  const TravelItinerary({
    required this.id,
    required this.uid,
    required this.title,
    required this.days,
    required this.stopIds,
    required this.stopNames,
    required this.notes,
    required this.createdAt,
    this.archived = false,
  });

  final String id;
  final String uid;
  final String title;
  final int days;
  final List<String> stopIds;
  final List<String> stopNames;
  final String notes;
  final DateTime createdAt;
  final bool archived;

  factory TravelItinerary.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return TravelItinerary(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      title: (d['title'] as String?) ?? 'Trip',
      days: (d['days'] as num?)?.toInt() ?? 1,
      stopIds: List<String>.from(d['stopIds'] as List? ?? const []),
      stopNames: List<String>.from(d['stopNames'] as List? ?? const []),
      notes: (d['notes'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      archived: d['archived'] == true,
    );
  }
}

class TravelBooking {
  const TravelBooking({
    required this.id,
    required this.uid,
    required this.destinationId,
    required this.destinationName,
    required this.kind,
    required this.service,
    required this.startAt,
    required this.status,
    required this.priceCents,
    required this.currency,
    required this.paymentStatus,
    required this.createdAt,
    this.notes = '',
    this.guests = 1,
  });

  final String id;
  final String uid;
  final String destinationId;
  final String destinationName;
  final String kind;
  final String service;
  final DateTime startAt;
  final String status;
  final int priceCents;
  final String currency;
  final String paymentStatus;
  final DateTime createdAt;
  final String notes;
  final int guests;

  String get priceLabel {
    final amount = priceCents / 100;
    return '$currency${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  factory TravelBooking.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final start = d['startAt'];
    final created = d['createdAt'];
    return TravelBooking(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      destinationId: (d['destinationId'] as String?) ?? '',
      destinationName: (d['destinationName'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? '',
      service: (d['service'] as String?) ?? '',
      startAt: start is Timestamp ? start.toDate() : DateTime.now(),
      status: (d['status'] as String?) ?? 'booked',
      priceCents: (d['priceCents'] as num?)?.toInt() ?? 0,
      currency: (d['currency'] as String?) ?? '\$',
      paymentStatus: (d['paymentStatus'] as String?) ?? 'unpaid',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      notes: (d['notes'] as String?) ?? '',
      guests: (d['guests'] as num?)?.toInt() ?? 1,
    );
  }
}
