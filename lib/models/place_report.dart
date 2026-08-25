import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'place_barrier_report.dart';

/// User-submitted place barrier or listing report (`placeReports` collection).
class PlaceReport {
  const PlaceReport({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.category,
    required this.type,
    required this.details,
    required this.status,
    required this.photoUrls,
    this.videoUrls = const [],
    this.createdAt,
  });

  final String id;
  final String placeId;
  final String placeName;
  final String category;
  final String type;
  final String details;
  final String status;
  final List<String> photoUrls;
  final List<String> videoUrls;
  final DateTime? createdAt;

  PlaceBarrierCategory? get categoryMeta => PlaceBarrierCategory.byId(category);

  String get categoryLabel => categoryMeta?.label ?? category;

  bool get isOpen => status == PlaceReportStatus.open;

  bool get isResolved => status == PlaceReportStatus.resolved;

  factory PlaceReport.fromMap(String id, Map<String, dynamic> data) {
    return PlaceReport(
      id: id,
      placeId: (data['placeId'] as String?) ?? '',
      placeName: (data['placeName'] as String?) ?? 'Place',
      category: (data['category'] as String?) ?? '',
      type: (data['type'] as String?) ?? 'barrier',
      details: (data['details'] as String?) ?? '',
      status: PlaceReportStatus.normalize(data['status'] as String?),
      photoUrls: List<String>.from(data['photoUrls'] as List? ?? const []),
      videoUrls: List<String>.from(data['videoUrls'] as List? ?? const []),
      createdAt: _readTime(data['createdAt']),
    );
  }
}

class PlaceReportStatus {
  static const open = 'open';
  static const inReview = 'in_review';
  static const resolved = 'resolved';
  static const dismissed = 'dismissed';

  static String normalize(String? raw) {
    final s = (raw ?? open).trim().toLowerCase();
    return switch (s) {
      inReview => inReview,
      resolved => resolved,
      dismissed => dismissed,
      _ => open,
    };
  }

  static String label(String status) => switch (normalize(status)) {
    inReview => 'In review',
    resolved => 'Resolved',
    dismissed => 'Dismissed',
    _ => 'Open',
  };

  static String message(String status) => switch (normalize(status)) {
    inReview =>
      'Our team is reviewing your report. We\'ll update the listing when verified.',
    resolved =>
      'Thanks — this report was reviewed and the place details were updated or confirmed.',
    dismissed =>
      'This report was closed without changes. Submit again if the issue persists.',
    _ => 'We received your report and will review it soon.',
  };

  static Color color(String status) => switch (normalize(status)) {
    inReview => const Color(0xFF3B82F6),
    resolved => const Color(0xFF22C55E),
    dismissed => const Color(0xFF9CA3AF),
    _ => const Color(0xFFF59E0B),
  };

  static IconData icon(String status) => switch (normalize(status)) {
    inReview => Icons.hourglass_top_rounded,
    resolved => Icons.check_circle_outline_rounded,
    dismissed => Icons.block_rounded,
    _ => Icons.flag_outlined,
  };
}

DateTime? _readTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
