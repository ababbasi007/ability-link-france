import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/route_step.dart';
import '../widgets/ux_scope.dart';
import 'location_service.dart';
import 'routing_service.dart';
import 'voice_service.dart';

/// Live turn-by-turn navigation over a [WalkingRoute].
class NavigationSession {
  NavigationSession({
    LocationService? location,
    VoiceService? voice,
  })  : _location = location ?? LocationService.instance,
        _voice = voice ?? VoiceService.instance;

  final LocationService _location;
  final VoiceService _voice;

  WalkingRoute? _route;
  List<RouteStep> _steps = const [];
  int _stepIndex = 0;
  String _destinationName = '';
  bool _active = false;
  bool _voiceEnabled = false;
  String _ttsLanguage = 'en-US';
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<AppLatLng>? _locationSub;
  LatLng? _userPosition;

  final _stepController = StreamController<int>.broadcast();
  final _stateController = StreamController<NavigationState>.broadcast();

  bool get isActive => _active;
  bool get voiceEnabled => _voiceEnabled;
  int get stepIndex => _stepIndex;
  LatLng? get userPosition => _userPosition;
  WalkingRoute? get route => _route;
  List<RouteStep> get steps => _steps;
  String get destinationName => _destinationName;

  RouteStep? get currentStep =>
      _stepIndex >= 0 && _stepIndex < _steps.length ? _steps[_stepIndex] : null;

  RouteStep? get nextStep =>
      _stepIndex + 1 < _steps.length ? _steps[_stepIndex + 1] : null;

  Stream<int> get stepChanges => _stepController.stream;
  Stream<NavigationState> get states => _stateController.stream;

  Future<void> start({
    required WalkingRoute route,
    required String destinationName,
    bool voiceEnabled = false,
    String ttsLanguage = 'en-US',
  }) async {
    await stop();
    _route = route;
    _steps = route.steps;
    _destinationName = destinationName;
    _voiceEnabled = voiceEnabled;
    _ttsLanguage = ttsLanguage;
    _stepIndex = 0;
    _active = true;

    final loc = await _location.ensure(force: true);
    _userPosition = LatLng(loc.lat, loc.lng);
    _emitState();
    await _announceCurrentStep();

    _locationSub = _location.stream.listen(_onLocation);
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 8,
      ),
    ).listen((pos) {
      _onLocation(AppLatLng(pos.latitude, pos.longitude, fromDevice: true));
    });
  }

  Future<void> stop() async {
    _active = false;
    await _positionSub?.cancel();
    _positionSub = null;
    await _locationSub?.cancel();
    _locationSub = null;
    await _voice.stopSpeaking();
    CaptionBus.clear();
    _emitState();
  }

  /// Enable or mute TTS prompts for the active session.
  Future<void> setVoiceEnabled(bool enabled) async {
    _voiceEnabled = enabled;
    _emitState();
    if (!enabled) {
      await _voice.stopSpeaking();
      CaptionBus.clear();
      return;
    }
    await _announceCurrentStep();
  }

  Future<void> repeatInstruction() => _announceCurrentStep();

  void dispose() {
    stop();
    _stepController.close();
    _stateController.close();
  }

  void _onLocation(AppLatLng loc) {
    if (!_active || !loc.fromDevice) return;
    _userPosition = LatLng(loc.lat, loc.lng);
    _maybeAdvanceStep();
    _emitState();
  }

  void _maybeAdvanceStep() {
    final step = currentStep;
    final user = _userPosition;
    if (step == null || user == null) return;

    final dist = _distanceMeters(user, step.location);
    if (dist <= 25 && _stepIndex < _steps.length - 1) {
      _stepIndex++;
      _stepController.add(_stepIndex);
      _announceCurrentStep();
    }
  }

  Future<void> _announceCurrentStep() async {
    if (!_voiceEnabled) return;
    final step = currentStep;
    if (step == null) return;
    final text = _stepIndex == _steps.length - 1
        ? 'You have arrived at $_destinationName'
        : step.instruction;
    CaptionBus.set(text);
    await _voice.speak(text, languageCode: _ttsLanguage);
  }

  void _emitState() {
    if (_stateController.isClosed) return;
    _stateController.add(
      NavigationState(
        active: _active,
        stepIndex: _stepIndex,
        stepCount: _steps.length,
        destinationName: _destinationName,
        voiceEnabled: _voiceEnabled,
        userPosition: _userPosition,
        currentStep: currentStep,
        nextStep: nextStep,
        route: _route,
      ),
    );
  }

  static double _distanceMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
    return earth * c;
  }

  static double _rad(double d) => d * math.pi / 180;
}

class NavigationState {
  const NavigationState({
    required this.active,
    required this.stepIndex,
    required this.stepCount,
    required this.destinationName,
    this.voiceEnabled = false,
    this.userPosition,
    this.currentStep,
    this.nextStep,
    this.route,
  });

  final bool active;
  final int stepIndex;
  final int stepCount;
  final String destinationName;
  final bool voiceEnabled;
  final LatLng? userPosition;
  final RouteStep? currentStep;
  final RouteStep? nextStep;
  final WalkingRoute? route;

  bool get hasArrived => active && stepIndex >= stepCount - 1;
}
