import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/accessible_routing_prefs.dart';
import '../../models/care_shared_route.dart';
import '../../models/map_basemap.dart';
import '../../models/place_category.dart';
import '../../models/place.dart';
import '../../models/place_barrier_report.dart';
import '../../models/route_direction_style.dart';
import '../../models/user_profile.dart';
import '../../models/ux_prefs.dart';
import '../../services/accessible_routing_prefs_store.dart';
import '../../services/accessible_routing_service.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/care_circle_service.dart';
import '../../services/geocode_service.dart';
import '../../services/local_place_cache.dart';
import '../../services/local_route_cache.dart';
import '../../services/location_service.dart';
import '../../services/map_basemap_prefs.dart';
import '../../services/map_search_history_service.dart';
import '../../services/navigation_session.dart';
import '../../services/offline_tile_provider.dart';
import '../../services/places_service.dart';
import '../../services/place_report_service.dart';
import '../../services/routing_service.dart';
import '../../services/user_activity_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/favorite_list_sheet.dart';
import '../../widgets/navigation_overlay.dart';
import '../../widgets/place_detail_sheet.dart';
import '../../widgets/place_summary_dialog.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../search/search_screen.dart';
import 'map_chrome.dart';
import 'map_hub_chrome.dart';
import 'saved_routes_screen.dart';
import 'tile_cache_screen.dart';

class AccessibilityMapScreen extends StatefulWidget {
  const AccessibilityMapScreen({
    super.key,
    this.showBack = true,
    this.initialPlaceId,
    this.initialLat,
    this.initialLng,
  });

  final bool showBack;
  final String? initialPlaceId;
  final double? initialLat;
  final double? initialLng;

  @override
  State<AccessibilityMapScreen> createState() => _AccessibilityMapScreenState();
}

class _AccessibilityMapScreenState extends State<AccessibilityMapScreen> {
  final _places = PlacesService();
  final _placeReports = PlaceReportService();
  final _auth = AuthService();
  final _navigation = NavigationSession();
  final _searchHistory = MapSearchHistoryService();
  final _geocode = GeocodeService();
  final _accessibleRouting = AccessibleRoutingService();
  final _mapController = MapController();
  final _sheetController = DraggableScrollableController();
  final _offlineTileProvider = OfflineFirstTileProvider(
    headers: {'User-Agent': 'com.abilitylink.app'},
  );

  int _selectedCategory = 0;
  String? _placeTypeFilter;
  final _search = TextEditingController();
  final _hubScroll = ScrollController();
  final _nearbySectionKey = GlobalKey();
  final Set<String> _amenities = {};
  WalkingRoute? _route;
  AccessiblePlace? _selected;
  Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favSub;
  StreamSubscription<AppLatLng>? _locSub;
  bool _seeding = false;
  bool _openedInitial = false;
  bool _mapReady = false;
  bool _locating = false;
  bool _routing = false;
  bool _didAutoCenter = false;
  bool _showLegend = false;
  bool _fullyAccessibleOnly = false;
  bool _openNowOnly = false;
  bool _alwaysOpenOnly = false;
  List<AccessiblePlace> _lastPlaces = const [];
  int _selectedLayer = 0;
  AccessibleRoutingPrefs _routingPrefs = AccessibleRoutingPrefs.defaults;
  NavigationState? _navState;
  StreamSubscription<NavigationState>? _navSub;
  LatLng? _userLatLng = const LatLng(
    PlacesService.defaultOriginLat,
    PlacesService.defaultOriginLng,
  );
  LatLng _mapCenter = const LatLng(34.1688, 73.2215);
  LatLng? _pendingMove;
  double _pendingZoom = 15;
  List<String> _recent = [];
  StreamSubscription<List<String>>? _recentSub;

  /// $1 icon, $2 filter key, $3 chip label, $4 icon color.
  static const _categories = [
    (Icons.grid_view_rounded, 'All Places', 'All', Color(0xFF006D44)),
    (
      Icons.accessible_rounded,
      'Wheelchair',
      'Wheelchair Accessible',
      Color(0xFF16A34A),
    ),
    (Icons.local_parking_rounded, 'parking', 'Parking', Color(0xFF2563EB)),
    (Icons.wc_rounded, 'toilet', 'Restrooms', Color(0xFF7C3AED)),
    (Icons.meeting_room_rounded, 'stepFree', 'Entrances', Color(0xFFEA580C)),
    (Icons.elevator_rounded, 'elevator', 'Elevator', Color(0xFF0D9488)),
  ];

