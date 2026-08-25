import 'place.dart';

/// A named accessible service offered at a venue (beyond a simple feature chip).
class AccessibleServiceItem {
  const AccessibleServiceItem({
    required this.id,
    required this.label,
    this.description = '',
    this.available = true,
    this.source = 'listing',
  });

  final String id;
  final String label;
  final String description;
  final bool available;

  /// listing | audit | community
  final String source;

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    if (description.isNotEmpty) 'description': description,
    'available': available,
    if (source.isNotEmpty) 'source': source,
  };

  factory AccessibleServiceItem.fromMap(Map<String, dynamic> m) {
    return AccessibleServiceItem(
      id: (m['id'] as String?) ?? '',
      label: (m['label'] as String?) ?? 'Service',
      description: (m['description'] as String?) ?? '',
      available: m['available'] != false,
      source: (m['source'] as String?) ?? 'listing',
    );
  }
}

/// Builds the structured accessible-services list shown on place detail.
class AccessibleServicesCatalog {
  const AccessibleServicesCatalog._();

  static const _featureDescriptions = <String, String>{
    PlaceAmenities.stepFree: 'Step-free route from street to the main entrance.',
    PlaceAmenities.ramp: 'Ramp or level access at the primary entrance.',
    PlaceAmenities.elevator: 'Lift access between floors.',
    PlaceAmenities.toilet: 'Accessible restroom on site.',
    PlaceAmenities.parking: 'Marked accessible parking near the entrance.',
    PlaceAmenities.freeParking: 'No charge for accessible parking spaces.',
    PlaceAmenities.dropOff: 'Curbside drop-off close to the door.',
    PlaceAmenities.hearing: 'Hearing loop or amplified sound in key areas.',
    PlaceAmenities.signLanguage: 'Staff or interpreters for sign language.',
    PlaceAmenities.braille: 'Braille or tactile wayfinding available.',
    PlaceAmenities.quiet: 'Quiet or low-sensory waiting area.',
    PlaceAmenities.serviceAnimal: 'Service animals welcome throughout.',
    PlaceAmenities.receptionDesk: 'Lower or adjustable reception counter.',
    PlaceAmenities.calmWaitingRoom: 'Calm waiting room away from crowds.',
    PlaceAmenities.wideCorridors: 'Corridors wide enough for wheelchairs.',
    PlaceAmenities.accessibleSeating: 'Seating with space for mobility devices.',
    PlaceAmenities.lowCounters: 'Service counters at wheelchair height.',
    PlaceAmenities.evAccessibleParking: 'EV spaces with room to deploy a ramp.',
    PlaceAmenities.evCharging: 'Accessible EV charging bays.',
    PlaceAmenities.familyFriendly: 'Family restrooms and child-friendly layout.',
    PlaceAmenities.petFriendly: 'Companion pets allowed in public areas.',
  };

  static const _staffServices = <String, ({String label, String description})>{
    'wheelchairAssist': (
      label: 'Wheelchair escort',
      description: 'Staff can guide you through the building.',
    ),
    'personalAssist': (
      label: 'Personal assistance',
      description: 'One-to-one help on arrival when requested.',
    ),
    'priority': (
      label: 'Priority access',
      description: 'Shorter wait or dedicated queue for disabled visitors.',
    ),
    'formats': (
      label: 'Alternate formats',
      description: 'Large print, audio, or digital formats on request.',
    ),
  };

  static List<AccessibleServiceItem> resolve(AccessiblePlace place) {
    if (place.accessibleServices.isNotEmpty) {
      return place.accessibleServices.where((s) => s.available).toList();
    }
    return _derivedFromPlace(place);
  }

  static List<AccessibleServiceItem> _derivedFromPlace(AccessiblePlace place) {
    final out = <AccessibleServiceItem>[];
    final seen = <String>{};

    void add(AccessibleServiceItem item) {
      if (item.id.isEmpty || seen.contains(item.id)) return;
      seen.add(item.id);
      out.add(item);
    }

    for (final f in place.features) {
      add(
        AccessibleServiceItem(
          id: f,
          label: PlaceAmenities.label(f),
          description: _featureDescriptions[f] ?? '',
          source: 'listing',
        ),
      );
    }

    for (final entry in _staffServices.entries) {
      final key = 'staff.${entry.key}';
      final auditVal = place.auditDetails[key]?.toLowerCase();
      if (auditVal == 'yes') {
        add(
          AccessibleServiceItem(
            id: key,
            label: entry.value.label,
            description: entry.value.description,
            source: 'audit',
          ),
        );
      }
    }

    return out;
  }
}
