import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../firebase_options.dart';
import '../models/app_notification.dart';
import '../screens/notifications/notifications_inbox_screen.dart';
import '../widgets/app_bottom_nav.dart';

/// Android channel id. Must match the native [NotificationChannel] and the
/// Cloud Function payload, or background notifications are dropped on API 26+.
const kPushChannelId = 'ability_link_alerts';

/// Required entry point for data messages received while the isolate is dead.
/// Notification-payload messages are displayed by the OS; this exists so a
/// future data-only payload does not crash the background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Stable Firestore doc id so token refreshes overwrite rather than pile up.
String fcmTokenDocId(String token) =>
    sha256.convert(utf8.encode(token)).toString();

/// Registers this device for FCM and keeps the token in
/// `users/{uid}/fcmTokens`. The Cloud Function reads that subcollection when a
/// `notifications` document is created with `push` in `channels`.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _started = false;
  String? _token;

  Future<void> start() async {
    if (kIsWeb || _started) return;
    _started = true;
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _messaging.onTokenRefresh.listen(_storeToken);
    FirebaseMessaging.onMessageOpenedApp.listen(_openInbox);
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openInbox(initial));
    }
  }

  /// Aligns the stored token with [prefs.push] and the OS permission.
  ///
  /// Called after sign-in (from the shell) and whenever the push toggle
  /// changes. A denied OS prompt leaves the preference alone so the user can
  /// retry from system settings.
  Future<void> sync({NotificationPrefs? prefs}) async {
    if (kIsWeb) return;
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final enabled = prefs?.push ?? await _pushEnabled(user.uid);
      if (!enabled) {
        await unregister();
        return;
      }
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _messaging.getToken();
      if (token != null) await _storeToken(token);
    } catch (error, stack) {
      // Missing APNs setup on a simulator is the usual case; don't crash the shell.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'ability_link',
          context: ErrorDescription('push token sync failed'),
        ),
      );
    }
  }

  /// Drops this device's token from Firestore. Must run while the user is
  /// still signed in — the owner-only rule cannot delete after [signOut].
  Future<void> unregister() async {
    if (kIsWeb) return;
    final uid = _auth.currentUser?.uid;
    String? token = _token;
    if (token == null) {
      try {
        token = await _messaging.getToken();
      } catch (_) {
        token = null;
      }
    }
    _token = null;
    if (uid == null || token == null || token.isEmpty) return;
    await _tokenDoc(uid, token).delete();
  }

  Future<bool> _pushEnabled(String uid) async {
    try {
      final snap = await _db.collection('users').doc(uid).get();
      final data = snap.data()?['notificationPrefs'];
      return NotificationPrefs.fromMap(
        data is Map ? Map<String, dynamic>.from(data) : null,
      ).push;
    } catch (_) {
      return true;
    }
  }

  Future<void> _storeToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null || token.isEmpty) return;
    _token = token;
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : 'other';
    await _tokenDoc(uid, token).set({
      'token': token,
      'platform': platform,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  DocumentReference<Map<String, dynamic>> _tokenDoc(String uid, String token) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(fcmTokenDocId(token));
  }

  void _openInbox(RemoteMessage message) {
    final nav = AppShellNav.navigatorKey.currentState;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsInboxScreen()),
    );
  }
}
