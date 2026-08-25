import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class TransportOption {
  const TransportOption({
    required this.id,
    required this.kind,
    required this.name,
    required this.lat,
    required this.lng,
    required this.summary,
    required this.features,
    this.stepFree = false,
    this.elevatorStatus = 'unknown',
    this.phone = '',
    this.spaces = 0,
    this.verified = false,
    this.apiHook = '',
  });

  final String id;

  /// transit | bus | taxi | parking | ev
  final String kind;
  final String name;
  final double lat;
  final double lng;
  final String summary;
  final List<String> features;
  final bool stepFree;
  final String elevatorStatus;
  final String phone;
  final int spaces;
  final bool verified;

  /// Named integration slot (GTFS, taxi API, parking feed).
  final String apiHook;

  String get kindLabel => switch (kind) {
        'taxi' => 'Accessible taxi',
        'parking' => 'Accessible parking',
        'bus' => 'Accessible bus stop',
        'ev' => 'EV accessibility',
        _ => 'Transit',
      };

  String get elevatorLabel => switch (elevatorStatus) {
    'in-service' => 'Elevators in service',
    'out' => 'Elevator outage',
    _ => 'Elevator status unknown',
  };

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

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) ||
        summary.toLowerCase().contains(q) ||
        features.any((f) => f.toLowerCase().contains(q));
  }

  factory TransportOption.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TransportOption(
      id: doc.id,
      kind: (d['kind'] as String?) ?? 'transit',
      name: (d['name'] as String?) ?? 'Stop',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      summary: (d['summary'] as String?) ?? '',
      features: List<String>.from(d['features'] as List? ?? const []),
      stepFree: d['stepFree'] == true,
      elevatorStatus: (d['elevatorStatus'] as String?) ?? 'unknown',
      phone: (d['phone'] as String?) ?? '',
      spaces: (d['spaces'] as num?)?.toInt() ?? 0,
      verified: d['verified'] == true,
      apiHook: (d['apiHook'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'kind': kind,
    'name': name,
    'lat': lat,
    'lng': lng,
    'summary': summary,
    'features': features,
    'stepFree': stepFree,
    'elevatorStatus': elevatorStatus,
    'phone': phone,
    'spaces': spaces,
    'verified': verified,
    'apiHook': apiHook,
  };

  static double _rad(double d) => d * math.pi / 180;
}

class BarrierAlert {
  const BarrierAlert({
    required this.id,
    required this.title,
    required this.detail,
    required this.severity,
    required this.lat,
    required this.lng,
    required this.status,
    required this.createdAt,
    this.uid = '',
    this.placeName = '',
  });

  final String id;
  final String title;
  final String detail;

  /// low | medium | high
  final String severity;
  final double lat;
  final double lng;

  /// open | resolved
  final String status;
  final DateTime createdAt;
  final String uid;
  final String placeName;

  factory BarrierAlert.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return BarrierAlert(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Barrier',
      detail: (d['detail'] as String?) ?? '',
      severity: (d['severity'] as String?) ?? 'medium',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      status: (d['status'] as String?) ?? 'open',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      uid: (d['uid'] as String?) ?? '',
      placeName: (d['placeName'] as String?) ?? '',
    );
  }
}
