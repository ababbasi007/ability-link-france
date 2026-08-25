import '../models/accessibility_audit.dart';
import '../models/accessible_service.dart';
import '../models/place.dart';
import '../models/place_photo_section.dart';
import '../models/place_video_section.dart';
import 'places_service.dart';

/// Promotes submitted audit answers onto a browsable [AccessiblePlace] record.
class AuditPlacePromotion {
  const AuditPlacePromotion._();

  static const _detailKeys = {
    'parking.spaces',
    'parking.distance',
    'parking.surface',
    'parking.dropOffDistance',
    'parking.dropOffLocation',
    'parking.evSpaces',
    'entrance.rampGradient',
    'entrance.doorWidth',
    'entrance.doorType',
    'entrance.threshold',
    'entrance.elevatorDims',
    'toilet.doorWidth',
    'toilet.turning',
    'mobility.counters',
    'mobility.seating',
    'mobility.corridors',
  };

  /// Structured text/counter/dropdown answers plus measurements.
  static Map<String, String> extractAuditDetails(AccessibilityAudit audit) {
    final out = <String, String>{};
    for (final section in AuditCatalog.checklist) {
      for (final item in section.items) {
        if (item.kind == AuditFieldKind.toggle) {
          final v = audit.answerFor(section.id, item.id).trim();
          if (v == 'yes') {
            out['${section.id}.${item.id}'] = 'yes';
          }
          continue;
        }
        final v = audit.answerFor(section.id, item.id).trim();
        if (v.isNotEmpty) {
          out['${section.id}.${item.id}'] = v;
        }
      }
    }
    for (final e in audit.measurements.entries) {
      final v = e.value.trim();
      if (v.isNotEmpty) out['measurement.${e.key}'] = v;
    }
    return out;
  }

  /// Human-readable rows for place detail UI.
  static List<({String label, String value})> labeledDetails(
    Map<String, String> details,
  ) {
    final labels = <String, String>{};
    for (final section in AuditCatalog.checklist) {
      for (final item in section.items) {
        labels['${section.id}.${item.id}'] = item.label;
      }
    }
    const measurementLabels = {
      'measurement.doorWidthCm': 'Main door width',
      'measurement.rampSlopePercent': 'Ramp slope',
      'measurement.corridorWidthCm': 'Corridor width',
      'measurement.parkingWidthCm': 'Accessible parking width',
      'measurement.grabBarHeightCm': 'Grab bar height',
      'measurement.counterHeightCm': 'Counter height',
    };

    final rows = <({String label, String value})>[];
    for (final key in _detailKeys) {
      final v = details[key];
      if (v == null || v.isEmpty) continue;
      rows.add((label: labels[key] ?? key, value: v));
    }
    for (final e in details.entries) {
      if (_detailKeys.contains(e.key)) continue;
      if (e.key.startsWith('measurement.')) {
        rows.add((
          label: measurementLabels[e.key] ?? e.key.replaceFirst('measurement.', ''),
          value: e.value,
        ));
      }
    }
    return rows;
  }

  static List<PlacePhotoSection> mergePhotoSections(
    AccessiblePlace place,
    AccessibilityAudit audit,
  ) {
    final sections = <PlacePhotoSection>[...place.photoSections];
    void add(String url, String label, String source) {
      if (url.isEmpty || sections.any((p) => p.url == url)) return;
      sections.add(PlacePhotoSection(url: url, label: label, source: source));
    }

    if (place.imageUrl.isNotEmpty) {
      add(place.imageUrl, 'Main photo', 'listing');
    }
    for (final p in audit.photos) {
      if (!p.isNetwork) continue;
      add(
        p.uri,
        p.caption.trim().isNotEmpty ? p.caption.trim() : 'Audit photo',
        'audit',
      );
    }
    for (final u in place.photoUrls) {
      add(u, 'Accessibility photo', 'listing');
    }
    return sections;
  }

  static List<AccessibleServiceItem> mergeAccessibleServices(
    AccessiblePlace place,
    AccessibilityAudit audit,
  ) {
    final byId = <String, AccessibleServiceItem>{
      for (final s in place.accessibleServices) s.id: s,
    };
    for (final s in audit.inferredServices()) {
      byId.putIfAbsent(s.id, () => s);
    }
    return byId.values.toList();
  }

  static List<PlaceVideoSection> mergeVideoSections(AccessiblePlace place) =>
      place.videoSections;

  static List<String> mergePhotoUrls(
    AccessiblePlace place,
    AccessibilityAudit audit,
  ) {
    final urls = <String>[...place.photoUrls];
    for (final p in audit.photos) {
      if (p.isNetwork && !urls.contains(p.uri)) urls.add(p.uri);
    }
    return urls;
  }

  /// Firestore patch to merge onto `places/{id}` after audit submit.
  static Map<String, dynamic> buildPlaceUpdate({
    required AccessibilityAudit audit,
    required AccessiblePlace place,
  }) {
    final features = {...place.features, ...audit.inferredFeatures()}.toList();
    final needs = {...place.needs, ...audit.inferredNeeds()}.toList();
    final auditDetails = extractAuditDetails(audit);
    final photoUrls = mergePhotoUrls(place, audit);
    final photoSections = mergePhotoSections(place, audit);
    final accessibleServices = mergeAccessibleServices(place, audit);
    final videoSections = mergeVideoSections(place);

    final patch = <String, dynamic>{
      'features': features,
      'needs': needs,
      'auditDetails': auditDetails,
      'photoUrls': photoUrls,
      'photoSections': photoSections.map((p) => p.toMap()).toList(),
      if (accessibleServices.isNotEmpty)
        'accessibleServices': accessibleServices.map((s) => s.toMap()).toList(),
      if (videoSections.isNotEmpty)
        'videoSections': videoSections.map((v) => v.toMap()).toList(),
      'lastAuditScore': audit.score,
      'catalogVersion': PlacesService.catalogVersion,
    };

    if (audit.score > place.score) {
      patch['score'] = audit.score;
    }

    final phone = audit.phone.trim();
    if (phone.isNotEmpty) patch['phone'] = phone;

    final hours = audit.hours.trim();
    if (hours.isNotEmpty) patch['hours'] = hours;

    final website = audit.website.trim();
    if (website.isNotEmpty) patch['website'] = website;

    if (audit.auditorNotes.trim().isNotEmpty && place.description.trim().isEmpty) {
      patch['description'] = audit.auditorNotes.trim();
    }

    final spaces = audit.answerFor('parking', 'spaces').trim();
    if (spaces.isNotEmpty) {
      patch['accessibleParkingSpaces'] = int.tryParse(spaces) ?? spaces;
    }

    final dropDist = audit.answerFor('parking', 'dropOffDistance').trim();
    if (dropDist.isNotEmpty) patch['dropOffDistance'] = dropDist;
    final dropLoc = audit.answerFor('parking', 'dropOffLocation').trim();
    if (dropLoc.isNotEmpty) patch['dropOffLocation'] = dropLoc;

    final evSpaces = audit.answerFor('parking', 'evSpaces').trim();
    if (evSpaces.isNotEmpty) {
      patch['evAccessibleSpaces'] = int.tryParse(evSpaces) ?? evSpaces;
    }

    return patch;
  }
}
