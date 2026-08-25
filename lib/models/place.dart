import 'dart:math' as math;

import 'place_category.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'place_photo_section.dart';
import 'place_video_section.dart';
import 'accessible_service.dart';

/// Amenity keys stored on [AccessiblePlace.features].
/// Minimum accessibility score for the "Fully accessible" filter.
const fullyAccessibleMinScore = 85;

/// Core features expected for a place to count as fully accessible.
const fullyAccessibleRequiredFeatures = <String>[
  PlaceAmenities.stepFree,
  PlaceAmenities.toilet,
];

class PlaceAmenities {
  static const parking = 'parking';
  static const toilet = 'toilet';
  static const stepFree = 'stepFree';
  static const ramp = 'ramp';
  static const elevator = 'elevator';
  static const braille = 'braille';
  static const hearing = 'hearing';
  static const signLanguage = 'signLanguage';
  static const accessibleTransit = 'accessibleTransit';
  static const quiet = 'quiet';
  static const receptionDesk = 'receptionDesk';
  static const calmWaitingRoom = 'calmWaitingRoom';
  static const serviceAnimal = 'serviceAnimal';
  static const visual = 'visual';
  static const captions = 'captions';
  static const dropOff = 'dropOff';
  static const wideCorridors = 'wideCorridors';
  static const accessibleSeating = 'accessibleSeating';
  static const lowCounters = 'lowCounters';
  static const brailleElevatorControls = 'brailleElevatorControls';
  static const highContrastSignage = 'highContrastSignage';
  static const audioAnnouncements = 'audioAnnouncements';
  static const goodLighting = 'goodLighting';
  static const visualEmergencyAlarms = 'visualEmergencyAlarms';
  static const textChat = 'textChat';
  static const evAccessibleParking = 'evAccessibleParking';
  static const evCharging = 'evCharging';
  static const freeParking = 'freeParking';
  static const familyFriendly = 'familyFriendly';
  static const petFriendly = 'petFriendly';

  static const labels = <String, String>{
    parking: 'Accessible parking',
    freeParking: 'Free accessible parking',
    toilet: 'Accessible toilets',
    stepFree: 'Step-free entrance',
    ramp: 'Step-free / ramp',
    elevator: 'Elevators',
    braille: 'Tactile / Braille',
    hearing: 'Hearing assistance',
    signLanguage: 'Sign-language support',
    accessibleTransit: 'Accessible transportation',
    quiet: 'Quiet / sensory-friendly',
    receptionDesk: 'Accessible reception desk',
    calmWaitingRoom: 'Calm waiting room',
    serviceAnimal: 'Service-animal friendly',
    visual: 'Visual / tactile aids',
    captions: 'Captioned displays',
    dropOff: 'Accessible drop-off',
    wideCorridors: 'Wide corridors',
    accessibleSeating: 'Accessible seating',
    lowCounters: 'Low service counters',
    brailleElevatorControls: 'Braille elevator controls',
    highContrastSignage: 'High-contrast signage',
    audioAnnouncements: 'Audio announcements',
    goodLighting: 'Good lighting',
    visualEmergencyAlarms: 'Visual emergency alarms',
    textChat: 'Text-based communication',
    evAccessibleParking: 'Accessible EV parking',
    evCharging: 'Accessible EV charging',
    familyFriendly: 'Family friendly',
    petFriendly: 'Pet friendly',
    'wheelchair': 'Wheelchair access',
  };

  static String label(String key) => labels[key] ?? key;
}

class AccessiblePlace {
  const AccessiblePlace({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.score,
    required this.rating,
    required this.reviewCount,
    required this.openNow,
    required this.imageUrl,
    required this.features,
    required this.needs,
    required this.address,
    this.verified = false,
    this.description = '',
    this.hidden = false,
    this.photoUrls = const [],
    this.photoSections = const [],
    this.videoSections = const [],
    this.accessibleServices = const [],
    this.peakHoursHint = '',
    this.catalogVersion = 0,
    this.phone = '',
    this.hours = '',
    this.website = '',
    this.auditDetails = const {},
    this.lastAuditScore = 0,
    this.governmentCertified = false,
    this.inspectionDate,
    this.certificateUrl = '',
    this.dropOffDistance = '',
    this.dropOffLocation = '',
    this.evAccessibleSpaces = 0,
  });

