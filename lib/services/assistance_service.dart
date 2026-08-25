import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/assistance_taxonomy.dart';
import '../models/assistance.dart';
import '../models/service_provider.dart';
import 'billing_service.dart';
import 'notification_service.dart';
import 'providers_service.dart';

class AssistanceService {
  AssistanceService({
    FirebaseFirestore? db,
    FirebaseAuth? auth,
    ProvidersService? providers,
    BillingService? billing,
  }) : _db = db ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _providers = providers ?? ProvidersService(),
       _billing = billing ?? BillingService();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final ProvidersService _providers;
  final BillingService _billing;

  String? get uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('assistanceBookings');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('assistantReports');

  DocumentReference<Map<String, dynamic>> _thread(String providerId) {
    final id = uid;
    if (id == null) throw StateError('Sign in required');
    return _db
        .collection('users')
        .doc(id)
        .collection('assistantThreads')
        .doc(providerId);
  }

  CollectionReference<Map<String, dynamic>> _messages(String providerId) {
    return _thread(providerId).collection('messages');
  }

  Stream<List<ServiceProvider>> watchAssistants() {
    return _providers.watchProviders().map(
      (all) => all.where((p) => p.isAssistance).toList(),
    );
  }

  List<ServiceProvider> filterAssistants(
    List<ServiceProvider> all, {
    String query = '',
    String assistanceType = '',
    String city = '',
    bool availableNowOnly = false,
    bool verifiedOnly = false,
    int? maxPrice,
    int? minPrice,
  }) {
    var list = all.where((p) {
      if (!p.isAssistance) return false;
      if (!p.matchesQuery(query)) return false;
      if (!p.matchesAssistanceType(assistanceType)) return false;
      if (city.isNotEmpty &&
          !p.city.toLowerCase().contains(city.trim().toLowerCase())) {
        return false;
      }
      if (availableNowOnly && !p.availableNow) return false;
      if (verifiedOnly && !p.verified) return false;
      if (minPrice != null && p.priceFrom < minPrice) return false;
      if (maxPrice != null && p.priceFrom > maxPrice) return false;
      return true;
    }).toList();
    list.sort((a, b) {
      if (a.availableNow != b.availableNow) return a.availableNow ? -1 : 1;
      if (a.verified != b.verified) return a.verified ? -1 : 1;
      return b.rating.compareTo(a.rating);
    });
    return list;
  }

