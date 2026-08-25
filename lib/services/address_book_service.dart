import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.line1,
    required this.city,
    required this.postalCode,
    required this.country,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final String line1;
  final String city;
  final String postalCode;
  final String country;
  final bool isDefault;

  String get summary => [
    line1,
    city,
    postalCode,
    country,
  ].where((s) => s.trim().isNotEmpty).join(', ');

  factory SavedAddress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SavedAddress(
      id: doc.id,
      label: (d['label'] as String?) ?? 'Home',
      line1: (d['line1'] as String?) ?? '',
      city: (d['city'] as String?) ?? '',
      postalCode: (d['postalCode'] as String?) ?? '',
      country: (d['country'] as String?) ?? '',
      isDefault: d['isDefault'] == true,
    );
  }
}

class AddressBookService {
  AddressBookService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('savedAddresses');
  }

  Stream<List<SavedAddress>> watch() {
    final col = _col;
    if (col == null) return Stream.value(const []);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(SavedAddress.fromDoc).toList();
      list.sort((a, b) {
        if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
        return a.label.compareTo(b.label);
      });
      return list;
    });
  }

  Future<void> seedFromProfile({
    required String address,
    required String city,
    required String postalCode,
    required String country,
  }) async {
    final col = _col;
    if (col == null) return;
    if (address.trim().isEmpty && city.trim().isEmpty) return;
    final existing = await col.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    await col.doc('primary').set({
      'label': 'Home',
      'line1': address.trim(),
      'city': city.trim(),
      'postalCode': postalCode.trim(),
      'country': country.trim(),
      'isDefault': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> save({
    String? id,
    required String label,
    required String line1,
    required String city,
    required String postalCode,
    required String country,
    bool isDefault = false,
  }) async {
    final col = _col;
    final uid = _auth.currentUser?.uid;
    if (col == null || uid == null) throw StateError('Sign in required');
    final ref = id == null ? col.doc() : col.doc(id);
    await ref.set({
      'label': label.trim().isEmpty ? 'Address' : label.trim(),
      'line1': line1.trim(),
      'city': city.trim(),
      'postalCode': postalCode.trim(),
      'country': country.trim(),
      'isDefault': isDefault,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (isDefault) {
      await _db.collection('users').doc(uid).set({
        'contact': {
          'address': line1.trim(),
          'city': city.trim(),
          'postalCode': postalCode.trim(),
          'country': country.trim(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> delete(String id) async {
    final col = _col;
    if (col == null) throw StateError('Sign in required');
    await col.doc(id).delete();
  }
}