  final String id;
  final String name;
  final String category; // hospital, cafe, library, mall, transit, park, other
  final double lat;
  final double lng;
  final int score;
  final double rating;
  final int reviewCount;
  final bool openNow;
  final String imageUrl;
  final List<String> features;
  final List<String> needs; // wheelchair, visual, hearing, cognitive
  final String address;
  final bool verified;
  final String description;
  final bool hidden;
  final List<String> photoUrls;
  final List<PlacePhotoSection> photoSections;
  final List<PlaceVideoSection> videoSections;
  final List<AccessibleServiceItem> accessibleServices;
  final String peakHoursHint;
  final int catalogVersion;
  final String phone;
  final String hours;
  final String website;
  final Map<String, String> auditDetails;
  final int lastAuditScore;
  final bool governmentCertified;
  final DateTime? inspectionDate;
  final String certificateUrl;
  final String dropOffDistance;
  final String dropOffLocation;
  final int evAccessibleSpaces;

  bool get hasContactInfo =>
      phone.isNotEmpty || hours.isNotEmpty || website.isNotEmpty;

  bool get hasAuditDetails => auditDetails.isNotEmpty;

  List<PlacePhotoSection> get labeledPhotos {
    if (photoSections.isNotEmpty) return photoSections;
    final out = <PlacePhotoSection>[];
    void add(String url, String label) {
      if (url.isEmpty || out.any((p) => p.url == url)) return;
      out.add(PlacePhotoSection(url: url, label: label, source: 'listing'));
    }

    add(imageUrl, 'Main photo');
    for (final u in photoUrls) {
      add(u, 'Accessibility photo');
    }
    return out;
  }

  List<String> get galleryUrls =>
      labeledPhotos.map((p) => p.url).where((u) => u.isNotEmpty).toList();

  List<AccessibleServiceItem> get resolvedServices =>
      AccessibleServicesCatalog.resolve(this);

  bool get hasVideos => videoSections.isNotEmpty;

  bool get hasAccessibleServices => resolvedServices.isNotEmpty;

  bool isFullyAccessible({
    int minScore = fullyAccessibleMinScore,
    List<String> requiredFeatures = fullyAccessibleRequiredFeatures,
  }) {
    if (score < minScore) return false;
    return requiredFeatures.every(features.contains);
  }

  bool isOpenNow({DateTime? now}) {
    final n = now ?? DateTime.now();
    final raw = hours.trim();
    if (raw.isEmpty) return openNow;

    final always = _parseAlwaysOpen(raw);
    if (always != null) return always;

    final segments = _parseHoursSegments(raw);
    if (segments == null || segments.isEmpty) return openNow;

    final day = n.weekday - 1; // DateTime.weekday: Mon=1..Sun=7
    final minuteOfDay = n.hour * 60 + n.minute;

    for (final s in segments) {
      if (!s.days.contains(day)) continue;
      if (s.startMinute <= s.endMinute) {
        // End time is treated as exclusive: e.g. 18:00 means closed at 18:00.
        if (minuteOfDay >= s.startMinute && minuteOfDay < s.endMinute) {
          return true;
        }
      } else {
        // Overnight schedule like 20:00-02:00.
        if (minuteOfDay >= s.startMinute || minuteOfDay < s.endMinute) {
          return true;
        }
      }
    }
    return false;
  }

  /// True when [hours] indicates 24/7 or always-open access.
  bool get isAlwaysOpen {
    final raw = hours.trim();
    if (raw.isEmpty) return false;
    return _parseAlwaysOpen(raw) == true;
  }