  List<String> citiesFrom(List<ServiceProvider> all) {
    final set = <String>{};
    for (final p in all.where((p) => p.isAssistance)) {
      if (p.city.trim().isNotEmpty) set.add(p.city.trim());
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<String> bookAssistance({
    required ServiceProvider provider,
    required DateTime startAt,
    required String mode,
    required String service,
    String notes = '',
    int durationMin = 60,
    bool payNow = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to book assistance');
    final priceCents = provider.priceFrom * 100;
    final ref = _bookings.doc();
    var paymentStatus = 'unpaid';
    var invoiceId = '';
    if (payNow) {
      invoiceId = await _billing.payAssistanceBooking(
        bookingId: ref.id,
        providerName: provider.name,
        amountCents: priceCents,
        currency: provider.currency,
      );
      paymentStatus = 'paid';
    }
    await ref.set({
      'uid': user.uid,
      'providerId': provider.id,
      'providerName': provider.name,
      'assistanceType': provider.assistanceType,
      'service': service.trim().isEmpty
          ? (provider.services.isNotEmpty
                ? provider.services.first
                : assistanceTypeLabel(provider.assistanceType))
          : service.trim(),
      'startAt': Timestamp.fromDate(startAt),
      'durationMin': durationMin,
      'mode': mode,
      'status': 'booked',
      'priceCents': priceCents,
      'currency': provider.currency,
      'paymentStatus': paymentStatus,
      'invoiceId': invoiceId,
      'notes': notes.trim(),
      'photoUrl': provider.photoUrl,
      'city': provider.city,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (provider.ownerUid.isNotEmpty) {
      await _billing.recordSessionCommission(
        ownerUid: provider.ownerUid,
        providerName: provider.name,
        appointmentId: ref.id,
      );
    }
    // Seed a thread welcome so messaging is ready.
    await _thread(provider.id).set({
      'providerId': provider.id,
      'providerName': provider.name,
      'photoUrl': provider.photoUrl,
      'assistanceType': provider.assistanceType,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': 'Booking confirmed for ${startAt.toLocal()}',
    }, SetOptions(merge: true));
    await _messages(provider.id).doc().set({
      'author': 'Ability Link',
      'body':
          'Your assistance booking with ${provider.name} is confirmed'
          '${payNow ? ' and paid (sandbox).' : '.'} Message here anytime.',
      'uid': '',
      'fromProvider': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await NotificationService(db: _db, auth: _auth).notifyBooking(
      patientUid: user.uid,
      providerName: provider.name,
      appointmentId: ref.id,
      ownerUid: provider.ownerUid,
      kind: 'assistance',
    );
    return ref.id;
  }

  Stream<List<AssistanceBooking>> watchMyBookings() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _bookings.where('uid', isEqualTo: id).snapshots().map((snap) {
      final list = snap.docs.map(AssistanceBooking.fromDoc).toList();
      list.sort((a, b) => b.startAt.compareTo(a.startAt));
      return list;
    });
  }

  Future<void> cancelBooking(String id) async {
    await _bookings.doc(id).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> ensureThread({required ServiceProvider provider}) async {
    await _thread(provider.id).set({
      'providerId': provider.id,
      'providerName': provider.name,
      'photoUrl': provider.photoUrl,
      'assistanceType': provider.assistanceType,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<AssistantMessage>> watchMessages(String providerId) {
    if (uid == null) return Stream.value(const []);
    return _messages(providerId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(AssistantMessage.fromDoc).toList());
  }

  Future<void> sendMessage({
    required String providerId,
    required String body,
    String author = 'You',
  }) async {
    final text = body.trim();
    if (text.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to message');
    await _messages(providerId).doc().set({
      'author': author,
      'body': text,
      'uid': user.uid,
      'fromProvider': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _thread(providerId).set({
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final provider = await _providers.getProvider(providerId);
    final owner = provider?.ownerUid ?? '';
    if (owner.isNotEmpty) {
      await NotificationService(db: _db, auth: _auth).notifyMessage(
        uid: owner,
        title: 'New assistance message',
        body: text,
        relatedId: providerId,
      );
    }
  }

  Stream<List<Map<String, dynamic>>> watchThreads() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return _db
        .collection('users')
        .doc(id)
        .collection('assistantThreads')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return {'id': d.id, ...data};
          }).toList(),
        );
  }

  Future<String> reportAssistant({
    required ServiceProvider provider,
    required String reason,
    required String detail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to report');
    final ref = _reports.doc();
    await ref.set({
      'uid': user.uid,
      'userEmail': user.email ?? '',
      'providerId': provider.id,
      'providerName': provider.name,
      'reason': reason.trim(),
      'detail': detail.trim(),
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db
        .collection('users')
        .doc(user.uid)
        .collection('assistantReports')
        .doc(ref.id)
        .set({
          'reportId': ref.id,
          'providerId': provider.id,
          'providerName': provider.name,
          'reason': reason.trim(),
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
    return ref.id;
  }

  List<DateTime> scheduleSlotsFor(ServiceProvider provider) {
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day, 9);
    final slots = <DateTime>[];
    for (var d = 0; d < 7; d++) {
      for (final hour in [9, 11, 14, 16]) {
        final slot = base.add(Duration(days: d, hours: hour - 9));
        if (slot.isAfter(now.add(const Duration(hours: 1)))) {
          slots.add(slot);
        }
      }
    }
    if (provider.availabilitySlots.isNotEmpty && slots.length > 8) {
      return slots.take(8).toList();
    }
    return slots.take(12).toList();
  }
}
