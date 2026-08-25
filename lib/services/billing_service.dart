import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/billing.dart';
import 'notification_service.dart';

class BillingService {
  BillingService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _db.collection('billingPlans');
  CollectionReference<Map<String, dynamic>> get _subs =>
      _db.collection('subscriptions');
  CollectionReference<Map<String, dynamic>> get _invoices =>
      _db.collection('invoices');

  CollectionReference<Map<String, dynamic>>? get _methods {
    final id = uid;
    if (id == null) return null;
    return _db.collection('users').doc(id).collection('paymentMethods');
  }

  Stream<List<BillingPlan>> watchPlans() {
    return _plans.snapshots().map((snap) {
      final list = snap.docs.map(BillingPlan.fromDoc).toList();
      list.sort((a, b) => a.amountCents.compareTo(b.amountCents));
      return list;
    });
  }

  Stream<BillingSubscription?> watchMySubscription() {
    final id = uid;
    if (id == null) return Stream.value(null);
    return _subs.where('uid', isEqualTo: id).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      final list = snap.docs.map(BillingSubscription.fromDoc).toList();
      list.sort((a, b) => b.periodEnd.compareTo(a.periodEnd));
      return list.first;
    });
  }

  Stream<List<Invoice>> watchMyInvoices() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _invoices.where('uid', isEqualTo: id).snapshots().map((snap) {
      final list = snap.docs.map(Invoice.fromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> ensureSeeded() async {
    final existing = await _plans.limit(1).get();
    if (existing.docs.isEmpty) {
      final batch = _db.batch();
      for (final p in seedPlans) {
        batch.set(_plans.doc(p.id), {...p.toMap(), 'seeded': true});
      }
      await batch.commit();
    }
    await ensureDefaultMethod();
  }

  Stream<List<SavedPaymentMethod>> watchMethods() {
    final col = _methods;
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(SavedPaymentMethod.fromDoc).toList();
      list.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.brand.compareTo(b.brand);
      });
      return list;
    });
  }

  Future<void> ensureDefaultMethod() async {
    final col = _methods;
    if (col == null) return;
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    await col.doc('sandbox-visa').set({
      'brand': 'Visa',
      'last4': '4242',
      'kind': 'card',
      'label': 'Sandbox Visa',
      'isDefault': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await col.doc('sandbox-wallet').set({
      'brand': 'Wallet',
      'last4': '0000',
      'kind': 'wallet',
      'label': 'Sandbox wallet',
      'isDefault': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addMethod({
    required String brand,
    required String last4,
    String kind = 'card',
    String label = '',
    bool isDefault = false,
  }) async {
    final col = _methods;
    if (col == null) throw StateError('Sign in required');
    final digits = last4.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) throw StateError('Enter the last 4 digits only');
    await col.doc().set({
      'brand': brand.trim().isEmpty ? 'Card' : brand.trim(),
      'last4': digits.substring(digits.length - 4),
      'kind': kind,
      'label': label.trim(),
      'isDefault': isDefault,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDefaultMethod(String id) async {
    final col = _methods;
    if (col == null) throw StateError('Sign in required');
    final all = await col.get();
    final batch = _db.batch();
    for (final d in all.docs) {
      batch.update(d.reference, {'isDefault': d.id == id});
    }
    await batch.commit();
  }

  Future<void> deleteMethod(String id) async {
    final col = _methods;
    if (col == null) throw StateError('Sign in required');
    await col.doc(id).delete();
  }

  Future<SavedPaymentMethod?> defaultMethod() async {
    await ensureDefaultMethod();
    final col = _methods;
    if (col == null) return null;
    final snap = await col.get();
    final list = snap.docs.map(SavedPaymentMethod.fromDoc).toList();
    if (list.isEmpty) return null;
    for (final m in list) {
      if (m.isDefault) return m;
    }
    return list.first;
  }

  Future<void> subscribe(BillingPlan plan) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to subscribe');
    final periodEnd = DateTime.now().add(
      Duration(days: plan.interval == 'year' ? 365 : 30),
    );
    final existing = await _subs
        .where('uid', isEqualTo: user.uid)
        .limit(1)
        .get();
    final subRef = existing.docs.isEmpty
        ? _subs.doc()
        : _subs.doc(existing.docs.first.id);
    await subRef.set({
      'uid': user.uid,
      'planId': plan.id,
      'planName': plan.name,
      'amountCents': plan.amountCents,
      'status': 'active',
      'periodEnd': Timestamp.fromDate(periodEnd),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _invoices.doc().set({
      'uid': user.uid,
      'type': 'subscription',
      'description': '${plan.name} · ${plan.interval}',
      'amountCents': plan.amountCents,
      'status': 'due',
      'relatedId': plan.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelSubscription(String id) async {
    await _subs.doc(id).update({
      'status': 'canceled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Test gateway — no card numbers are collected or stored.
  Future<void> payInvoice(String invoiceId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to pay');
    final snap = await _invoices.doc(invoiceId).get();
    final data = snap.data() ?? {};
    final method = await defaultMethod();
    await _invoices.doc(invoiceId).update({
      'status': 'paid',
      'gateway': 'abilitylink_test',
      'last4': method?.last4 ?? '4242',
      'methodBrand': method?.brand ?? 'Visa',
      'paidAt': FieldValue.serverTimestamp(),
    });
    await NotificationService(db: _db, auth: _auth).notifyPayment(
      uid: user.uid,
      description: (data['description'] as String?) ?? 'Invoice',
      amountCents: (data['amountCents'] as num?)?.toInt() ?? 0,
      invoiceId: invoiceId,
    );
  }

  Future<void> refundInvoice(String invoiceId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in required');
    final doc = await _invoices.doc(invoiceId).get();
    if (!doc.exists || doc.data()?['uid'] != user.uid) {
      throw StateError('Invoice not found');
    }
    final status = doc.data()?['status'];
    if (status != 'paid') {
      throw StateError('Only paid invoices can be refunded');
    }
    await _invoices.doc(invoiceId).update({
      'status': 'refunded',
      'refundedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await NotificationService(db: _db, auth: _auth).notifyPayment(
      uid: user.uid,
      description: (doc.data()?['description'] as String?) ?? 'Invoice',
      amountCents: (doc.data()?['amountCents'] as num?)?.toInt() ?? 0,
      invoiceId: invoiceId,
      title: 'Refund issued',
    );
  }

  Future<String> payService({
    required String type,
    required String description,
    required int amountCents,
    String relatedId = '',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to pay');
    final method = await defaultMethod();
    final cents = amountCents <= 0 ? 2500 : amountCents;
    final ref = _invoices.doc();
    await ref.set({
      'uid': user.uid,
      'type': type,
      'description': description,
      'amountCents': cents,
      'status': 'paid',
      'gateway': 'abilitylink_test',
      'last4': method?.last4 ?? '4242',
      'methodBrand': method?.brand ?? 'Visa',
      'relatedId': relatedId,
      'paidAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService(db: _db, auth: _auth).notifyPayment(
      uid: user.uid,
      description: description,
      amountCents: cents,
      invoiceId: ref.id,
    );
    return ref.id;
  }

  Future<void> recordLeadFee({
    required String ownerUid,
    required String providerName,
    required String enquiryId,
  }) async {
    if (ownerUid.isEmpty) return;
    final sub = await _subs.where('uid', isEqualTo: ownerUid).limit(1).get();
    if (sub.docs.isNotEmpty) {
      final s = BillingSubscription.fromDoc(sub.docs.first);
      if (s.isActive && s.planId == 'provider-growth') return;
    }
    await recordCharge(
      uid: ownerUid,
      type: 'lead_fee',
      description: 'Lead fee · $providerName',
      amountCents: 500,
      relatedId: enquiryId,
    );
  }

  Future<void> recordSessionCommission({
    required String ownerUid,
    required String providerName,
    required String appointmentId,
  }) async {
    if (ownerUid.isEmpty) return;
    await recordCharge(
      uid: ownerUid,
      type: 'commission',
      description: '8% session commission · $providerName',
      amountCents: 320,
      relatedId: appointmentId,
    );
  }

  Future<void> recordCharge({
    required String uid,
    required String type,
    required String description,
    required int amountCents,
    String relatedId = '',
    String status = 'due',
  }) async {
    if (uid.isEmpty || amountCents <= 0) return;
    await _invoices.doc().set({
      'uid': uid,
      'createdBy': _auth.currentUser?.uid ?? uid,
      'type': type,
      'description': description,
      'amountCents': amountCents,
      'status': status,
      'relatedId': relatedId,
      if (status == 'paid') ...{
        'gateway': 'abilitylink_test',
        'last4': '4242',
        'paidAt': FieldValue.serverTimestamp(),
      },
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (status == 'paid') {
      await NotificationService(db: _db, auth: _auth).notifyPayment(
        uid: uid,
        description: description,
        amountCents: amountCents,
        invoiceId: relatedId.isEmpty ? type : relatedId,
      );
    }
  }

  /// Sandbox checkout for Assistance Marketplace bookings (no card capture).
  Future<String> payAssistanceBooking({
    required String bookingId,
    required String providerName,
    required int amountCents,
    String currency = '\$',
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to pay');
    final method = await defaultMethod();
    final ref = _invoices.doc();
    await ref.set({
      'uid': user.uid,
      'type': 'assistance_booking',
      'description': 'Assistance · $providerName',
      'amountCents': amountCents,
      'currency': currency,
      'status': 'paid',
      'gateway': 'abilitylink_test',
      'last4': method?.last4 ?? '4242',
      'methodBrand': method?.brand ?? 'Visa',
      'relatedId': bookingId,
      'paidAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService(db: _db, auth: _auth).notifyPayment(
      uid: user.uid,
      description: 'Assistance · $providerName',
      amountCents: amountCents,
      invoiceId: ref.id,
    );
    return ref.id;
  }
}

const seedPlans = <BillingPlan>[
  BillingPlan(
    id: 'consumer-plus',
    name: 'Ability Plus',
    audience: 'consumer',
    amountCents: 499,
    interval: 'month',
    summary: 'Priority AI answers and saved-search alerts.',
    features: ['Priority support', 'Saved-search alerts', 'Ad-light map'],
  ),
  BillingPlan(
    id: 'provider-starter',
    name: 'Provider Starter',
    audience: 'provider',
    amountCents: 2900,
    interval: 'month',
    summary: 'Listing + 10 included leads, then \$5 per extra lead.',
    features: ['Public listing', '10 leads included', '\$5 extra lead fee'],
  ),
  BillingPlan(
    id: 'provider-growth',
    name: 'Provider Growth',
    audience: 'provider',
    amountCents: 7900,
    interval: 'month',
    summary: 'Unlimited leads and featured placement.',
    features: ['Unlimited leads', 'Featured directory', 'Analytics export'],
  ),
  BillingPlan(
    id: 'employer-saas',
    name: 'Employer SaaS',
    audience: 'employer',
    amountCents: 9900,
    interval: 'month',
    summary: 'Inclusive hiring workspace and accommodation tracking.',
    features: ['Unlimited jobs', 'Candidate matching', 'KPI dashboard'],
  ),
];
