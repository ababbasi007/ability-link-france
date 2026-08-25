import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'places_service.dart';

class AppLatLng {
  const AppLatLng(this.lat, this.lng, {this.fromDevice = false});

  final double lat;
  final double lng;
  final bool fromDevice;

  static const fallback = AppLatLng(
    PlacesService.defaultOriginLat,
    PlacesService.defaultOriginLng,
  );
}

/// Shared device location for search, nearby, and map.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  AppLatLng _current = AppLatLng.fallback;
  AppLatLng get current => _current;

  final _controller = StreamController<AppLatLng>.broadcast();
  Stream<AppLatLng> get stream async* {
    yield _current;
    yield* _controller.stream;
  }

  Completer<AppLatLng>? _inFlight;
  String? lastError;

  Future<AppLatLng> ensure({bool force = false}) async {
    if (!force && _current.fromDevice) return _current;
    if (_inFlight != null) return _inFlight!.future;
    return refresh();
  }

  Future<AppLatLng> refresh() async {
    if (_inFlight != null) return _inFlight!.future;
    final completer = Completer<AppLatLng>();
    _inFlight = completer;
    lastError = null;
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (!serviceOn) {
        lastError = 'Location services are off';
        _emit(_current.fromDevice ? _current : AppLatLng.fallback);
        completer.complete(_current);
        return _current;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        lastError = 'Location permission denied';
        _emit(_current.fromDevice ? _current : AppLatLng.fallback);
        completer.complete(_current);
        return _current;
      }

      // Fast path: last known position for quick camera move.
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          _emit(AppLatLng(last.latitude, last.longitude, fromDevice: true));
        }
      } catch (_) {}

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final next = AppLatLng(pos.latitude, pos.longitude, fromDevice: true);
      _emit(next);
      completer.complete(next);
      return next;
    } on TimeoutException {
      lastError = 'Location timed out';
      if (_current.fromDevice) {
        completer.complete(_current);
        return _current;
      }
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          final next = AppLatLng(
            last.latitude,
            last.longitude,
            fromDevice: true,
          );
          _emit(next);
          completer.complete(next);
          return next;
        }
      } catch (_) {}
      _emit(AppLatLng.fallback);
      completer.complete(_current);
      return _current;
    } catch (e) {
      lastError = e.toString();
      if (!_current.fromDevice) _emit(AppLatLng.fallback);
      completer.complete(_current);
      return _current;
    } finally {
      _inFlight = null;
    }
  }

  void _emit(AppLatLng value) {
    _current = value;
    if (!_controller.isClosed) _controller.add(value);
  }
}
