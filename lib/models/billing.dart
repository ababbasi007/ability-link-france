import 'package:cloud_firestore/cloud_firestore.dart';

class BillingPlan {
  const BillingPlan({
    required this.id,
    required this.name,
    required this.audience,
    required this.amountCents,
    required this.interval,
    required this.summary,
    required this.features,
  });

  final String id;
  final String name;

  /// consumer | provider | employer
  final String audience;
  final int amountCents;
  final String interval;
  final String summary;
  final List<String> features;

  String get priceLabel {
    final dollars = amountCents / 100;
    final n = dollars.truncateToDouble() == dollars
        ? dollars.toInt().toString()
        : dollars.toStringAsFixed(2);
    return '\$$n/${interval == 'year' ? 'yr' : 'mo'}';
  }

  factory BillingPlan.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BillingPlan(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Plan',
      audience: (d['audience'] as String?) ?? 'consumer',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      interval: (d['interval'] as String?) ?? 'month',
      summary: (d['summary'] as String?) ?? '',
      features: List<String>.from(d['features'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'audience': audience,
    'amountCents': amountCents,
    'interval': interval,
    'summary': summary,
    'features': features,
  };
}

class BillingSubscription {
  const BillingSubscription({
    required this.id,
    required this.uid,
    required this.planId,
    required this.planName,
    required this.amountCents,
    required this.status,
    required this.periodEnd,
  });

  final String id;
  final String uid;
  final String planId;
  final String planName;
  final int amountCents;
  final String status;
  final DateTime periodEnd;

  bool get isActive => status == 'active' && periodEnd.isAfter(DateTime.now());

  factory BillingSubscription.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final ts = d['periodEnd'];
    return BillingSubscription(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      planId: (d['planId'] as String?) ?? '',
      planName: (d['planName'] as String?) ?? '',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      status: (d['status'] as String?) ?? 'canceled',
      periodEnd: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

class Invoice {
  const Invoice({
    required this.id,
    required this.uid,
    required this.type,
    required this.description,
    required this.amountCents,
    required this.status,
    required this.createdAt,
    this.relatedId = '',
    this.gateway = '',
    this.last4 = '',
  });

  final String id;
  final String uid;

  /// subscription | lead_fee | commission
  final String type;
  final String description;
  final int amountCents;
  final String status;
  final DateTime createdAt;
  final String relatedId;
  final String gateway;
  final String last4;

  String get amountLabel => '\$${(amountCents / 100).toStringAsFixed(2)}';

  String get receiptNumber =>
      'AL-${createdAt.year}${createdAt.month.toString().padLeft(2, '0')}-${id.length >= 6 ? id.substring(0, 6).toUpperCase() : id.toUpperCase()}';

  String receiptText() {
    final paid = status == 'paid' || status == 'refunded';
    return [
      'Ability Link receipt',
      'Receipt $receiptNumber',
      description,
      'Type: $type',
      'Amount: $amountLabel',
      'Status: $status',
      if (gateway.isNotEmpty) 'Gateway: $gateway (sandbox)',
      if (last4.isNotEmpty) 'Method: ••$last4',
      'Date: ${createdAt.toLocal()}',
      if (relatedId.isNotEmpty) 'Reference: $relatedId',
      paid
          ? 'This is a sandbox receipt — no live card charge.'
          : 'Amount due (sandbox).',
    ].join('\n');
  }

  factory Invoice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return Invoice(
      id: doc.id,
      uid: (d['uid'] as String?) ?? '',
      type: (d['type'] as String?) ?? 'subscription',
      description: (d['description'] as String?) ?? '',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      status: (d['status'] as String?) ?? 'due',
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      relatedId: (d['relatedId'] as String?) ?? '',
      gateway: (d['gateway'] as String?) ?? '',
      last4: (d['last4'] as String?) ?? '',
    );
  }
}

class SavedPaymentMethod {
  const SavedPaymentMethod({
    required this.id,
    required this.brand,
    required this.last4,
    required this.kind,
    this.label = '',
    this.isDefault = false,
  });

  final String id;
  final String brand;
  final String last4;

  /// card | wallet
  final String kind;
  final String label;
  final bool isDefault;

  String get displayLabel {
    if (label.trim().isNotEmpty) return label;
    if (kind == 'wallet') return '$brand wallet ••$last4';
    return '$brand ••$last4';
  }

  factory SavedPaymentMethod.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return SavedPaymentMethod(
      id: doc.id,
      brand: (d['brand'] as String?) ?? 'Card',
      last4: (d['last4'] as String?) ?? '4242',
      kind: (d['kind'] as String?) ?? 'card',
      label: (d['label'] as String?) ?? '',
      isDefault: d['isDefault'] == true,
    );
  }
}
