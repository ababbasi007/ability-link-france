import 'package:flutter/material.dart';

/// How a place category is surfaced in the app.
enum PlaceCategoryModule {
  /// Pins, labels, and filters on the accessibility map.
  native,

  /// Opens Healthcare & Rehab / provider booking flows.
  healthcare,

  /// Opens Government offices / benefits directory.
  benefits,

  /// Opens education / provider directory filtered to schools.
  education,
}

/// Canonical place categories for map pins, labels, and smart filters.
class PlaceCategory {
  const PlaceCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.module = PlaceCategoryModule.native,
    this.aliases = const [],
  });

  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final PlaceCategoryModule module;
  final List<String> aliases;

  bool matches(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return false;
    if (s == id) return true;
    return aliases.any((a) => a.toLowerCase() == s);
  }

  static const all = <PlaceCategory>[
    PlaceCategory(
      id: 'hospital',
      label: 'Hospital',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFEF4444),
      aliases: ['medical'],
    ),
    PlaceCategory(
      id: 'cafe',
      label: 'Café',
      icon: Icons.local_cafe_rounded,
      color: Color(0xFFF59E0B),
      aliases: ['coffee'],
    ),
    PlaceCategory(
      id: 'library',
      label: 'Library',
      icon: Icons.local_library_rounded,
      color: Color(0xFF3B82F6),
    ),
    PlaceCategory(
      id: 'mall',
      label: 'Shopping mall',
      icon: Icons.store_mall_directory_rounded,
      color: Color(0xFF8B5CF6),
      aliases: ['shopping'],
    ),
    PlaceCategory(
      id: 'transit',
      label: 'Transit hub',
      icon: Icons.directions_subway_rounded,
      color: Color(0xFF14B8A6),
      aliases: ['transport'],
    ),
    PlaceCategory(
      id: 'park',
      label: 'Park',
      icon: Icons.park_rounded,
      color: Color(0xFF22C55E),
    ),
    PlaceCategory(
      id: 'clinic',
      label: 'Clinic',
      icon: Icons.medical_information_rounded,
      color: Color(0xFFDC2626),
      module: PlaceCategoryModule.healthcare,
      aliases: ['urgent_care'],
    ),
    PlaceCategory(
      id: 'doctor',
      label: 'Doctor',
      icon: Icons.medical_services_rounded,
      color: Color(0xFFDC2626),
      module: PlaceCategoryModule.healthcare,
      aliases: ['gp', 'physician'],
    ),
    PlaceCategory(
      id: 'rehab',
      label: 'Rehab center',
      icon: Icons.accessible_forward_rounded,
      color: Color(0xFFDC2626),
      module: PlaceCategoryModule.healthcare,
      aliases: ['rehabilitation', 'physiotherapy'],
    ),
    PlaceCategory(
      id: 'school',
      label: 'School / University',
      icon: Icons.school_rounded,
      color: Color(0xFF2563EB),
      module: PlaceCategoryModule.education,
      aliases: ['university', 'education', 'college', 'course'],
    ),
    PlaceCategory(
      id: 'therapist',
      label: 'Therapist',
      icon: Icons.healing_rounded,
      color: Color(0xFFDC2626),
      module: PlaceCategoryModule.healthcare,
      aliases: ['therapy', 'counselor', 'psychologist'],
    ),
    PlaceCategory(
      id: 'dentist',
      label: 'Dentist',
      icon: Icons.medication_rounded,
      color: Color(0xFFDC2626),
      module: PlaceCategoryModule.healthcare,
      aliases: ['dental'],
    ),
    PlaceCategory(
      id: 'government',
      label: 'Government office',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF6B7280),
      module: PlaceCategoryModule.benefits,
      aliases: ['office', 'public_service'],
    ),
    PlaceCategory(
      id: 'bank',
      label: 'Bank',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF64748B),
      aliases: ['atm', 'credit_union'],
    ),
    PlaceCategory(
      id: 'hotel',
      label: 'Hotel',
      icon: Icons.hotel_rounded,
      color: Color(0xFF0EA5E9),
      aliases: ['lodging', 'hostel'],
    ),
    PlaceCategory(
      id: 'restaurant',
      label: 'Restaurant',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFF97316),
      aliases: ['food', 'dining'],
    ),
    PlaceCategory(
      id: 'grocery',
      label: 'Grocery store',
      icon: Icons.local_grocery_store_rounded,
      color: Color(0xFF84CC16),
      aliases: ['supermarket', 'market'],
    ),
    PlaceCategory(
      id: 'worship',
      label: 'Mosque / Church',
      icon: Icons.church_rounded,
      color: Color(0xFF7C3AED),
      aliases: ['mosque', 'church', 'temple', 'synagogue'],
    ),
    PlaceCategory(
      id: 'museum',
      label: 'Museum',
      icon: Icons.museum_rounded,
      color: Color(0xFF9333EA),
      aliases: ['gallery', 'exhibit'],
    ),
    PlaceCategory(
      id: 'gym',
      label: 'Sports center / Gym',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFEA580C),
      aliases: ['sports', 'fitness', 'recreation'],
    ),
    PlaceCategory(
      id: 'beach',
      label: 'Beach',
      icon: Icons.beach_access_rounded,
      color: Color(0xFF06B6D4),
      aliases: ['shore', 'waterfront'],
    ),
    PlaceCategory(
      id: 'airport',
      label: 'Airport',
      icon: Icons.flight_rounded,
      color: Color(0xFF0284C7),
      aliases: ['terminal'],
    ),
    PlaceCategory(
      id: 'railway',
      label: 'Railway station',
      icon: Icons.train_rounded,
      color: Color(0xFF0D9488),
      aliases: ['train', 'station', 'rail'],
    ),
    PlaceCategory(
      id: 'public_toilet',
      label: 'Public toilet',
      icon: Icons.wc_rounded,
      color: Color(0xFF0891B2),
      aliases: ['toilet', 'restroom', 'comfort_station'],
    ),
    PlaceCategory(
      id: 'pharmacy',
      label: 'Pharmacy',
      icon: Icons.local_pharmacy_rounded,
      color: Color(0xFF10B981),
      aliases: ['chemist'],
    ),
    PlaceCategory(
      id: 'parking',
      label: 'Parking',
      icon: Icons.local_parking_rounded,
      color: Color(0xFF2563EB),
      aliases: ['car_park', 'accessible_parking'],
    ),
    PlaceCategory(
      id: 'caregiver',
      label: 'Assistance',
      icon: Icons.support_agent_rounded,
      color: Color(0xFF7C3AED),
      aliases: ['assistant', 'assistance'],
    ),
  ];

  static const other = PlaceCategory(
    id: 'other',
    label: 'Place',
    icon: Icons.place_rounded,
    color: Color(0xFF9CA3AF),
  );

  /// Categories shown in the map “Place type” smart-filter row.
  static const smartFilterIds = [
    'hospital',
    'cafe',
    'restaurant',
    'grocery',
    'library',
    'mall',
    'transit',
    'railway',
    'airport',
    'park',
    'beach',
    'hotel',
    'museum',
    'gym',
    'worship',
    'public_toilet',
  ];

  static List<PlaceCategory> get smartFilters => [
    for (final id in smartFilterIds) byId(id),
  ];

  static PlaceCategory byId(String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return other;
  }

  static PlaceCategory resolve(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s.isEmpty) return other;
    for (final c in all) {
      if (c.matches(s)) return c;
    }
    if (s == 'store') return byId('mall');
    return PlaceCategory(
      id: s,
      label: s.isEmpty ? other.label : '${s[0].toUpperCase()}${s.substring(1)}',
      icon: other.icon,
      color: other.color,
    );
  }

  static String labelFor(String? raw) => resolve(raw).label;
  static IconData iconFor(String? raw) => resolve(raw).icon;
  static Color colorFor(String? raw) => resolve(raw).color;
  static PlaceCategoryModule moduleFor(String? raw) => resolve(raw).module;

  static bool matchesType(String? raw, String? filterId) {
    if (filterId == null || filterId.isEmpty || filterId == 'all') {
      return true;
    }
    return resolve(raw).id == filterId;
  }
}
