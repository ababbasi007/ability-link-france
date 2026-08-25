import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_copy.dart';
import '../../models/care_appointment.dart';
import '../../models/rehab.dart';
import '../../models/ux_prefs.dart';
import '../../services/consult_call_service.dart';
import '../../services/healthcare_service.dart';
import '../../services/rehab_service.dart';
import '../../services/telehealth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';
import '../../widgets/ux_scope.dart';
import '../tele_rehab/exercise_library_screen.dart';

class SessionRoomScreen extends StatefulWidget {
  const SessionRoomScreen({super.key, required this.appointment});

  final CareAppointment appointment;

  @override
  State<SessionRoomScreen> createState() => _SessionRoomScreenState();
}

class _SessionRoomScreenState extends State<SessionRoomScreen> {
  final _care = HealthcareService();
  final _rehab = RehabService();
  final _tele = TelehealthService();
  final _tts = FlutterTts();
  final _chat = TextEditingController();
  final _picker = ImagePicker();
  final _call = ConsultCallService();

  bool _muted = false;
  bool _speakerOn = true;
  bool _showChat = false;
  bool _precheckDone = false;
  bool _precheckMuted = false;
  String? _sharePath;
  RehabExercise? _demo;
  DateTime? _started;
  Timer? _tick;
  Duration _elapsed = Duration.zero;
  String _joinCode = '';
  bool _chatReady = false;

  CareAppointment get appointment => widget.appointment;
  bool get isRehab => appointment.kind == 'rehab';
  bool get isVideo => appointment.mode == 'video' || appointment.mode.isEmpty;
  bool get isAudio => appointment.mode == 'audio';
  bool get isChat => appointment.mode == 'chat';
  String get threadId => 'session-${appointment.id}';
  bool get isPatient {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == appointment.uid;
  }

