import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class TrustedContact {
  const TrustedContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation = '',
    this.isPrimary = false,
    this.linkedUid = '',
  });

  final String id;
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;
  final String linkedUid;

  factory TrustedContact.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return TrustedContact(
      id: doc.id,
      name: (d['name'] as String?) ?? '',
      phone: (d['phone'] as String?) ?? '',
      relation: (d['relation'] as String?) ?? '',
      isPrimary: d['isPrimary'] == true,
      linkedUid: (d['linkedUid'] as String?) ?? '',
    );
  }
}

class SosAlert {
  const SosAlert({
    required this.id,
    required this.uid,
    required this.lat,
    required this.lng,
    required this.message,
    required this.createdAt,
    this.status = 'open',
    this.mapsUrl = '',
    this.medical = const {},
    this.accessibility = const {},
    this.contactNames = const [],
    this.notifiedUids = const [],
  });

  final String id;
  final String uid;
  final double lat;
  final double lng;
  final String message;
  final DateTime createdAt;
  final String status;
  final String mapsUrl;
  final Map<String, dynamic> medical;
  final Map<String, dynamic> accessibility;
  final List<String> contactNames;
  final List<String> notifiedUids;

  factory SosAlert.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    Map<String, dynamic> asMap(dynamic v) {
      if (v is Map) return Map<String, dynamic>.from(v);
      return {};
    }

    return SosAlert(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      message: (d['message'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      status: (d['status'] as String?) ?? 'open',
      mapsUrl: (d['mapsUrl'] as String?) ?? '',
      medical: asMap(d['medical']),
      accessibility: asMap(d['accessibility']),
      contactNames: ((d['contactNames'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
      notifiedUids: ((d['notifiedUids'] as List?) ?? const [])
          .map((e) => '$e')
          .toList(),
    );
  }
}

class LocationSharePin {
  const LocationSharePin({
    required this.id,
    required this.uid,
    required this.lat,
    required this.lng,
    required this.expiresAt,
    required this.status,
  });

  final String id;
  final String uid;
  final double lat;
  final double lng;
  final DateTime expiresAt;
  final String status;

  bool get isActive => status == 'active' && expiresAt.isAfter(DateTime.now());

  String get mapsUrl => 'https://maps.google.com/?q=$lat,$lng';

  factory LocationSharePin.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final exp = d['expiresAt'];
    return LocationSharePin(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      expiresAt: exp is Timestamp ? exp.toDate() : DateTime.now(),
      status: (d['status'] as String?) ?? 'revoked',
    );
  }
}

class EmergencyResource {
  const EmergencyResource({
    required this.id,
    required this.name,
    required this.kind,
    required this.phone,
    required this.summary,
    required this.lat,
    required this.lng,
    this.stepFree = false,
    this.country = 'US',
  });

  final String id;
  final String name;
  final String kind;
  final String phone;
  final String summary;
  final double lat;
  final double lng;
  final bool stepFree;
  final String country;

  double distanceKm(double fromLat, double fromLng) {
    const earth = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat - fromLat);
    final dLng = rad(lng - fromLng);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(fromLat)) *
            math.cos(rad(lat)) *
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

  factory EmergencyResource.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return EmergencyResource(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Resource',
      kind: (d['kind'] as String?) ?? 'other',
      phone: (d['phone'] as String?) ?? '',
      summary: (d['summary'] as String?) ?? '',
      lat: (d['lat'] as num?)?.toDouble() ?? 0,
      lng: (d['lng'] as num?)?.toDouble() ?? 0,
      stepFree: d['stepFree'] == true,
      country: (d['country'] as String?)?.trim().isNotEmpty == true
          ? d['country'] as String
          : 'US',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'kind': kind,
    'phone': phone,
    'summary': summary,
    'lat': lat,
    'lng': lng,
    'stepFree': stepFree,
    'country': country,
  };
}
