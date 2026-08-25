import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/care_appointment.dart';

/// Two-party WebRTC call using Firestore as the signaling channel.
///
/// The patient (appointment.uid) is the caller. The clinician is the callee.
/// Both must be signed in. A second device joins with the visit code.
class ConsultCallService extends ChangeNotifier {
  ConsultCallService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const _ice = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _local;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sessionSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _iceSub;
  bool _remoteDescSet = false;
  bool _isCaller = true;
  String? _roomId;
  final _pendingIce = <RTCIceCandidate>[];

  bool connecting = false;
  bool peerConnected = false;
  bool micOn = true;
  bool cameraOn = true;
  bool speakerOn = true;
  bool _closed = false;
  String? error;

  bool get hasLocal => localRenderer.srcObject != null;
  bool get hasRemote => remoteRenderer.srcObject != null;

  CollectionReference<Map<String, dynamic>> _room(String id) =>
      _db.collection('consultRooms').doc(id).collection('call');

  DocumentReference<Map<String, dynamic>> _session(String id) =>
      _room(id).doc('session');

  Future<void> join({
    required CareAppointment appointment,
    required bool video,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      error = 'Sign in required';
      notifyListeners();
      return;
    }
    if (appointment.id.isEmpty) {
      error = 'Missing visit';
      notifyListeners();
      return;
    }

    connecting = true;
    cameraOn = video;
    error = null;
    _isCaller = uid == appointment.uid;
    _roomId = appointment.id;
    notifyListeners();

    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();

      _local = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video
            ? {'facingMode': 'user', 'width': 640, 'height': 480}
            : false,
      });
      localRenderer.srcObject = _local;

      _pc = await createPeerConnection(_ice);
      for (final track in _local!.getTracks()) {
        await _pc!.addTrack(track, _local!);
      }

      _pc!.onTrack = (event) {
        if (event.streams.isNotEmpty) {
          remoteRenderer.srcObject = event.streams.first;
          peerConnected = true;
          connecting = false;
          notifyListeners();
        }
      };

      _pc!.onIceConnectionState = (state) {
        if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
            state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
          peerConnected = true;
          connecting = false;
          notifyListeners();
        }
      };

      _pc!.onIceCandidate = (candidate) {
        final room = _roomId;
        if (room == null || candidate.candidate == null) return;
        _session(room).collection(_isCaller ? 'callerIce' : 'calleeIce').add({
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      try {
        await Helper.setSpeakerphoneOn(true);
      } catch (_) {}

      final iceCol = _session(
        appointment.id,
      ).collection(_isCaller ? 'calleeIce' : 'callerIce');
      _iceSub = iceCol.snapshots().listen((snap) async {
        for (final change in snap.docChanges) {
          if (change.type != DocumentChangeType.added) continue;
          final d = change.doc.data() ?? {};
          final cand = RTCIceCandidate(
            d['candidate'] as String?,
            d['sdpMid'] as String?,
            (d['sdpMLineIndex'] as num?)?.toInt(),
          );
          if (!_remoteDescSet) {
            _pendingIce.add(cand);
            continue;
          }
          await _pc?.addCandidate(cand);
        }
      });

      if (_isCaller) {
        await _startAsCaller(appointment.id);
      } else {
        await _startAsCallee(appointment.id);
      }
    } catch (e) {
      error = 'Could not start live call. $e';
      connecting = false;
      notifyListeners();
    }
  }

  Future<void> _startAsCaller(String roomId) async {
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);
    await _session(roomId).set({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'offerUid': _auth.currentUser?.uid,
      'hangup': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    _sessionSub = _session(roomId).snapshots().listen((snap) async {
      final d = snap.data();
      if (d == null) return;
      if (d['hangup'] == true) {
        error = 'The other person left the visit.';
        notifyListeners();
        return;
      }
      final answer = d['answer'];
      if (answer is Map && !_remoteDescSet) {
        await _pc!.setRemoteDescription(
          RTCSessionDescription(
            answer['sdp'] as String?,
            answer['type'] as String?,
          ),
        );
        _remoteDescSet = true;
        await _flushIce();
      }
    });
  }

  Future<void> _startAsCallee(String roomId) async {
    _sessionSub = _session(roomId).snapshots().listen((snap) async {
      final d = snap.data();
      if (d == null) return;
      if (d['hangup'] == true) {
        error = 'The other person left the visit.';
        notifyListeners();
        return;
      }
      final offer = d['offer'];
      if (offer is Map && !_remoteDescSet) {
        await _pc!.setRemoteDescription(
          RTCSessionDescription(
            offer['sdp'] as String?,
            offer['type'] as String?,
          ),
        );
        _remoteDescSet = true;
        final answer = await _pc!.createAnswer();
        await _pc!.setLocalDescription(answer);
        await _session(roomId).set({
          'answer': {'sdp': answer.sdp, 'type': answer.type},
          'answerUid': _auth.currentUser?.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _flushIce();
      }
    });
  }

  Future<void> _flushIce() async {
    for (final c in _pendingIce) {
      await _pc?.addCandidate(c);
    }
    _pendingIce.clear();
  }

  Future<void> setMic(bool on) async {
    micOn = on;
    _local?.getAudioTracks().forEach((t) => t.enabled = on);
    notifyListeners();
  }

  Future<void> setCamera(bool on) async {
    cameraOn = on;
    _local?.getVideoTracks().forEach((t) => t.enabled = on);
    notifyListeners();
  }

  Future<void> setSpeaker(bool on) async {
    speakerOn = on;
    try {
      await Helper.setSpeakerphoneOn(on);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> hangup() async {
    if (_closed) return;
    _closed = true;
    final room = _roomId;
    if (room != null) {
      try {
        await _session(room).set({
          'hangup': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
    await _sessionSub?.cancel();
    await _iceSub?.cancel();
    _sessionSub = null;
    _iceSub = null;
    for (final t in _local?.getTracks() ?? const <MediaStreamTrack>[]) {
      await t.stop();
    }
    await _local?.dispose();
    _local = null;
    await _pc?.close();
    _pc = null;
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    try {
      await localRenderer.dispose();
      await remoteRenderer.dispose();
    } catch (_) {}
    peerConnected = false;
    connecting = false;
  }
}
