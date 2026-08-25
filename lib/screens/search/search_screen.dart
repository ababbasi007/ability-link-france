import '../../services/background_task.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/benefit_scheme.dart';
import '../../models/community.dart';
import '../../models/education_program.dart';
import '../../models/global_search.dart';
import '../../models/place.dart';
import '../../models/service_provider.dart';
import '../../models/transport_option.dart';
import '../../models/travel_destination.dart';
import '../../services/community_service.dart';
import '../../services/education_service.dart';
import '../../services/geocode_service.dart';
import '../../services/global_search_service.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/places_service.dart';
import '../../services/travel_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';
import '../../widgets/favorite_list_sheet.dart';
import '../../widgets/place_detail_sheet.dart';
import '../../widgets/place_summary_dialog.dart';
import '../benefits/benefit_detail_screen.dart';
import '../benefits/government_offices_screen.dart';
import '../community/community_group_screen.dart';
import '../community/community_post_screen.dart';
import '../education/education_detail_screen.dart';
import '../map/accessibility_map_screen.dart';
import '../providers/provider_profile_screen.dart';
import '../transport/step_free_route_screen.dart';
import '../travel/travel_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _places = PlacesService();
  final _search = GlobalSearchService();
  final _geocode = GeocodeService();
  final _location = LocationService.instance;
  final _controller = TextEditingController();
  final _focus = FocusNode();

  GlobalSearchKind _scope = GlobalSearchKind.all;
  String _need = 'all';
  final Set<String> _amenities = {};
  bool _openNowOnly = false;
  bool _alwaysOpenOnly = false;
  bool _verifiedOnly = false;
  bool _fullyAccessibleOnly = false;
  double? _maxKm;
  PlaceSort _sort = PlaceSort.distance;
  Set<String> _favoriteIds = {};
  StreamSubscription<Set<String>>? _favSub;
  StreamSubscription<GlobalSearchCatalog>? _catalogSub;
  GlobalSearchCatalog _catalog = const GlobalSearchCatalog();
  final List<String> _recent = [];
  AppLatLng _origin = LocationService.instance.current;
  bool _locating = true;

  static const _amenitiesCatalog = [
    (PlaceAmenities.freeParking, 'Free parking'),
    (PlaceAmenities.parking, 'Parking'),
    (PlaceAmenities.toilet, 'Toilets'),
    (PlaceAmenities.stepFree, 'Step-free'),
    (PlaceAmenities.elevator, 'Elevators'),
    (PlaceAmenities.familyFriendly, 'Family friendly'),
    (PlaceAmenities.petFriendly, 'Pet friendly'),
    (PlaceAmenities.serviceAnimal, 'Service animal'),
    (PlaceAmenities.braille, 'Braille'),
    (PlaceAmenities.hearing, 'Hearing loop'),
    (PlaceAmenities.signLanguage, 'Sign language'),
    (PlaceAmenities.accessibleTransit, 'Transit'),
    (PlaceAmenities.quiet, 'Quiet'),
  ];

  static const _needs = [
    ('all', 'All needs', Icons.accessible_rounded),
    ('wheelchair', 'Wheelchair', Icons.accessible_rounded),
    ('visual', 'Visual', Icons.visibility_rounded),
    ('hearing', 'Hearing', Icons.hearing_rounded),
    ('cognitive', 'Cognitive', Icons.psychology_rounded),
  ];

  static const _distances = [
    (null, 'Any'),
    (0.5, '0.5 km'),
    (1.0, '1 km'),
    (2.0, '2 km'),
    (5.0, '5 km'),
  ];

  static const _scopes = [
    GlobalSearchKind.all,
    GlobalSearchKind.places,
    GlobalSearchKind.doctors,
    GlobalSearchKind.therapists,
    GlobalSearchKind.caregivers,
    GlobalSearchKind.assistants,
    GlobalSearchKind.hotels,
    GlobalSearchKind.restaurants,
    GlobalSearchKind.schools,
    GlobalSearchKind.courses,
    GlobalSearchKind.benefits,
    GlobalSearchKind.transportation,
    GlobalSearchKind.tourism,
    GlobalSearchKind.community,
  ];

  bool get _placeFilters =>
      _scope == GlobalSearchKind.all ||
      _scope == GlobalSearchKind.places ||
      _scope == GlobalSearchKind.transportation;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.initialQuery;
    _favSub = _places.watchFavoriteIds().listen((ids) {
      if (mounted) setState(() => _favoriteIds = ids);
    });
    _catalogSub = _search.watchCatalog().listen((c) {
      if (mounted) setState(() => _catalog = c);
    });
    runInBackground(_search.ensureSeeded(), 'seed search catalogs');
    _resolveLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialQuery.isEmpty) _focus.requestFocus();
    });
  }

  Future<void> _resolveLocation() async {
    setState(() => _locating = true);
    final loc = await _location.ensure(force: true);
    if (!mounted) return;
    setState(() {
      _origin = loc;
      _locating = false;
    });
  }

  @override
  void dispose() {
    _favSub?.cancel();
    _catalogSub?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _rememberQuery(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    setState(() {
      _recent.remove(t);
      _recent.insert(0, t);
      if (_recent.length > 6) _recent.removeLast();
    });
  }

  Future<void> _maybeGeocodeFallback(String query) async {
    final q = query.trim();
    if (q.isEmpty) return;
    final hits = _search.search(
      _catalog,
      query: q,
      scope: _scope,
      need: _need,
      amenities: _amenities,
      openNowOnly: _openNowOnly,
      alwaysOpenOnly: _alwaysOpenOnly,
      verifiedOnly: _verifiedOnly,
      fullyAccessibleOnly: _fullyAccessibleOnly,
      maxKm: _maxKm,
      originLat: _origin.lat,
      originLng: _origin.lng,
      placeSort: _sort,
    );
    if (hits.isNotEmpty) return;

    final geo = await _geocode.searchOne(q, countryCode: 'fr');
    if (!mounted || geo == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccessibilityMapScreen(
          showBack: true,
          initialLat: geo.lat,
          initialLng: geo.lng,
        ),
      ),
    );
  }

  List<GlobalSearchHit> get _hits => _search.search(
    _catalog,
    query: _controller.text,
    scope: _scope,
    need: _need,
    amenities: _amenities,
    openNowOnly: _openNowOnly,
    alwaysOpenOnly: _alwaysOpenOnly,
    verifiedOnly: _verifiedOnly,
    fullyAccessibleOnly: _fullyAccessibleOnly,
    maxKm: _maxKm,
    originLat: _origin.lat,
    originLng: _origin.lng,
    placeSort: _sort,
  );

  Future<void> _openHit(GlobalSearchHit hit) async {
    _rememberQuery(_controller.text);
    final payload = hit.payload;
    if (payload is AccessiblePlace) {
      await _openPlace(payload);
      return;
    }
    if (payload is ServiceProvider) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ProviderProfileScreen(providerId: payload.id, provider: payload),
        ),
      );
      return;
    }
    if (payload is TravelDestination) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TravelDetailScreen(
            destination: payload,
            matchScore: TravelService().matchScore(payload, null),
          ),
        ),
      );
      return;
    }
    if (payload is EducationProgram) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EducationDetailScreen(
            program: payload,
            matchScore: EducationService().matchScore(payload, null),
          ),
        ),
      );
      return;
    }
    if (payload is BenefitScheme) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BenefitDetailScreen(scheme: payload),
        ),
      );
      return;
    }
    if (payload is GovernmentOffice) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GovernmentOfficesScreen(initialQuery: payload.name),
        ),
      );
      return;
    }
    if (payload is TransportOption) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => StepFreeRouteScreen(destination: payload),
        ),
      );
      return;
    }
    if (payload is CommunityPost) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CommunityPostScreen(postId: payload.id),
        ),
      );
      return;
    }
    if (payload is CommunityGroup) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CommunityGroupScreen(groupId: payload.id),
        ),
      );
      return;
    }
    if (payload is CommunityEvent) {
      await _openEvent(payload);
    }
  }

  Future<void> _openEvent(CommunityEvent event) async {
    final community = CommunityService();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${event.whenLabel} · ${event.city}\n${event.venue}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(event.body, style: GoogleFonts.plusJakartaSans(height: 1.4)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await community.toggleRsvp(event);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('RSVP'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPlace(AccessiblePlace place) async {
    await PlaceDetailSheet.show(
      context,
      place: place,
      isFavorite: _favoriteIds.contains(place.id),
      distanceLabel: place.distanceLabel(_origin.lat, _origin.lng),
      onFavorite: () async {
        try {
          await _places.toggleFavorite(place.id);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      },
      onAddToList: () => FavoriteListSheet.show(
        context,
        placeId: place.id,
        places: _places,
      ),
      onViewOnMap: () {
        Navigator.pop(context);
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AccessibilityMapScreen(initialPlaceId: place.id),
          ),
        );
      },
      onSummarize: () {
        Navigator.pop(context);
        showPlaceAiSummary(context, place);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hits = _hits;
    final query = _controller.text;
    final idle =
        query.trim().isEmpty &&
        _scope == GlobalSearchKind.all &&
        _need == 'all' &&
        _amenities.isEmpty &&
        !_openNowOnly &&
        !_alwaysOpenOnly &&
        !_verifiedOnly &&
        !_fullyAccessibleOnly &&
        _maxKm == null &&
        _recent.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildScopeFilters(),
            _buildLocationBar(),
            if (_placeFilters) ...[
              _buildNeedFilters(),
              _buildAmenityFilters(),
              _buildToggles(),
            ] else
              _buildVerifiedRow(),
            Expanded(child: idle ? _buildIdle(hits) : _buildResults(hits)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(List<GlobalSearchHit> hits) {
    if (hits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No matches across ${_scope.label.toLowerCase()}. Try another word or chip.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: hits.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Text(
            '${hits.length} result${hits.length == 1 ? '' : 's'} · ${_scope.label}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          );
        }
        final hit = hits[i - 1];
        return _HitCard(hit: hit, onTap: () => _openHit(hit));
      },
    );
  }

  Widget _buildIdle(List<GlobalSearchHit> hits) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Recent searches',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in _recent)
              ActionChip(
                label: Text(q),
                onPressed: () => setState(() => _controller.text = q),
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFF0F1F3)),
                labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Top matches across Ability Link',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 10),
        for (final hit in hits) ...[
          _HitCard(hit: hit, onTap: () => _openHit(hit)),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0F1F3)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: (_) => setState(() {}),
                onSubmitted: (v) async {
                  _rememberQuery(v);
                  setState(() {});
                  await _maybeGeocodeFallback(v);
                },
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search places, doctors, hotels, benefits…',
                  hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: InputBorder.none,
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF9CA3AF),
                  ),
                  suffixIcon: _controller.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _controller.clear();
                            setState(() {});
                          },
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                style: GoogleFonts.plusJakartaSans(fontSize: 14),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Save this search',
            onPressed: () async {
              try {
                await NotificationService().saveSearch(
                  query: _controller.text,
                  need: _need,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Search saved. Place-match alerts land in Notifications.',
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildScopeFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _scopes.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = _scopes[i];
          final selected = _scope == item;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => setState(() => _scope = item),
            label: Text(item.label),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFF0F1F3),
            ),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF1E1B4B),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildLocationBar() {
    final label = _locating
        ? 'Getting your location…'
        : _origin.fromDevice
        ? 'Using your current location'
        : (_location.lastError ?? 'Using default map area');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: Row(
        children: [
          Icon(
            _origin.fromDevice
                ? Icons.my_location_rounded
                : Icons.location_searching_rounded,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: _locating ? null : _resolveLocation,
            child: Text(
              'Refresh',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _needs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = _needs[i];
          final selected = _need == item.$1;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => setState(() => _need = item.$1),
            avatar: Icon(
              item.$3,
              size: 16,
              color: selected ? Colors.white : AppColors.primary,
            ),
            label: Text(item.$2),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFF0F1F3),
            ),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF1E1B4B),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }

  Widget _buildAmenityFilters() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        itemCount: _amenitiesCatalog.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = _amenitiesCatalog[i];
          final selected = _amenities.contains(item.$1);
          return FilterChip(
            selected: selected,
            onSelected: (on) => setState(() {
              if (on) {
                _amenities.add(item.$1);
              } else {
                _amenities.remove(item.$1);
              }
            }),
            label: Text(item.$2),
            selectedColor: AppColors.primary,
            backgroundColor: Colors.white,
            showCheckmark: false,
            side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFF0F1F3),
            ),
            labelStyle: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF1E1B4B),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerifiedRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _ToggleChip(
          label: 'Verified',
          selected: _verifiedOnly,
          onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
        ),
      ),
    );
  }

  Widget _buildToggles() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        children: [
          Row(
            children: [
              _ToggleChip(
                label: 'Open now',
                selected: _openNowOnly,
                onTap: () => setState(() => _openNowOnly = !_openNowOnly),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: '24/7 access',
                selected: _alwaysOpenOnly,
                onTap: () =>
                    setState(() => _alwaysOpenOnly = !_alwaysOpenOnly),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Fully accessible',
                selected: _fullyAccessibleOnly,
                onTap: () =>
                    setState(() => _fullyAccessibleOnly = !_fullyAccessibleOnly),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _ToggleChip(
                label: 'Verified',
                selected: _verifiedOnly,
                onTap: () => setState(() => _verifiedOnly = !_verifiedOnly),
              ),
              const Spacer(),
              PopupMenuButton<PlaceSort>(
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: PlaceSort.relevance,
                    child: Text('Best match'),
                  ),
                  const PopupMenuItem(
                    value: PlaceSort.distance,
                    child: Text('Nearest'),
                  ),
                  const PopupMenuItem(
                    value: PlaceSort.rating,
                    child: Text('Top rated'),
                  ),
                ],
                child: Row(
                  children: [
                    const Icon(
                      Icons.sort_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      switch (_sort) {
                        PlaceSort.relevance => 'Best match',
                        PlaceSort.distance => 'Nearest',
                        PlaceSort.rating => 'Top rated',
                      },
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _distances.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = _distances[i];
                final selected = _maxKm == item.$1;
                return ChoiceChip(
                  selected: selected,
                  label: Text(item.$2),
                  onSelected: (_) => setState(() => _maxKm = item.$1),
                  selectedColor: AppColors.primaryLight,
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFFF0F1F3),
                  ),
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary
                        : const Color(0xFF6B7280),
                  ),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : const Color(0xFFF0F1F3),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
      ),
    );
  }
}