  static const _amenityChips = [
    (Icons.local_parking_rounded, PlaceAmenities.freeParking, 'Free parking'),
    (Icons.local_parking_rounded, PlaceAmenities.parking, 'Parking'),
    (Icons.wc_rounded, PlaceAmenities.toilet, 'Toilets'),
    (Icons.stairs_outlined, PlaceAmenities.stepFree, 'Step-free'),
    (Icons.elevator_rounded, PlaceAmenities.elevator, 'Elevators'),
    (Icons.touch_app_rounded, PlaceAmenities.braille, 'Braille'),
    (Icons.hearing_rounded, PlaceAmenities.hearing, 'Hearing loop'),
    (Icons.sign_language_rounded, PlaceAmenities.signLanguage, 'Sign language'),
    (
      Icons.directions_transit_rounded,
      PlaceAmenities.accessibleTransit,
      'Transit',
    ),
    (Icons.nights_stay_rounded, PlaceAmenities.quiet, 'Quiet'),
    (Icons.desk_rounded, PlaceAmenities.receptionDesk, 'Reception desk'),
    (Icons.spa_rounded, PlaceAmenities.calmWaitingRoom, 'Calm waiting room'),
    (Icons.pets_rounded, PlaceAmenities.serviceAnimal, 'Service animal'),
    (
      Icons.family_restroom_rounded,
      PlaceAmenities.familyFriendly,
      'Family friendly',
    ),
    (Icons.pets_rounded, PlaceAmenities.petFriendly, 'Pet friendly'),
    (Icons.straighten_rounded, PlaceAmenities.wideCorridors, 'Wide corridors'),
    (
      Icons.event_seat_rounded,
      PlaceAmenities.accessibleSeating,
      'Accessible seating',
    ),
    (Icons.countertops_outlined, PlaceAmenities.lowCounters, 'Low counters'),
    (
      Icons.elevator_rounded,
      PlaceAmenities.brailleElevatorControls,
      'Braille elevator',
    ),
    (
      Icons.contrast_rounded,
      PlaceAmenities.highContrastSignage,
      'High contrast',
    ),
    (Icons.campaign_rounded, PlaceAmenities.audioAnnouncements, 'Audio alerts'),
    (Icons.light_mode_rounded, PlaceAmenities.goodLighting, 'Good lighting'),
    (
      Icons.wb_twilight_rounded,
      PlaceAmenities.visualEmergencyAlarms,
      'Visual alarms',
    ),
    (Icons.chat_rounded, PlaceAmenities.textChat, 'Text chat'),
    (Icons.local_taxi_rounded, PlaceAmenities.dropOff, 'Drop-off'),
    (
      Icons.ev_station_rounded,
      PlaceAmenities.evAccessibleParking,
      'EV parking',
    ),
    (Icons.electrical_services_rounded, PlaceAmenities.evCharging, 'EV charge'),
  ];

