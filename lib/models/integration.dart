import 'package:cloud_firestore/cloud_firestore.dart';

class IntegrationItem {
  const IntegrationItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.status,
    required this.endpoint,
    required this.notes,
    this.lastCheckedAt,
  });

  final String id;
  final String name;
  final String kind;
  final String status; // live | sandbox | fallback | planned
  final String endpoint;
  final String notes;
  final DateTime? lastCheckedAt;

  factory IntegrationItem.fromMap(Map<String, dynamic> d) {
    final ts = d['lastCheckedAt'];
    return IntegrationItem(
      id: (d['id'] as String?) ?? '',
      name: (d['name'] as String?) ?? 'Integration',
      kind: (d['kind'] as String?) ?? 'other',
      status: (d['status'] as String?) ?? 'planned',
      endpoint: (d['endpoint'] as String?) ?? '',
      notes: (d['notes'] as String?) ?? '',
      lastCheckedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'kind': kind,
    'status': status,
    'endpoint': endpoint,
    'notes': notes,
    if (lastCheckedAt != null)
      'lastCheckedAt': Timestamp.fromDate(lastCheckedAt!),
  };
}

class ApiKeyRecord {
  const ApiKeyRecord({
    required this.id,
    required this.uid,
    required this.prefix,
    required this.tokenHash,
    required this.createdAt,
    this.revoked = false,
    this.lastUsedAt,
  });

  final String id;
  final String uid;
  final String prefix;
  final String tokenHash;
  final DateTime createdAt;
  final bool revoked;
  final DateTime? lastUsedAt;

  factory ApiKeyRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final created = d['createdAt'];
    final used = d['lastUsedAt'];
    return ApiKeyRecord(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      prefix: (d['prefix'] as String?) ?? '',
      tokenHash: (d['tokenHash'] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      revoked: d['revoked'] == true,
      lastUsedAt: used is Timestamp ? used.toDate() : null,
    );
  }
}

class OpenDataBundle {
  const OpenDataBundle({
    required this.kind,
    required this.featureCount,
    required this.json,
    this.updatedAt,
  });

  final String kind;
  final int featureCount;
  final String json;
  final DateTime? updatedAt;
}