class _HitCard extends StatelessWidget {
  const _HitCard({required this.hit, required this.onTap});

  final GlobalSearchHit hit;
  final VoidCallback onTap;

  IconData get _icon => switch (hit.kind) {
    GlobalSearchKind.places => Icons.place_rounded,
    GlobalSearchKind.doctors => Icons.medical_services_outlined,
    GlobalSearchKind.therapists => Icons.fitness_center_outlined,
    GlobalSearchKind.caregivers => Icons.volunteer_activism_outlined,
    GlobalSearchKind.assistants => Icons.support_agent_rounded,
    GlobalSearchKind.hotels => Icons.hotel_outlined,
    GlobalSearchKind.restaurants => Icons.restaurant_outlined,
    GlobalSearchKind.schools => Icons.school_outlined,
    GlobalSearchKind.courses => Icons.menu_book_outlined,
    GlobalSearchKind.benefits => Icons.account_balance_outlined,
    GlobalSearchKind.transportation => Icons.directions_transit_rounded,
    GlobalSearchKind.tourism => Icons.travel_explore_outlined,
    GlobalSearchKind.community => Icons.forum_outlined,
    GlobalSearchKind.all => Icons.search_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: hit.imageUrl.isEmpty
                    ? Container(
                        width: 72,
                        height: 72,
                        color: AppColors.primaryLight,
                        child: Icon(_icon, color: AppColors.primary),
                      )
                    : DecodedNetworkImage(
                        hit.imageUrl,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: AppColors.primaryLight,
                          child: Icon(_icon, color: AppColors.primary),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.kind.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      hit.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hit.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }
}
