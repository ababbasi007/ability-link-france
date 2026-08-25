import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_profile.dart';
import '../screens/signup/signup_data.dart';
import 'address_book_service.dart';
import 'biometric_lock_service.dart';
import 'push_service.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  bool _googleReady = false;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  DocumentReference<Map<String, dynamic>> userDoc(String uid) =>
      _db.collection('users').doc(uid);

  Future<void> _ensureGoogle() async {
    if (_googleReady) return;
    // Web client ID from Firebase Auth → Google provider (required on Android).
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '70258044409-2u2bdrhf1nsapha4k3311jemc0m0lk6n.apps.googleusercontent.com',
    );
    _googleReady = true;
  }

  Future<UserCredential> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    String? role,
    String? dateOfBirth,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(fullName.trim());
    await userDoc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone.trim(),
      if (role != null && role.isNotEmpty) 'role': role,
      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        'dateOfBirth': dateOfBirth,
      'provider': 'password',
      'onboardingComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogle();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google Sign-In did not return an ID token.',
      );
    }
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final cred = await _auth.signInWithCredential(credential);
    final isNew = cred.additionalUserInfo?.isNewUser ?? false;
    if (isNew || !(await _userExists(cred.user!.uid))) {
      await userDoc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'fullName': cred.user!.displayName ?? account.displayName ?? '',
        'email': (cred.user!.email ?? account.email).toLowerCase(),
        'phone': cred.user!.phoneNumber ?? '',
        'provider': 'google',
        'photoUrl': cred.user!.photoURL ?? account.photoUrl,
        'onboardingComplete': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return cred;
  }

  Future<bool> _userExists(String uid) async {
    final snap = await userDoc(uid).get();
    return snap.exists;
  }

  Future<bool> isOnboardingComplete(String uid) async {
    final snap = await userDoc(uid).get();
    final data = snap.data();
    return data?['onboardingComplete'] == true;
  }

  Stream<UserProfile?> watchCurrentProfile() {
    return authStateChanges.asyncExpand((user) {
      if (user == null) return Stream<UserProfile?>.value(null);
      return userDoc(user.uid).snapshots().map((snap) {
        if (!snap.exists || snap.data() == null) {
          return UserProfile(
            uid: user.uid,
            fullName: user.displayName ?? '',
            email: user.email ?? '',
            phone: user.phoneNumber ?? '',
            photoUrl: user.photoURL,
            role: null,
            passportId: 'AL-${user.uid.substring(0, 6).toUpperCase()}',
            onboardingComplete: false,
          );
        }
        final profile = UserProfile.fromDoc(snap);
        return profile.copyWith(
          fullName: profile.fullName.isNotEmpty
              ? profile.fullName
              : (user.displayName ?? ''),
          email: profile.email.isNotEmpty ? profile.email : (user.email ?? ''),
          photoUrl: (profile.photoUrl == null || profile.photoUrl!.isEmpty)
              ? user.photoURL
              : profile.photoUrl,
        );
      });
    });
  }

  Future<UserProfile?> getCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await userDoc(user.uid).get();
    if (!snap.exists || snap.data() == null) {
      return UserProfile(
        uid: user.uid,
        fullName: user.displayName ?? '',
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        photoUrl: user.photoURL,
        role: null,
        passportId: 'AL-${user.uid.substring(0, 6).toUpperCase()}',
        onboardingComplete: false,
      );
    }
    return UserProfile.fromDoc(snap);
  }

  Future<void> saveOnboardingProfile(SignupData data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in user');
    }
    await userDoc(user.uid).set({
      ...data.toFirestoreMap(),
      'uid': user.uid,
      'email': user.email ?? data.email,
      'fullName': data.fullName.isNotEmpty
          ? data.fullName
          : (user.displayName ?? ''),
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await AddressBookService().seedFromProfile(
      address: data.address,
      city: data.city,
      postalCode: data.postalCode,
      country: data.country,
    );
  }

  /// Updates Passport fields after signup without rotating passportId.
  Future<void> updatePassport(SignupData data) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to update your Passport');
    final map = data.toFirestoreMap(includePassportId: false);
    await userDoc(user.uid).set({
      ...map,
      'uid': user.uid,
      'email': user.email ?? data.email,
      'fullName': data.fullName.isNotEmpty
          ? data.fullName
          : (user.displayName ?? ''),
      'phone': data.mobile.isNotEmpty ? data.mobile : user.phoneNumber,
      'onboardingComplete': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (data.fullName.isNotEmpty) {
      await user.updateDisplayName(data.fullName);
    }
    await AddressBookService().seedFromProfile(
      address: data.address,
      city: data.city,
      postalCode: data.postalCode,
      country: data.country,
    );
  }

  Future<void> signOut() async {
    // Token docs are owner-write-only, so this has to happen while still signed in.
    try {
      await PushService.instance.unregister();
    } catch (_) {}
    try {
      await _ensureGoogle();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore Google sign-out failures when Google was never used.
    }
    await _auth.signOut();
    BiometricLockService.sessionUnlocked = false;
  }

  String messageFor(Object error) {
    return AuthService.errorMessage(error);
  }

  static String errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'This email is already registered. Try logging in.';
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Incorrect email or password.';
        case 'network-request-failed':
          return 'Network error. Check your connection.';
        case 'requires-recent-login':
          return 'Sign in again, then retry this security action.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        default:
          return error.message ?? 'Authentication failed (${error.code}).';
      }
    }
    return error.toString();
  }

  Future<void> sendPasswordReset(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) throw StateError('Enter your email');
    await _auth.sendPasswordResetEmail(email: trimmed);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw StateError(
        'Password change is for email accounts. Google sign-in is managed by Google.',
      );
    }
    if (newPassword.trim().length < 6) {
      throw StateError('New password must be at least 6 characters');
    }
    final cred = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword.trim());
  }

  Future<void> setBiometricLock(bool enabled) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in required');
    await userDoc(user.uid).update({
      'preferences.biometricLock': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