  @override
  void initState() {
    super.initState();
    _joinCode = appointment.joinCode;
    _showChat = isChat;
    // Chat-only visits have no devices to check — everything else gets a
    // camera/mic precheck before the other person is left waiting.
    _precheckDone = isChat;
    _started = DateTime.now();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _started == null) return;
      setState(() => _elapsed = DateTime.now().difference(_started!));
    });
    _call.addListener(_onCall);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = UxScope.maybeOf(context)?.prefs ?? const UxPrefs();
      CaptionBus.set(
        '${AppCopy.t(prefs, 'captionsSession')}: ${appointment.providerName}',
      );
      if (isChat) {
        _prepare();
      } else {
        _call.preview(video: isVideo);
      }
    });
  }

  Future<void> _joinNow() async {
    if (_precheckMuted) {
      await _call.setMic(false);
    }
    setState(() => _precheckDone = true);
    await _prepare();
  }

  Future<void> _prepare() async {
    if (isPatient && appointment.id.isNotEmpty) {
      final code = await _care.ensureJoinCode(appointment);
      if (mounted && code.isNotEmpty) setState(() => _joinCode = code);
    } else if (appointment.id.isNotEmpty && _joinCode.isNotEmpty) {
      await _care.registerConsultGuest(
        appointmentId: appointment.id,
        code: _joinCode,
      );
    }
    if (appointment.id.isNotEmpty) {
      await _rehab.ensureChatThread(threadId, appointmentId: appointment.id);
      if (mounted) setState(() => _chatReady = true);
    }
    if (!isChat) {
      await _call.join(appointment: appointment, video: isVideo);
    }
  }

  void _onCall() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleCamera() async {
    await _call.setCamera(!_call.cameraOn);
  }

  Future<void> _shareScreen() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _sharePath = file.path);
  }

  Future<void> _pickDemo() async {
    final list = await _rehab.watchExercises().first;
    if (!mounted || list.isEmpty) return;
    final chosen = await showModalBottomSheet<RehabExercise>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          for (final e in list)
            ListTile(
              title: Text(e.title),
              subtitle: Text(e.demoCue),
              onTap: () => Navigator.pop(ctx, e),
            ),
        ],
      ),
    );
    if (chosen != null && mounted) setState(() => _demo = chosen);
  }

  Future<void> _sendChat() async {
    final text = _chat.text.trim();
    if (text.isEmpty) return;
    _chat.clear();
    await _rehab.sendChat(
      threadId: threadId,
      appointmentId: appointment.id,
      body: text,
      author: isPatient ? 'You' : appointment.providerName,
    );
    if (_speakerOn && !_muted) {
      await _tts.speak(text);
    }
  }

  String get _timerLabel {
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = _elapsed.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  Future<void> _end() async {
    await _call.hangup();
    if (isPatient && appointment.id.isNotEmpty) {
      final summary =
          '${appointment.modeLabel} with ${appointment.providerName} ($_timerLabel).';
      try {
        await _care.complete(appointment.id, summary: summary);
        if (isRehab) {
          await _rehab.addNote(
            author: appointment.providerName,
            body:
                'Session completed ($_timerLabel). ${appointment.notes.isEmpty ? 'Follow the home plan and log pain/energy today.' : appointment.notes}',
            appointmentId: appointment.id,
          );
        } else {
          await _tele.addNote(
            author: appointment.providerName,
            body:
                'Visit completed ($_timerLabel). ${appointment.notes.isEmpty ? 'Continue current plan and message if symptoms change.' : appointment.notes}',
            appointmentId: appointment.id,
          );
          await _tele.addDocument(
            title: 'Visit · ${appointment.providerName}',
            kind: 'visit',
            detail: summary,
          );
        }
      } catch (_) {}
    }
    if (!mounted) return;
    var follow = false;
    if (isPatient) {
      follow =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Book a follow-up?'),
              content: const Text(
                'Schedule another visit with this clinician in two weeks.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Not now'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Book follow-up'),
                ),
              ],
            ),
          ) ??
          false;
      if (follow) {
        await _care.bookFollowUp(appointment);
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          follow ? 'Session ended. Follow-up booked.' : 'Session ended.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    _chat.dispose();
    _call.removeListener(_onCall);
    unawaited(_call.hangup());
    CaptionBus.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_precheckDone) return _precheckView();

    final peerName = isPatient
        ? appointment.providerName
        : (appointment.patientName.isEmpty
              ? 'Patient'
              : appointment.patientName);

    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          isRehab
                              ? 'Tele-rehab session'
                              : isChat
                              ? 'Chat consultation'
                              : isAudio
                              ? 'Audio consultation'
                              : 'Video consultation',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          _call.peerConnected
                              ? 'Live with $peerName'
                              : peerName,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x33FFFFFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _timerLabel,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(child: _mainStage()),
                  if (_sharePath != null || _demo != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: _shareBanner(),
                    ),
                  if (_call.reconnecting)
                    Positioned(
                      left: 12,
                      right: 12,
                      top: 12,
                      child: _reconnectingBanner(),
                    ),
                  if (isVideo) Positioned(right: 12, bottom: 12, child: _pip()),
                ],
              ),
            ),
            if (_joinCode.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  isPatient
                      ? 'Clinician join code: $_joinCode'
                      : 'Visit code $_joinCode',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (_showChat || isChat) _chatPane(),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (!isChat)
                    _ctl(
                      _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                      _muted ? 'Unmute' : 'Mute',
                      () async {
                        final next = !_muted;
                        setState(() => _muted = next);
                        await _call.setMic(!next);
                      },
                      active: !_muted,
                    ),
                  if (isVideo)
                    _ctl(
                      _call.cameraOn
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      'Camera',
                      _toggleCamera,
                      active: _call.cameraOn,
                    ),
                  if (!isChat)
                    _ctl(
                      _speakerOn
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      'Speaker',
                      () async {
                        setState(() => _speakerOn = !_speakerOn);
                        await _call.setSpeaker(_speakerOn);
                      },
                      active: _speakerOn,
                    ),
                  if (isVideo)
                    _ctl(
                      Icons.present_to_all_rounded,
                      'Share',
                      _shareScreen,
                      active: _sharePath != null,
                    ),
                  _ctl(
                    Icons.chat_bubble_rounded,
                    'Chat',
                    () => setState(() => _showChat = !_showChat),
                    active: _showChat || isChat,
                  ),
                  if (isRehab)
                    _ctl(
                      Icons.fitness_center_rounded,
                      'Demo',
                      _pickDemo,
                      active: _demo != null,
                    ),
                  _ctl(Icons.call_end_rounded, 'End', _end, danger: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _precheckView() {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      'Check your camera & mic',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: Colors.black,
                  width: double.infinity,
                  child: _call.error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              _call.error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : (isVideo && _call.hasLocal)
                      ? RTCVideoView(
                          _call.localRenderer,
                          mirror: true,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        )
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _call.hasLocal
                                    ? 'Microphone ready'
                                    : 'Requesting camera & microphone access…',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ctl(
                    _precheckMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    _precheckMuted ? 'Unmute' : 'Mute',
                    () => setState(() => _precheckMuted = !_precheckMuted),
                    active: !_precheckMuted,
                  ),
                  if (isVideo)
                    _ctl(
                      _call.cameraOn
                          ? Icons.videocam_rounded
                          : Icons.videocam_off_rounded,
                      'Camera',
                      _toggleCamera,
                      active: _call.cameraOn,
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _call.hasLocal || _call.error != null
                      ? _joinNow
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _call.error != null ? 'Join anyway' : 'Join session',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainStage() {
    if (_demo != null) {
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) =>
                ExerciseDetailScreen(exercise: _demo!, inSession: true),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: DecodedNetworkImage(
                _demo!.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Colors.black,
                  child: Icon(
                    Icons.fitness_center,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(12),
              child: Text(
                '${_demo!.title}: ${_demo!.demoCue}',
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
    if (_sharePath != null && !kIsWeb) {
      return Image.file(File(_sharePath!), fit: BoxFit.contain);
    }
    if (!isChat && _call.hasRemote) {
      return RTCVideoView(
        _call.remoteRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }
    if (isVideo && _call.hasLocal) {
      return Stack(
        fit: StackFit.expand,
        children: [
          RTCVideoView(
            _call.localRenderer,
            mirror: true,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          if (!_call.peerConnected) _waitingBanner(),
        ],
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: appointment.photoUrl.isEmpty
                ? null
                : NetworkImage(appointment.photoUrl),
            child: appointment.photoUrl.isEmpty
                ? const Icon(Icons.person, size: 48, color: AppColors.primary)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            _statusLabel,
            style: GoogleFonts.plusJakartaSans(color: Colors.white70),
          ),
          if (_call.error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _call.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                isChat
                    ? 'Messages stay on this visit. The clinician can reply live.'
                    : isPatient
                    ? 'Waiting for the clinician. Share join code $_joinCode.'
                    : 'Connecting to the patient…',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  String get _statusLabel {
    if (isChat) return 'Chat consultation';
    if (_call.peerConnected) {
      return isAudio ? 'Audio connected' : 'Live';
    }
    if (_muted) return 'Microphone muted';
    if (_call.connecting) return 'Connecting…';
    return isAudio ? 'Waiting for audio' : 'Waiting for the other person';
  }

  Widget _waitingBanner() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xCC111827),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _joinCode.isEmpty
              ? 'Waiting for the clinician to join…'
              : 'Waiting for clinician · code $_joinCode',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _reconnectingBanner() {
    return Material(
      color: const Color(0xCC7A4A00),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Reconnecting…',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        height: 150,
        color: Colors.black,
        child: _call.hasLocal && _call.hasRemote
            ? RTCVideoView(_call.localRenderer, mirror: true)
            : const Icon(Icons.person, color: Colors.white54),
      ),
    );
  }

  Widget _shareBanner() {
    return Material(
      color: const Color(0xCC111827),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        title: Text(
          _demo != null
              ? 'Sharing exercise: ${_demo!.title}'
              : 'Screen sharing on',
          style: const TextStyle(color: Colors.white),
        ),
        trailing: TextButton(
          onPressed: () => setState(() {
            _demo = null;
            _sharePath = null;
          }),
          child: const Text('Stop'),
        ),
      ),
    );
  }

  Widget _chatPane() {
    return Container(
      height: 180,
      color: const Color(0xFF1F2937),
      child: Column(
        children: [
          Expanded(
            child: !_chatReady
                ? const SizedBox.shrink()
                : StreamBuilder<List<SessionChatMessage>>(
                    stream: _rehab.watchChat(threadId),
                    builder: (context, snap) {
                      final list = snap.data ?? const <SessionChatMessage>[];
                      return ListView(
                        padding: const EdgeInsets.all(8),
                        children: [
                          for (final m in list)
                            Text(
                              '${m.author}: ${m.body}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chat,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Chat…',
                      hintStyle: TextStyle(color: Colors.white54),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Send message',
                  onPressed: _sendChat,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctl(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
    bool danger = false,
  }) {
    final color = danger
        ? const Color(0xFFEF4444)
        : active
        ? AppColors.primary
        : const Color(0xFF374151);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: color,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
