import 'package:cloud_firestore/cloud_firestore.dart';

class CareMember {
  const CareMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.permissions,
    this.colorValue = 0xFF6C63FF,
    this.phone = '',
    this.role = 'family',
    this.providerId = '',
    this.bio = '',
    this.availableNow = false,
    this.verified = false,
  });

  final String id;
  final String name;
  final String relation;
  final List<String> permissions;
  final int colorValue;
  final String phone;

  /// family | professional
  final String role;
  final String providerId;
  final String bio;
  final bool availableNow;
  final bool verified;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  bool has(String key) => permissions.contains(key);
  bool get isProfessional => role == 'professional';

  factory CareMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return CareMember(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Member',
      relation: (d['relation'] as String?) ?? '',
      permissions: List<String>.from(d['permissions'] as List? ?? const []),
      colorValue: (d['colorValue'] as num?)?.toInt() ?? 0xFF6C63FF,
      phone: (d['phone'] as String?) ?? '',
      role: (d['role'] as String?) ?? 'family',
      providerId: (d['providerId'] as String?) ?? '',
      bio: (d['bio'] as String?) ?? '',
      availableNow: d['availableNow'] == true,
      verified: d['verified'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'relation': relation,
    'permissions': permissions,
    'colorValue': colorValue,
    'phone': phone,
    'role': role,
    'providerId': providerId,
    'bio': bio,
    'availableNow': availableNow,
    'verified': verified,
  };
}

class CareTask {
  const CareTask({
    required this.id,
    required this.title,
    required this.personName,
    required this.timeLabel,
    required this.kind,
    required this.status,
    this.notes = '',
    this.completedAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String personName;
  final String timeLabel;

  /// meds | task | appointment | assistance
  final String kind;
  final String status;
  final String notes;
  final DateTime? completedAt;
  final DateTime? createdAt;

  bool get isDone => status == 'done';

  factory CareTask.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final doneTs = d['completedAt'];
    final createdTs = d['createdAt'];
    return CareTask(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Task',
      personName: (d['personName'] as String?) ?? '',
      timeLabel: (d['timeLabel'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'task',
      status: (d['status'] as String?) ?? 'pending',
      notes: (d['notes'] as String?) ?? '',
      completedAt: doneTs is Timestamp ? doneTs.toDate() : null,
      createdAt: createdTs is Timestamp ? createdTs.toDate() : null,
    );
  }
}

class CareNote {
  const CareNote({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    required this.createdAt,
    this.personName = '',
    this.kind = 'general',
  });

  final String id;
  final String title;
  final String body;
  final String author;
  final DateTime createdAt;
  final String personName;

  /// general | meds | visit | incident | assistance
  final String kind;

  factory CareNote.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return CareNote(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Note',
      body: (d['body'] as String?) ?? '',
      author: (d['author'] as String?) ?? 'Caregiver',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      personName: (d['personName'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'general',
    );
  }
}

class CareHistoryEvent {
  const CareHistoryEvent({
    required this.id,
    required this.title,
    required this.detail,
    required this.kind,
    required this.createdAt,
    this.relatedId = '',
  });

  final String id;
  final String title;
  final String detail;

  /// task | note | hire | message | meds | appointment
  final String kind;
  final DateTime createdAt;
  final String relatedId;

  factory CareHistoryEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return CareHistoryEvent(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Event',
      detail: (d['detail'] as String?) ?? '',
      kind: (d['kind'] as String?) ?? 'task',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      relatedId: (d['relatedId'] as String?) ?? '',
    );
  }
}

class CareMessage {
  const CareMessage({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    this.uid = '',
  });

  final String id;
  final String author;
  final String body;
  final DateTime createdAt;
  final String uid;

  factory CareMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return CareMessage(
      id: doc.id,
      author: (d['author'] as String?) ?? 'Member',
      body: (d['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      uid: (d['uid'] as String?) ?? '',
    );
  }
}

class CareHireRequest {
  const CareHireRequest({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.service,
    required this.scheduleLabel,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.phone = '',
    this.paymentStatus = 'unpaid',
    this.invoiceId = '',
    this.amountCents = 0,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String service;
  final String scheduleLabel;
  final String notes;

  /// requested | accepted | declined | completed | cancelled
  final String status;
  final DateTime createdAt;
  final String phone;
  final String paymentStatus;
  final String invoiceId;
  final int amountCents;

  factory CareHireRequest.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return CareHireRequest(
      id: doc.id,
      providerId: (d['providerId'] as String?) ?? '',
      providerName: (d['providerName'] as String?) ?? '',
      service: (d['service'] as String?) ?? 'Personal assistance',
      scheduleLabel: (d['scheduleLabel'] as String?) ?? '',
      notes: (d['notes'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'requested',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      phone: (d['phone'] as String?) ?? '',
      paymentStatus: (d['paymentStatus'] as String?) ?? 'unpaid',
      invoiceId: (d['invoiceId'] as String?) ?? '',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
    );
  }
}