  factory AccessiblePlace.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AccessiblePlace(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Place',
      category: (d['category'] as String?) ?? 'other',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      score: (d['score'] as num?)?.toInt() ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      openNow: d['openNow'] == true,
      imageUrl: (d['imageUrl'] as String?) ?? '',
      features: List<String>.from(d['features'] as List? ?? const []),
      needs: List<String>.from(d['needs'] as List? ?? const []),
      address: (d['address'] as String?) ?? '',
      verified: d['verified'] == true,
      description: (d['description'] as String?) ?? '',
      hidden: d['hidden'] == true,
      photoUrls: List<String>.from(d['photoUrls'] as List? ?? const []),
      photoSections: [
        for (final p in d['photoSections'] as List? ?? const [])
          if (p is Map) PlacePhotoSection.fromMap(Map<String, dynamic>.from(p)),
      ],
      videoSections: [
        for (final v in d['videoSections'] as List? ?? const [])
          if (v is Map) PlaceVideoSection.fromMap(Map<String, dynamic>.from(v)),
      ],
      accessibleServices: [
        for (final s in d['accessibleServices'] as List? ?? const [])
          if (s is Map) AccessibleServiceItem.fromMap(Map<String, dynamic>.from(s)),
      ],
      peakHoursHint: (d['peakHoursHint'] as String?) ?? '',
      catalogVersion: (d['catalogVersion'] as num?)?.toInt() ?? 0,
      phone: (d['phone'] as String?) ?? '',
      hours: (d['hours'] as String?) ?? '',
      website: (d['website'] as String?) ?? '',
      auditDetails: Map<String, String>.from(
        d['auditDetails'] as Map? ?? const {},
      ),
      lastAuditScore: (d['lastAuditScore'] as num?)?.toInt() ?? 0,
      governmentCertified: d['governmentCertified'] == true,
      inspectionDate: (d['inspectionDate'] as Timestamp?)?.toDate(),
      certificateUrl: (d['certificateUrl'] as String?) ?? '',
      dropOffDistance: (d['dropOffDistance'] as String?) ?? '',
      dropOffLocation: (d['dropOffLocation'] as String?) ?? '',
      evAccessibleSpaces: (d['evAccessibleSpaces'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'lat': lat,
    'lng': lng,
    'score': score,
    'rating': rating,
    'reviewCount': reviewCount,
    'openNow': openNow,
    'imageUrl': imageUrl,
    'photoUrls': photoUrls,
    if (photoSections.isNotEmpty)
      'photoSections': photoSections.map((p) => p.toMap()).toList(),
    if (videoSections.isNotEmpty)
      'videoSections': videoSections.map((v) => v.toMap()).toList(),
    if (accessibleServices.isNotEmpty)
      'accessibleServices': accessibleServices.map((s) => s.toMap()).toList(),
    if (peakHoursHint.isNotEmpty) 'peakHoursHint': peakHoursHint,
    'features': features,
    'needs': needs,
    'address': address,
    'verified': verified,
    'description': description,
    'catalogVersion': catalogVersion,
    if (phone.isNotEmpty) 'phone': phone,
    if (hours.isNotEmpty) 'hours': hours,
    if (website.isNotEmpty) 'website': website,
    if (auditDetails.isNotEmpty) 'auditDetails': auditDetails,
    if (lastAuditScore > 0) 'lastAuditScore': lastAuditScore,
    if (governmentCertified) 'governmentCertified': governmentCertified,
    if (inspectionDate != null) 'inspectionDate': Timestamp.fromDate(inspectionDate!),
    if (certificateUrl.isNotEmpty) 'certificateUrl': certificateUrl,
    if (dropOffDistance.isNotEmpty) 'dropOffDistance': dropOffDistance,
    if (dropOffLocation.isNotEmpty) 'dropOffLocation': dropOffLocation,
    if (evAccessibleSpaces > 0) 'evAccessibleSpaces': evAccessibleSpaces,
  };

  /// JSON-safe serialization for local disk cache (no Firestore types).
  Map<String, dynamic> toJson() {
    final m = Map<String, dynamic>.from(toMap());
    // Replace Firestore Timestamp with ISO-8601 string.
    final ts = m['inspectionDate'];
    if (ts != null) m['inspectionDate'] = inspectionDate!.toIso8601String();
    m['_id'] = id;
    return m;
  }

  factory AccessiblePlace.fromJson(Map<String, dynamic> d) {
    final inspRaw = d['inspectionDate'];
    DateTime? inspDate;
    if (inspRaw is String) {
      inspDate = DateTime.tryParse(inspRaw);
    }
    return AccessiblePlace(
      id: (d['_id'] as String?) ?? (d['id'] as String?) ?? '',
      name: (d['name'] as String?) ?? 'Place',
      category: (d['category'] as String?) ?? 'other',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      score: (d['score'] as num?)?.toInt() ?? 0,
      rating: (d['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      openNow: d['openNow'] == true,
      imageUrl: (d['imageUrl'] as String?) ?? '',
      features: List<String>.from(d['features'] as List? ?? const []),
      needs: List<String>.from(d['needs'] as List? ?? const []),
      address: (d['address'] as String?) ?? '',
      verified: d['verified'] == true,
      description: (d['description'] as String?) ?? '',
      hidden: d['hidden'] == true,
      photoUrls: List<String>.from(d['photoUrls'] as List? ?? const []),
      photoSections: [
        for (final p in d['photoSections'] as List? ?? const [])
          if (p is Map) PlacePhotoSection.fromMap(Map<String, dynamic>.from(p)),
      ],
      videoSections: [
        for (final v in d['videoSections'] as List? ?? const [])
          if (v is Map) PlaceVideoSection.fromMap(Map<String, dynamic>.from(v)),
      ],
      accessibleServices: [
        for (final s in d['accessibleServices'] as List? ?? const [])
          if (s is Map) AccessibleServiceItem.fromMap(Map<String, dynamic>.from(s)),
      ],
      peakHoursHint: (d['peakHoursHint'] as String?) ?? '',
      catalogVersion: (d['catalogVersion'] as num?)?.toInt() ?? 0,
      phone: (d['phone'] as String?) ?? '',
      hours: (d['hours'] as String?) ?? '',
      website: (d['website'] as String?) ?? '',
      auditDetails: Map<String, String>.from(
        d['auditDetails'] as Map? ?? const {},
      ),
      lastAuditScore: (d['lastAuditScore'] as num?)?.toInt() ?? 0,
      governmentCertified: d['governmentCertified'] == true,
      inspectionDate: inspDate,
      certificateUrl: (d['certificateUrl'] as String?) ?? '',
      dropOffDistance: (d['dropOffDistance'] as String?) ?? '',
      dropOffLocation: (d['dropOffLocation'] as String?) ?? '',
      evAccessibleSpaces: (d['evAccessibleSpaces'] as num?)?.toInt() ?? 0,
    );
  }

  bool hasAmenity(String key) {
    switch (key) {
      case 'All Places':
      case 'all':
        return true;
      case 'Wheelchair':
      case 'wheelchair':
        return needs.contains('wheelchair') ||
            features.contains(PlaceAmenities.ramp) ||
            features.contains(PlaceAmenities.stepFree);
      case 'Visual':
      case 'visual':
        return needs.contains('visual') ||
            features.contains(PlaceAmenities.visual) ||
            features.contains(PlaceAmenities.braille) ||
            features.contains(PlaceAmenities.brailleElevatorControls) ||
            features.contains(PlaceAmenities.highContrastSignage) ||
            features.contains(PlaceAmenities.audioAnnouncements) ||
            features.contains(PlaceAmenities.goodLighting);
      case 'Hearing':
      case 'hearing':
        return needs.contains('hearing') ||
            features.contains(PlaceAmenities.hearing) ||
            features.contains(PlaceAmenities.signLanguage) ||
            features.contains(PlaceAmenities.captions) ||
            features.contains(PlaceAmenities.visualEmergencyAlarms) ||
            features.contains(PlaceAmenities.textChat);
      case 'Cognitive':
      case 'cognitive':
        return needs.contains('cognitive') ||
            features.contains(PlaceAmenities.quiet);
      case PlaceAmenities.stepFree:
      case PlaceAmenities.ramp:
        return features.contains(PlaceAmenities.stepFree) ||
            features.contains(PlaceAmenities.ramp);
      case PlaceAmenities.braille:
        return features.contains(PlaceAmenities.braille);
      case PlaceAmenities.signLanguage:
        return features.contains(PlaceAmenities.signLanguage);
      case PlaceAmenities.accessibleTransit:
        return category == 'transit' ||
            features.contains(PlaceAmenities.accessibleTransit);
      case PlaceAmenities.quiet:
        return features.contains(PlaceAmenities.quiet);
      case PlaceAmenities.serviceAnimal:
        return features.contains(PlaceAmenities.serviceAnimal);
      case PlaceAmenities.freeParking:
        return features.contains(PlaceAmenities.freeParking) ||
            _auditSaysFreeParking();
      case PlaceAmenities.familyFriendly:
        return features.contains(PlaceAmenities.familyFriendly);
      case PlaceAmenities.petFriendly:
        return features.contains(PlaceAmenities.petFriendly);
      default:
        return features.contains(key) || needs.contains(key);
    }
  }

  bool _auditSaysFreeParking() {
    for (final entry in auditDetails.entries) {
      final key = entry.key.toLowerCase();
      if (!key.contains('parking') && !key.contains('fee')) continue;
      final value = entry.value.trim().toLowerCase();
      if (value == 'free' || value.contains('no charge')) return true;
    }
    return false;
  }

  bool matchesFilter(String filter) => hasAmenity(filter);

  bool matchesAmenities(Set<String> amenityIds) {
    if (amenityIds.isEmpty) return true;
    return amenityIds.every(hasAmenity);
  }

  /// Haversine distance in kilometers.
  double distanceKm(double fromLat, double fromLng) {
    const earth = 6371.0;
    final dLat = _rad(lat - fromLat);
    final dLng = _rad(lng - fromLng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(fromLat)) *
            math.cos(_rad(lat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earth * c;
  }

  String distanceLabel(double fromLat, double fromLng) {
    final km = distanceKm(fromLat, fromLng);
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String get categoryLabel => PlaceCategory.labelFor(category);

  PlaceCategory get placeCategory => PlaceCategory.resolve(category);

  bool matchesPlaceType(String? typeFilter) =>
      PlaceCategory.matchesType(category, typeFilter);

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        address.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        description.toLowerCase().contains(q) ||
        features.any(
          (f) =>
              f.toLowerCase().contains(q) ||
              PlaceAmenities.label(f).toLowerCase().contains(q),
        ) ||
        auditDetails.values.any((v) => v.toLowerCase().contains(q)) ||
        phone.toLowerCase().contains(q) ||
        hours.toLowerCase().contains(q) ||
        website.toLowerCase().contains(q) ||
        needs.any(
          (n) =>
              n.toLowerCase().contains(q) ||
              PlaceAmenities.label(n).toLowerCase().contains(q),
        );
  }

  static double _rad(double d) => d * math.pi / 180;

  bool? _parseAlwaysOpen(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('24/7')) return true;
    if (s.contains('24-7')) return true;
    if (s.contains('open 24') && s.contains('hour')) return true;
    if (s.contains('24 hours')) return true;
    return null;
  }

  List<_HoursSegment>? _parseHoursSegments(String raw) {
    // Supports seeded patterns like:
    // "Mon–Fri 7:00–20:00 · Sat–Sun 8:00–18:00"
    // "Open 24 hours"
    final normalized = raw
        .replaceAll('\u00A0', ' ')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('−', '-')
        .trim();

    final parts = normalized
        .split(RegExp(r'[·|]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty);

    // Capture: days + startTime-endTime
    final rangeExp = RegExp(
      r'^(?<days>.+?)\s+(?<start>\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s*-\s*(?<end>\d{1,2}(?::\d{2})?\s*(?:am|pm)?)\s*$',
      caseSensitive: false,
    );

    final segments = <_HoursSegment>[];
    for (final part in parts) {
      final m = rangeExp.firstMatch(part);
      if (m == null) continue;
      final daysStr = (m.namedGroup('days') ?? '').trim();
      final startStr = (m.namedGroup('start') ?? '').trim();
      final endStr = (m.namedGroup('end') ?? '').trim();

      final startMinute = _parseTimeToMinutes(startStr);
      final endMinute = _parseTimeToMinutes(endStr);
      final days = _parseDays(daysStr);
      if (startMinute == null || endMinute == null || days == null) continue;
      segments.add(
        _HoursSegment(days: days, startMinute: startMinute, endMinute: endMinute),
      );
    }

    return segments.isEmpty ? null : segments;
  }

  int? _parseTimeToMinutes(String raw) {
    var s = raw.trim().toLowerCase();
    s = s.replaceAll('.', ':');

    final isPm = s.contains('pm');
    final isAm = s.contains('am');
    if (isPm || isAm) {
      s = s.replaceAll('am', '').replaceAll('pm', '').trim();
    }

    final m = RegExp(r'^(?<h>\d{1,2})(?::(?<m>\d{2}))?$').firstMatch(s);
    if (m == null) return null;
    final hour = int.parse(m.namedGroup('h')!);
    final minute = m.namedGroup('m') != null
        ? int.parse(m.namedGroup('m')!)
        : 0;

    var h = hour;
    if (isPm && h != 12) h += 12;
    if (isAm && h == 12) h = 0;

    if (h < 0 || h > 23) return null;
    if (minute < 0 || minute > 59) return null;
    return h * 60 + minute;
  }

  Set<int>? _parseDays(String raw) {
    // Days mapping uses 0=Mon..6=Sun.
    final normalized = raw
        .toLowerCase()
        .trim()
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(' ', '');

    int? day(String token) => switch (token) {
          // English
          'mon' || 'monday' => 0,
          'tue' || 'tues' || 'tuesday' => 1,
          'wed' || 'wednesday' => 2,
          'thu' || 'thur' || 'thurs' || 'thursday' => 3,
          'fri' || 'friday' => 4,
          'sat' || 'saturday' => 5,
          'sun' || 'sunday' => 6,
          // French
          'lun' || 'lundi' => 0,
          'mar' || 'mardi' => 1,
          'mer' || 'mercredi' => 2,
          'jeu' || 'jeudi' => 3,
          'ven' || 'vendredi' => 4,
          'sam' || 'samedi' => 5,
          'dim' || 'dimanche' => 6,
          _ => null,
        };

    if (normalized.contains('-')) {
      final parts = normalized.split('-').where((p) => p.isNotEmpty).toList();
      if (parts.length < 2) return null;
      final start = day(parts.first);
      final end = day(parts.last);
      if (start == null || end == null) return null;

      final days = <int>{};
      if (start <= end) {
        for (var d = start; d <= end; d++) {
          days.add(d);
        }
      } else {
        // Wrapped range: e.g. Fri-Mon.
        for (var d = start; d <= 6; d++) {
          days.add(d);
        }
        for (var d = 0; d <= end; d++) {
          days.add(d);
        }
      }
      return days;
    }

    // Single day or a comma-separated list.
    final tokens = normalized.split(RegExp(r'[,&]')).where((t) => t.isNotEmpty);
    if (tokens.isEmpty) return null;

    final days = <int>{};
    for (final t in tokens) {
      final idx = day(t);
      if (idx == null) return null;
      days.add(idx);
    }
    return days;
  }
}

class _HoursSegment {
  const _HoursSegment({
    required this.days,
    required this.startMinute,
    required this.endMinute,
  });

  final Set<int> days;
  final int startMinute;
  final int endMinute;
}
