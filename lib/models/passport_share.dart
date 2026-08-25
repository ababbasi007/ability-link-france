import 'package:cloud_firestore/cloud_firestore.dart';

class PassportShare {
  const PassportShare({
    required this.id,
    required this.ownerUid,
    required this.fields,
    required this.status,
    required this.snapshot,
    required this.createdAt,
    this.expiresAt,
    this.accessCount = 0,
    this.lastViewer = '',
    this.consent = false,
  });

  final String id;
  final String ownerUid;
  final List<String> fields;
  final String status;
  final Map<String, dynamic> snapshot;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final int accessCount;
  final String lastViewer;
  final bool consent;

  bool get isActive {
    if (status != 'active') return false;
    if (expiresAt != null && expiresAt!.isBefore(DateTime.now())) return false;
    return true;
  }

  String get shareCode => id.toUpperCase();

  String get shareLink => 'abilitylink://passport/$id';

  factory PassportShare.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final created = d['createdAt'];
    final expires = d['expiresAt'];
    return PassportShare(
      id: doc.id,
      ownerUid: (d['ownerUid'] as String?) ?? '',
      fields: List<String>.from(d['fields'] as List? ?? const []),
      status: (d['status'] as String?) ?? 'revoked',
      snapshot: Map<String, dynamic>.from(d['snapshot'] as Map? ?? const {}),
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      expiresAt: expires is Timestamp ? expires.toDate() : null,
      accessCount: (d['accessCount'] as num?)?.toInt() ?? 0,
      lastViewer: (d['lastViewer'] as String?) ?? '',
      consent: d['consent'] == true,
    );
  }
}

class PassportAccessEvent {
  const PassportAccessEvent({
    required this.id,
    required this.shareId,
    required this.action,
    required this.createdAt,
    this.viewerName = '',
  });

  final String id;
  final String shareId;
  final String action;
  final DateTime createdAt;
  final String viewerName;

  factory PassportAccessEvent.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return PassportAccessEvent(
      id: doc.id,
      shareId: (d['shareId'] as String?) ?? '',
      action: (d['action'] as String?) ?? 'view',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      viewerName: (d['viewerName'] as String?) ?? '',
    );
  }
}
