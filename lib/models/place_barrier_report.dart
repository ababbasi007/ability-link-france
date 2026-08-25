import 'package:flutter/material.dart';

/// Structured barrier / listing issue categories for place reports.
class PlaceBarrierCategory {
  const PlaceBarrierCategory({
    required this.id,
    required this.label,
    required this.hint,
    required this.icon,
  });

  final String id;
  final String label;
  final String hint;
  final IconData icon;

  static const elevator = PlaceBarrierCategory(
    id: 'elevator',
    label: 'Broken elevator / escalator',
    hint: 'Which lift, floor, and what happened?',
    icon: Icons.elevator_rounded,
  );

  static const ramp = PlaceBarrierCategory(
    id: 'ramp',
    label: 'Blocked or broken ramp',
    hint: 'Describe the blockage or damage…',
    icon: Icons.ramp_right_rounded,
  );

  static const toilet = PlaceBarrierCategory(
    id: 'toilet',
    label: 'Inaccessible toilet',
    hint: 'Out of order, locked, too small, missing rails…',
    icon: Icons.wc_rounded,
  );

  static const parking = PlaceBarrierCategory(
    id: 'parking',
    label: 'Accessible parking issue',
    hint: 'Spaces occupied, blocked, or not marked…',
    icon: Icons.local_parking_rounded,
  );

  static const construction = PlaceBarrierCategory(
    id: 'construction',
    label: 'Temporary construction barrier',
    hint: 'Where is the work and how long has it been there?',
    icon: Icons.construction_rounded,
  );

  static const incorrectInfo = PlaceBarrierCategory(
    id: 'incorrect_info',
    label: 'Incorrect venue information',
    hint: 'Wrong hours, features, address, photos, or score…',
    icon: Icons.info_outline_rounded,
  );

  static const featureImprovement = PlaceBarrierCategory(
    id: 'feature_improvement',
    label: 'Suggest accessibility improvement',
    hint: 'What feature or entry change would help most?',
    icon: Icons.lightbulb_outline_rounded,
  );

  static const all = [
    elevator,
    ramp,
    toilet,
    parking,
    construction,
    incorrectInfo,
  ];

  /// Barrier report sheet categories only (excludes listing / suggestion flows).
  static const barrierReportCategories = all;

  static const allIncludingSuggestions = [
    ...all,
    featureImprovement,
  ];

  static PlaceBarrierCategory? byId(String id) {
    for (final c in allIncludingSuggestions) {
      if (c.id == id) return c;
    }
    return null;
  }
}

/// Firestore payload for `placeReports` (barrier or listing issue).
Map<String, dynamic> placeReportDocument({
  required String uid,
  required String placeId,
  required String placeName,
  required String category,
  required String details,
  List<String> photoUrls = const [],
  List<String> videoUrls = const [],
}) {
  return {
    'uid': uid,
    'placeId': placeId,
    'placeName': placeName,
    'category': category,
    'type': switch (category) {
      _ when category == PlaceBarrierCategory.incorrectInfo.id => 'listing',
      _ when category == PlaceBarrierCategory.featureImprovement.id =>
        'suggestion',
      _ => 'barrier',
    },
    'details': details.trim(),
    'photoUrls': photoUrls,
    'videoUrls': videoUrls,
    'status': 'open',
  };
}