  MapBasemap get _activeBasemap => MapBasemap.byIndex(_selectedLayer);

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _mapCenter = LatLng(widget.initialLat!, widget.initialLng!);
      _didAutoCenter = true;
    }
    unawaited(_restoreBasemap());
    unawaited(_restoreRoutingPrefs());
    _recentSub = _searchHistory.watchRecent().listen((items) {
      if (mounted) setState(() => _recent = items);
    });
    _favSub = _places.watchFavoriteIds().listen((ids) {
      if (mounted) setState(() => _favoriteIds = ids);
    });
    _locSub = LocationService.instance.stream.listen((loc) {
      if (!mounted || !loc.fromDevice) return;
      final point = LatLng(loc.lat, loc.lng);
      setState(() => _userLatLng = point);
      if (!_didAutoCenter && widget.initialPlaceId == null) {
        _didAutoCenter = true;
        _moveCamera(point, 15);
      }
    });
    _navSub = _navigation.states.listen((state) {
      if (mounted) setState(() => _navState = state);
    });
    _seedIfNeeded();
    if (widget.initialLat == null || widget.initialLng == null) {
      _goToMyLocation(silent: true);
    }
  }

  void _moveCamera(LatLng point, [double zoom = 15]) {
    _mapCenter = point;
    if (_mapReady) {
      _mapController.move(point, zoom);
      _pendingMove = null;
    } else {
      _pendingMove = point;
      _pendingZoom = zoom;
    }
  }

  void _onMapReady() {
    _mapReady = true;
    final pending = _pendingMove;
    if (pending != null) {
      _mapController.move(pending, _pendingZoom);
      _pendingMove = null;
    } else if (_userLatLng != null &&
        widget.initialPlaceId == null &&
        !_didAutoCenter) {
      _didAutoCenter = true;
      _mapController.move(_userLatLng!, 15);
    }
  }

  Future<void> _restoreBasemap() async {
    final kind = await MapBasemapPrefs.instance.load();
    if (!mounted) return;
    setState(() => _selectedLayer = MapBasemap.indexOf(kind));
  }

  Future<void> _restoreRoutingPrefs() async {
    final profile = await _auth.getCurrentProfile();
    final seeded = AccessibleRoutingPrefs.fromPassport(profile);
    final stored = await AccessibleRoutingPrefsStore.instance.load(
      fallback: seeded,
    );
    if (!mounted) return;
    setState(() => _routingPrefs = stored);
  }

  Future<void> _selectBasemap(int index) async {
    if (index < 0 || index >= MapBasemap.all.length) return;
    setState(() => _selectedLayer = index);
    await MapBasemapPrefs.instance.save(MapBasemap.all[index].kind);
  }

  Future<void> _saveRoutingPrefs(AccessibleRoutingPrefs prefs) async {
    setState(() => _routingPrefs = prefs);
    await AccessibleRoutingPrefsStore.instance.save(prefs);
  }

  Future<void> _goToMyLocation({bool silent = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final loc = await LocationService.instance.ensure(force: true);
      if (!mounted) return;
      final point = LatLng(loc.lat, loc.lng);
      setState(() {
        _mapCenter = point;
        // Always treat a resolved fix as the nearby origin. Fallback is
        // Abbottabad so local test places still sort as "near me".
        _userLatLng = point;
      });
      if (loc.fromDevice) {
        _didAutoCenter = true;
        _moveCamera(point, 15);
      } else {
        if (!_didAutoCenter) {
          _didAutoCenter = true;
          _moveCamera(point, 14);
        }
        if (!silent) {
          _toast(
            LocationService.instance.lastError ??
                'Using Abbottabad as your map area. Enable location for live GPS.',
          );
        }
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _seedIfNeeded() async {
    setState(() => _seeding = true);
    try {
      await _places.ensureSeeded();
      // Opportunistically refresh the offline favorites cache.
      unawaited(_places.syncFavoritesToCache());
    } catch (_) {
      // Seed may fail if signed out; places already seeded via console.
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  void dispose() {
    _favSub?.cancel();
    _locSub?.cancel();
    _recentSub?.cancel();
    _navSub?.cancel();
    _navigation.dispose();
    _searchHistory.dispose();
    _search.dispose();
    _hubScroll.dispose();
    // Do NOT dispose _mapController here — FlutterMap owns its lifecycle and
    // will dispose it when the widget unmounts. Calling dispose() from outside
    // races with the widget tree teardown and triggers the
    // `_dependents.isEmpty` assertion in framework.dart.
    _sheetController.dispose();
    _offlineTileProvider.dispose();
    super.dispose();
  }

  String get _filterLabel => _categories[_selectedCategory].$2;

  List<AccessiblePlace> _filtered(List<AccessiblePlace> all) {
    final query = _search.text;
    final origin = _userLatLng ??
        LatLng(
          PlacesService.defaultOriginLat,
          PlacesService.defaultOriginLng,
        );
    final list = all.where((p) {
      if (!p.matchesFilter(_filterLabel)) return false;
      if (!p.matchesPlaceType(_placeTypeFilter)) return false;
      if (_openNowOnly && !p.isOpenNow()) return false;
      if (_alwaysOpenOnly && !p.isAlwaysOpen) return false;
      if (!p.matchesAmenities(_amenities)) return false;
      if (_fullyAccessibleOnly && !p.isFullyAccessible()) return false;
      if (!p.matchesQuery(query)) return false;
      return true;
    }).toList();
    list.sort(
      (a, b) => a
          .distanceKm(origin.latitude, origin.longitude)
          .compareTo(b.distanceKm(origin.latitude, origin.longitude)),
    );
    return list;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggleFavorite(AccessiblePlace place) async {
    try {
      await _places.toggleFavorite(place.id);
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _rememberRecent(String name) {
    runInBackground(_searchHistory.remember(name), 'map search history');
  }

  Future<void> _clearRecent() async {
    try {
      await _searchHistory.clear();
    } catch (e) {
      _toast('$e');
    }
  }

  void _openRecent(String name, List<AccessiblePlace> places) {
    _search.text = name;
    setState(() {});
    AccessiblePlace? match;
    for (final p in places) {
      if (p.name.toLowerCase() == name.toLowerCase()) {
        match = p;
        break;
      }
    }
    match ??= () {
      for (final p in places) {
        if (p.name.toLowerCase().contains(name.toLowerCase())) return p;
      }
      return null;
    }();
    if (match != null) _showPlaceSheet(match);
  }

  Future<void> _handleSearchSubmit(
    String query,
    List<AccessiblePlace> places,
  ) async {
    _rememberRecent(query);
    final q = query.trim();
    if (q.isEmpty) return;

    AccessiblePlace? match;
    for (final p in places) {
      if (p.name.toLowerCase() == q.toLowerCase()) {
        match = p;
        break;
      }
    }
    match ??= () {
      for (final p in places) {
        if (p.name.toLowerCase().contains(q.toLowerCase())) return p;
      }
      return null;
    }();
    if (match != null) {
      _showPlaceSheet(match);
      return;
    }

    final geo = await _geocode.searchOne(q, countryCode: 'fr');
    if (!mounted || geo == null) {
      _toast('No place or address match found for "$q".');
      return;
    }
    _moveCamera(LatLng(geo.lat, geo.lng), 15);
    _toast('Moved map to ${geo.displayName}');
  }

  Future<void> _routeTo(AccessiblePlace place) async {
    if (_routing) return;
    setState(() => _routing = true);
    try {
      final origin = await LocationService.instance.ensure(force: true);
      if (!mounted) return;
      WalkingRoute route;
      try {
        route = await _routeWithAccessibilityV1(
          origin: origin,
          destination: place,
        );
      } catch (_) {
        final cached = await LocalRouteCache.instance.findForDestination(
          place.id,
        );
        if (cached == null) rethrow;
        route = cached.route;
        if (mounted) {
          _toast('Using saved offline route to ${place.name}');
        }
      }
      if (!mounted) return;
      unawaited(
        LocalRouteCache.instance.save(destination: place, route: route),
      );
      await _applyRoute(place, route);
    } catch (e) {
      if (mounted) _toast('$e');
    } finally {
      if (mounted) setState(() => _routing = false);
    }
  }

  Future<void> _applyRoute(AccessiblePlace place, WalkingRoute route) async {
    setState(() {
      _selected = place;
      _route = route;
    });
    _rememberRecent(place.name);
    if (route.points.length >= 2) {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: route.points,
          padding: const EdgeInsets.fromLTRB(48, 180, 48, 320),
        ),
      );
    }
    _toast(
      route.source == 'cached'
          ? 'Offline route · ${route.distanceLabel} · ${route.durationLabel}'
          : route.isAccessibleProfile
          ? 'Accessible ${route.profile == 'wheelchair' ? 'wheelchair' : 'detour'} · ${route.distanceLabel} · ${route.durationLabel}'
          : 'Walk ${route.distanceLabel} · ${route.durationLabel}',
    );
    await _startNavigation(place, route);
  }

  Future<void> _openCachedRoute(CachedNavigationRoute cached) async {
    AccessiblePlace? place;
    for (final p in _lastPlaces) {
      if (p.id == cached.destinationPlaceId) {
        place = p;
        break;
      }
    }
    if (place == null && cached.destinationPlaceId.isNotEmpty) {
      place = await _places.getPlace(cached.destinationPlaceId);
    }
    if (place == null) {
      final recent = await LocalPlaceCache.instance.loadRecent();
      for (final p in recent) {
        if (p.id == cached.destinationPlaceId) {
          place = p;
          break;
        }
      }
    }
    place ??= AccessiblePlace(
      id: cached.destinationPlaceId.isNotEmpty
          ? cached.destinationPlaceId
          : cached.id,
      name: cached.destinationName,
      lat: cached.destinationLat,
      lng: cached.destinationLng,
      category: 'other',
      score: 0,
      rating: 0,
      reviewCount: 0,
      openNow: false,
      imageUrl: '',
      features: const [],
      needs: const [],
      address: '',
    );
    await _applyRoute(place, cached.route);
  }

  double _distanceMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final aa =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(a.latitude)) *
            math.cos(_rad(b.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(aa), math.sqrt(1 - aa));
    return earth * c;
  }

  double _rad(double d) => d * math.pi / 180;

  Future<List<LatLng>> _mineAvoidPoints() async {
    final mine = await _placeReports.fetchMineOpenAndInReview();
    if (mine.isEmpty) return const [];

    final avoid = <LatLng>[];
    for (final r in mine) {
      final cat = PlaceBarrierCategory.byId(r.category);
      if (cat == null) continue;
      if (cat.id != PlaceBarrierCategory.elevator.id &&
          cat.id != PlaceBarrierCategory.ramp.id &&
          cat.id != PlaceBarrierCategory.construction.id) {
        continue;
      }

      AccessiblePlace? place;
      for (final p in _lastPlaces) {
        if (p.id == r.placeId) {
          place = p;
          break;
        }
      }
      place ??= await _places.getPlace(r.placeId);
      if (place == null) continue;

      avoid.add(LatLng(place.lat, place.lng));
    }

    // Dedupe points that are basically the same.
    final out = <LatLng>[];
    for (final p in avoid) {
      if (out.any((x) => _distanceMeters(x, p) < 25)) continue;
      out.add(p);
    }
    return out;
  }

  Future<WalkingRoute> _routeWithAccessibilityV1({
    required AppLatLng origin,
    required AccessiblePlace destination,
  }) async {
    final avoidPoints = await _mineAvoidPoints();
    return _accessibleRouting.route(
      fromLat: origin.lat,
      fromLng: origin.lng,
      toLat: destination.lat,
      toLng: destination.lng,
      prefs: _routingPrefs,
      avoidPoints: avoidPoints,
      nearbyPlaces: _lastPlaces,
    );
  }

  Future<void> _planRoute(List<AccessiblePlace> places) async {
    if (places.isEmpty) {
      _toast('No nearby places to route to.');
      return;
    }
    final picked = await showModalBottomSheet<AccessiblePlace>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            Future<void> toggle(
              AccessibleRoutingPrefs Function(AccessibleRoutingPrefs) update,
            ) async {
              final next = update(_routingPrefs);
              await _saveRoutingPrefs(next);
              setModal(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan accessible route',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pick a destination. Routing uses your accessibility prefs.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final mode in PreferredTransportMode.values)
                          ChoiceChip(
                            selected:
                                _routingPrefs.preferredTransportMode == mode,
                            label: Text(mode.label),
                            onSelected: (_) => toggle(
                              (p) => p.copyWith(preferredTransportMode: mode),
                            ),
                          ),
                        FilterChip(
                          selected: _routingPrefs.wheelchairFriendly,
                          label: const Text('Wheelchair routing'),
                          onSelected: (v) =>
                              toggle((p) => p.copyWith(wheelchairFriendly: v)),
                        ),
                        FilterChip(
                          selected: _routingPrefs.avoidStairs,
                          label: const Text('No stairs'),
                          onSelected: (v) =>
                              toggle((p) => p.copyWith(avoidStairs: v)),
                        ),
                        FilterChip(
                          selected: _routingPrefs.preferElevators,
                          label: const Text('Elevators'),
                          onSelected: (v) =>
                              toggle((p) => p.copyWith(preferElevators: v)),
                        ),
                        FilterChip(
                          selected: _routingPrefs.avoidSteepSlopes,
                          label: const Text('Gentle slopes'),
                          onSelected: (v) =>
                              toggle((p) => p.copyWith(avoidSteepSlopes: v)),
                        ),
                        FilterChip(
                          selected: _routingPrefs.avoidRoughTerrain,
                          label: const Text('Smooth surfaces'),
                          onSelected: (v) =>
                              toggle((p) => p.copyWith(avoidRoughTerrain: v)),
                        ),
                        FilterChip(
                          selected: _routingPrefs.preferQuiet,
                          label: const Text('Quiet'),
                          onSelected: (v) =>
                              toggle((p) => p.copyWith(preferQuiet: v)),
                        ),
                        FilterChip(
                          selected: _routingPrefs.preferSafe,
                          label: const Text('Safer'),
                          onSelected: (v) =>
                              toggle((p) => p.copyWith(preferSafe: v)),
                        ),
                      ],
                    ),
                    if (!_accessibleRouting.hasOrsKey) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Wheelchair graph + slope/surface filters need ORS_API_KEY. Barrier detours and step-free vias still apply.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          for (final p in places.take(12))
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _scoreColor(
                                  p.score,
                                ).withValues(alpha: 0.15),
                                child: Icon(
                                  p.placeCategory.icon,
                                  color: p.placeCategory.color,
                                ),
                              ),
                              title: Text(p.name),
                              subtitle: Text(
                                _userLatLng == null
                                    ? p.categoryLabel
                                    : '${p.distanceLabel(_userLatLng!.latitude, _userLatLng!.longitude)} · ${p.categoryLabel}',
                              ),
                              onTap: () => Navigator.pop(ctx, p),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (picked != null) await _routeTo(picked);
  }

  Future<void> _startNavigation(
    AccessiblePlace place,
    WalkingRoute route,
  ) async {
    final profile = await _auth.getCurrentProfile();
    final prefs = UxPrefs.fromProfile(profile);
    await _navigation.start(
      route: route,
      destinationName: place.name,
      voiceEnabled: prefs.voiceNavigation || prefs.screenReader,
      ttsLanguage: prefs.ttsCode,
    );
    if (!mounted) return;
    _toast(
      (prefs.voiceNavigation || prefs.screenReader)
          ? 'Turn-by-turn with voice guidance started'
          : 'Turn-by-turn navigation started · tap speaker to enable voice',
    );
  }

  Future<void> _stopNavigation() async {
    final route = _navigation.route ?? _route;
    final place = _selected;
    final meters = route?.meters ?? 0;
    await _navigation.stop();
    if (meters > 0 && place != null) {
      unawaited(
        UserActivityService().recordTrip(
          meters: meters,
          destinationName: place.name,
          placeId: place.id,
        ),
      );
    }
    if (mounted) setState(() => _navState = null);
  }

  Future<void> _shareRouteWithCareCircle() async {
    final route = _route;
    final place = _selected;
    if (route == null || place == null) {
      _toast('Plan a route first, then share it.');
      return;
    }
    try {
      final profile = await _auth.getCurrentProfile();
      final origin = _userLatLng;
      await CareCircleService().shareRoute(
        CareSharedRoute.payloadFromWalkingRoute(
          route: route,
          destinationName: place.name,
          destinationPlaceId: place.id,
          createdByName: profile?.displayName ?? 'You',
          fromLat: origin?.latitude,
          fromLng: origin?.longitude,
        ),
      );
      if (!mounted) return;
      _toast('Route shared with Care Circle');
    } catch (e) {
      if (mounted) _toast('$e');
    }
  }

  Future<void> _navigate(List<AccessiblePlace> places) async {
    final target = _selected ?? (places.isEmpty ? null : places.first);
    if (target == null) {
      _toast('No destination nearby.');
      return;
    }
    await _routeTo(target);
  }

  void _openFilters() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Smart filters',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: _openNowOnly,
                        label: const Text('Open now'),
                        avatar: const Icon(Icons.schedule_rounded, size: 16),
                        onSelected: (on) {
                          setState(() => _openNowOnly = on);
                          setModal(() {});
                        },
                      ),
                      FilterChip(
                        selected: _alwaysOpenOnly,
                        label: const Text('24/7 access'),
                        avatar: const Icon(
                          Icons.hourglass_bottom_rounded,
                          size: 16,
                        ),
                        onSelected: (on) {
                          setState(() => _alwaysOpenOnly = on);
                          setModal(() {});
                        },
                      ),
                      FilterChip(
                        selected: _fullyAccessibleOnly,
                        label: const Text('Fully accessible'),
                        avatar: const Icon(Icons.verified_rounded, size: 16),
                        onSelected: (on) {
                          setState(() => _fullyAccessibleOnly = on);
                          setModal(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Place type',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        selected: _placeTypeFilter == null,
                        label: const Text('All types'),
                        onSelected: (_) {
                          setState(() => _placeTypeFilter = null);
                          setModal(() {});
                        },
                      ),
                      for (final cat in PlaceCategory.smartFilters)
                        FilterChip(
                          selected: _placeTypeFilter == cat.id,
                          label: Text(cat.label),
                          avatar: Icon(cat.icon, size: 16),
                          onSelected: (on) {
                            setState(() {
                              _placeTypeFilter = on ? cat.id : null;
                            });
                            setModal(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Accessibility features',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _amenityChips)
                        FilterChip(
                          selected: _amenities.contains(item.$2),
                          label: Text(item.$3),
                          avatar: Icon(item.$1, size: 16),
                          onSelected: (on) {
                            setState(() {
                              if (on) {
                                _amenities.add(item.$2);
                              } else {
                                _amenities.remove(item.$2);
                              }
                            });
                            setModal(() {});
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _amenities.clear();
                        _placeTypeFilter = null;
                        _fullyAccessibleOnly = false;
                        _openNowOnly = false;
                        _alwaysOpenOnly = false;
                      });
                      setModal(() {});
                    },
                    child: const Text('Clear filters'),
                  ),
                  if (_recent.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent searches',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _clearRecent();
                            setModal(() {});
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final q in _recent.take(8))
                          ActionChip(
                            label: Text(q),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openRecent(q, _lastPlaces);
                            },
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openLayerSwitcher() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Map layers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Standard, satellite, or terrain',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < MapBasemap.all.length; i++)
                        ChoiceChip(
                          selected: _selectedLayer == i,
                          avatar: Icon(MapBasemap.all[i].icon, size: 16),
                          label: Text(MapBasemap.all[i].label),
                          onSelected: (_) async {
                            await _selectBasemap(i);
                            setModal(() {});
                            if (ctx.mounted) Navigator.pop(ctx);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _showLegend,
                    onChanged: (v) {
                      setState(() => _showLegend = v);
                      setModal(() {});
                    },
                    title: const Text('Show score legend'),
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.download_for_offline_rounded),
                    title: const Text('Offline city packs'),
                    subtitle: const Text(
                      'Download tiles to browse without Wi-Fi',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TileCacheScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alt_route_rounded),
                    title: const Text('Plan accessible route'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _planRoute(_filtered(_lastPlaces));
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.navigation_rounded),
                    title: const Text('Start navigation'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _navigate(_filtered(_lastPlaces));
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.route_rounded),
                    title: const Text('Saved routes'),
                    subtitle: const Text(
                      'Replay planned routes without network',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              SavedRoutesScreen(onOpenRoute: _openCachedRoute),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _scoreColor(int score) {
    if (score >= 90) return const Color(0xFF22C55E);
    if (score >= 70) return const Color(0xFFEAB308);
    if (score >= 40) return const Color(0xFFF97316);
    if (score > 0) return const Color(0xFFEF4444);
    return const Color(0xFF9CA3AF);
  }

  void _showPlaceSheet(AccessiblePlace place) {
    setState(() => _selected = place);
    _rememberRecent(place.name);
    unawaited(LocalPlaceCache.instance.pushRecent(place));
    unawaited(
      UserActivityService().recordVisit(
        placeId: place.id,
        placeName: place.name,
        category: place.category,
      ),
    );
    _mapController.move(LatLng(place.lat, place.lng), 15);
    final origin = _userLatLng;
    PlaceDetailSheet.show(
      context,
      place: place,
      isFavorite: _favoriteIds.contains(place.id),
      distanceLabel: origin == null
          ? null
          : place.distanceLabel(origin.latitude, origin.longitude),
      onFavorite: () => _toggleFavorite(place),
      onAddToList: () =>
          FavoriteListSheet.show(context, placeId: place.id, places: _places),
      onShowRoute: (route) async {
        unawaited(
          LocalRouteCache.instance.save(destination: place, route: route),
        );
        await _applyRoute(place, route);
      },
      onSummarize: () {
        Navigator.pop(context);
        showPlaceAiSummary(context, place);
      },
    ).whenComplete(() {
      if (mounted) setState(() => _selected = null);
    });
  }

  void _maybeOpenInitial(List<AccessiblePlace> places) {
    final id = widget.initialPlaceId;
    if (id == null || _openedInitial) return;
    AccessiblePlace? match;
    for (final p in places) {
      if (p.id == id) {
        match = p;
        break;
      }
    }
    if (match == null) return;
    _openedInitial = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showPlaceSheet(match!);
    });
  }

  bool get _moreFiltersActive =>
      _amenities.isNotEmpty ||
      _placeTypeFilter != null ||
      _openNowOnly ||
      _alwaysOpenOnly ||
      _fullyAccessibleOnly;

  String _distanceKmLabel(AccessiblePlace place) {
    final origin = _userLatLng ??
        LatLng(
          PlacesService.defaultOriginLat,
          PlacesService.defaultOriginLng,
        );
    return '${place.distanceKm(origin.latitude, origin.longitude).toStringAsFixed(1)} km';
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsInboxScreen()),
    );
  }

  void _scrollToNearby() {
    final ctx = _nearbySectionKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      alignment: 0.08,
    );
  }

  void _openAddPlace() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen()));
  }

  void _openAllNearby(List<AccessiblePlace> places) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.4,
          maxChildSize: 0.94,
          builder: (_, scroll) {
            return ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: places.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Text(
                    'Nearby Places',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  );
                }
                final place = places[i - 1];
                return MapHubNearbyCard(
                  place: place,
                  distanceLabel: _distanceKmLabel(place),
                  iconColor: place.placeCategory.color,
                  icon: place.placeCategory.icon,
                  isFavorite: _favoriteIds.contains(place.id),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showPlaceSheet(place);
                  },
                  onFavorite: () => _toggleFavorite(place),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _embeddedMap(List<AccessiblePlace> places, {required bool loading}) {
    final activeLayer = _activeBasemap;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 13.5,
                onMapReady: _onMapReady,
              ),
              children: [
                TileLayer(
                  key: ValueKey(activeLayer.urlTemplate),
                  urlTemplate: activeLayer.urlTemplate,
                  subdomains: activeLayer.subdomains,
                  maxZoom: activeLayer.maxZoom,
                  maxNativeZoom: activeLayer.maxZoom.round(),
                  userAgentPackageName: 'com.abilitylink.app',
                  tileProvider:
                      OfflineFirstTileProvider.supportsOfflineCache(activeLayer)
                      ? _offlineTileProvider
                      : NetworkTileProvider(
                          headers: {'User-Agent': 'com.abilitylink.app'},
                        ),
                ),
                if (_userLatLng != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _userLatLng!,
                        radius: 56,
                        color: const Color(0x332563EB),
                        borderStrokeWidth: 0,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (_userLatLng != null)
                      Marker(
                        point: _userLatLng!,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x402563EB),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    for (final place in places)
                      Marker(
                        point: LatLng(place.lat, place.lng),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => _showPlaceSheet(place),
                          child: _MapPin(
                            color: _scoreColor(place.score),
                            icon: place.placeCategory.icon,
                            selected: _selected?.id == place.id,
                          ),
                        ),
                      ),
                  ],
                ),
                if (_route != null && _route!.points.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _route!.points,
                        color: AppColors.primary,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                if (_route != null && _route!.steps.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < _route!.steps.length; i++)
                        Marker(
                          point: _route!.steps[i].location,
                          width: 34,
                          height: 34,
                          child: _DirectionMarker(
                            style: RouteDirectionStyle.forStep(
                              _route!.steps[i],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: MapHubStatusChip(onLongPress: _openLayerSwitcher),
          ),
          if (_showLegend)
            const Positioned(left: 10, top: 46, child: MapScoreLegend()),
          Positioned(
            right: 10,
            bottom: 10,
            child: Column(
              children: [
                MapHubRoundFab(
                  icon: Icons.my_location_rounded,
                  onTap: _locating ? () {} : () => _goToMyLocation(),
                ),
                const SizedBox(height: 8),
                MapHubRoundFab(
                  icon: Icons.format_list_bulleted_rounded,
                  onTap: _scrollToNearby,
                ),
              ],
            ),
          ),
          if (loading || _seeding || _routing)
            const Center(child: CircularProgressIndicator()),
          if (activeLayer.attribution.isNotEmpty)
            Positioned(
              left: 8,
              bottom: 8,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: Text(
                      activeLayer.attribution,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _auth.watchCurrentProfile(),
      builder: (context, profileSnap) {
        final city = profileSnap.data?.city;
        final locationLabel =
            (city != null && city.isNotEmpty && city != 'Location not set')
            ? city
            : 'Abbottabad, Pakistan';

        return StreamBuilder<List<AccessiblePlace>>(
          stream: _places.watchPlaces(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <AccessiblePlace>[];
            _lastPlaces = all;
            _maybeOpenInitial(all);
            final places = _filtered(all);
            final nearby = places.take(3).toList();
            final loading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

            return Scaffold(
              backgroundColor: Colors.white,
              body: Stack(
                children: [
                  SafeArea(
                    bottom: false,
                    child: CustomScrollView(
                      controller: _hubScroll,
                      slivers: [
                        SliverToBoxAdapter(
                          child: MapHubHeader(
                            showBack: widget.showBack,
                            onBack: () => Navigator.of(context).maybePop(),
                            locationLabel: locationLabel,
                            onLocation: () => _goToMyLocation(),
                            onNotify: _openNotifications,
                          ),
                        ),
                        const SliverToBoxAdapter(child: MapHubHero()),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                            child: MapHubSearchBar(
                              controller: _search,
                              onChanged: () => setState(() {}),
                              onSubmitted: (q) => _handleSearchSubmit(q, all),
                              onFilter: _openFilters,
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 86,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                              itemCount: _categories.length + 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index == _categories.length) {
                                  return MapHubCategoryChip(
                                    icon: Icons.more_horiz_rounded,
                                    label: 'More',
                                    selected: _moreFiltersActive,
                                    onTap: _openFilters,
                                    fg: const Color(0xFF6B7280),
                                  );
                                }
                                final cat = _categories[index];
                                return MapHubCategoryChip(
                                  icon: cat.$1,
                                  label: cat.$3,
                                  selected: _selectedCategory == index,
                                  onTap: () =>
                                      setState(() => _selectedCategory = index),
                                  fg: cat.$4,
                                  parkingBadge: cat.$2 == 'parking',
                                );
                              },
                            ),
                          ),
                        ),
                        if (_route != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Walking ${_route!.distanceLabel} · ${_route!.durationLabel}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _route = null),
                                    child: const Text('Clear route'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: SizedBox(
                              height: 236,
                              child: _embeddedMap(places, loading: loading),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            key: _nearbySectionKey,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Nearby Places',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _openAllNearby(places),
                                  child: Text(
                                    'View all',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (nearby.isEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  if (!snapshot.hasError)
                                    Image.asset(
                                      'assets/images/empty_states/empty_search.png',
                                      width: 96,
                                      height: 96,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    snapshot.hasError
                                        ? 'Could not load places. Check connection.'
                                        : 'No places match this filter.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverList.separated(
                              itemCount: nearby.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final place = nearby[i];
                                return MapHubNearbyCard(
                                  place: place,
                                  distanceLabel: _distanceKmLabel(place),
                                  iconColor: place.placeCategory.color,
                                  icon: place.placeCategory.icon,
                                  isFavorite: _favoriteIds.contains(place.id),
                                  onTap: () => _showPlaceSheet(place),
                                  onFavorite: () => _toggleFavorite(place),
                                );
                              },
                            ),
                          ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                            child: MapHubAddPlaceBanner(onTap: _openAddPlace),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_navState?.active == true)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: MediaQuery.sizeOf(context).height * 0.12,
                      child: NavigationOverlay(
                        state: _navState!,
                        onStop: _stopNavigation,
                        onToggleVoice: (v) => _navigation.setVoiceEnabled(v),
                        onRepeat: () => _navigation.repeatInstruction(),
                        onShareWithCare: _shareRouteWithCareCircle,
                        onRecenter: _userLatLng == null
                            ? null
                            : () => _moveCamera(_userLatLng!, 16),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.color,
    required this.icon,
    required this.selected,
  });

  final Color color;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: selected ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: selected ? 8 : 4,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: selected ? 18 : 16),
    );
  }
}

class _DirectionMarker extends StatelessWidget {
  const _DirectionMarker({required this.style});

  final RouteDirectionStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: style.color, width: 2.5),
        boxShadow: [
          BoxShadow(color: style.color.withValues(alpha: 0.35), blurRadius: 4),
        ],
      ),
      child: Icon(style.icon, color: style.color, size: 18),
    );
  }
}
