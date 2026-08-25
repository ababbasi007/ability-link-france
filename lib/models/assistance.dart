import 'package:cloud_firestore/cloud_firestore.dart';

class AssistanceBooking {
  const AssistanceBooking({
    required this.id,
    required this.uid,
    required this.providerId,
    required this.providerName,
    required this.assistanceType,
    required this.service,
    required this.startAt,
    required this.durationMin,
    required this.mode,
    required this.status,
    required this.priceCents,
    required this.currency,
    required this.paymentStatus,
    required this.createdAt,
    this.notes = '',
    this.photoUrl = '',
    this.city = '',
    this.invoiceId = '',
  });

  final String id;
  final String uid;
  final String providerId;
  final String providerName;
  final String assistanceType;
  final String service;
  final DateTime startAt;
  final int durationMin;

  /// in_person | remote_video | remote_chat
  final String mode;

  /// booked | completed | cancelled
  final String status;
  final int priceCents;
  final String currency;

  /// unpaid | paid | refunded | sandbox
  final String paymentStatus;
  final DateTime createdAt;
  final String notes;
  final String photoUrl;
  final String city;
  final String invoiceId;

  bool get isUpcoming =>
      status == 'booked' &&
      startAt.isAfter(DateTime.now().subtract(const Duration(hours: 1)));

  String get priceLabel {
    final amount = priceCents / 100;
    return '$currency${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}';
  }

  String get modeLabel => switch (mode) {
    'remote_video' => 'Video',
    'remote_chat' => 'Chat',
    _ => 'In person',
  };

  factory AssistanceBooking.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final start = d['startAt'];
    final created = d['createdAt'];
    return AssistanceBooking(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      providerId: (d['providerId'] as String?) ?? '',
      providerName: (d['providerName'] as String?) ?? '',
      assistanceType: (d['assistanceType'] as String?) ?? '',
      service: (d['service'] as String?) ?? '',
      startAt: start is Timestamp ? start.toDate() : DateTime.now(),
      durationMin: (d['durationMin'] as num?)?.toInt() ?? 60,
      mode: (d['mode'] as String?) ?? 'in_person',
      status: (d['status'] as String?) ?? 'booked',
      priceCents: (d['priceCents'] as num?)?.toInt() ?? 0,
      currency: (d['currency'] as String?) ?? '\$',
      paymentStatus: (d['paymentStatus'] as String?) ?? 'unpaid',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      notes: (d['notes'] as String?) ?? '',
      photoUrl: (d['photoUrl'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      invoiceId: (d['invoiceId'] as String?) ?? '',
    );
  }
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.author,
    required this.body,
    required this.createdAt,
    this.uid = '',
    this.fromProvider = false,
  });

  final String id;
  final String author;
  final String body;
  final DateTime createdAt;
  final String uid;
  final bool fromProvider;

  factory AssistantMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return AssistantMessage(
      id: doc.id,
      author: (d['author'] as String?) ?? 'You',
      body: (d['body'] as String?) ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      uid: (d['uid'] as String?) ?? '',
      fromProvider: d['fromProvider'] == true,
    );
  }
}

class AssistantReport {
  const AssistantReport({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.reason,
    required this.detail,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String reason;
  final String detail;
  final String status;
  final DateTime createdAt;

  factory AssistantReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return AssistantReport(
      id: doc.id,
      providerId: (d['providerId'] as String?) ?? '',
      providerName: (d['providerName'] as String?) ?? '',
      reason: (d['reason'] as String?) ?? '',
      detail: (d['detail'] as String?) ?? '',
      status: (d['status'] as String?) ?? 'open',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
