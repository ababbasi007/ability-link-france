import '../../../services/background_task.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/place.dart';
import '../../../services/location_service.dart';
import '../../../services/places_service.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/decoded_network_image.dart';

class NearbyPlacesSection extends StatefulWidget {
  const NearbyPlacesSection({
    super.key,
    required this.onViewAll,
    required this.onPlace,
    this.onOpenMap,
  });

  final VoidCallback onViewAll;
  final ValueChanged<AccessiblePlace> onPlace;
  final VoidCallback? onOpenMap;

  @override
  State<NearbyPlacesSection> createState() => _NearbyPlacesSectionState();
}

class _NearbyPlacesSectionState extends State<NearbyPlacesSection> {
  final _places = PlacesService();
  final _location = LocationService.instance;
  StreamSubscription<AppLatLng>? _locSub;
  AppLatLng _origin = LocationService.instance.current;

  @override
  void initState() {
    super.initState();
    runInBackground(_places.ensureSeeded(), 'seed places');
    _locSub = _location.stream.listen((loc) {
      if (mounted) setState(() => _origin = loc);
    });
    _location.ensure();
  }

  @override
  void dispose() {
    _locSub?.cancel();
    super.dispose();
  }

  List<(IconData, Color)> _featureIcons(AccessiblePlace place) {
    const palette = <String, (IconData, Color)>{
      'ramp': (Icons.accessible_rounded, Color(0xFF006D44)),
      'stepFree': (Icons.accessible_rounded, Color(0xFF006D44)),
      'elevator': (Icons.elevator_rounded, Color(0xFF006D44)),
      'toilet': (Icons.wc_rounded, Color(0xFF006D44)),
      'parking': (Icons.local_parking_rounded, Color(0xFF006D44)),
      'hearing': (Icons.hearing_rounded, Color(0xFF006D44)),
      'visual': (Icons.visibility_rounded, Color(0xFF006D44)),
      'braille': (Icons.touch_app_rounded, Color(0xFF006D44)),
      'signLanguage': (Icons.front_hand_rounded, Color(0xFF006D44)),
      'wifi': (Icons.wifi_rounded, Color(0xFF006D44)),
    };
    final out = <(IconData, Color)>[];
    for (final f in place.features) {
      final m = palette[f];
      if (m != null) out.add(m);
      if (out.length >= 4) break;
    }
    if (out.isEmpty) {
      out.add((Icons.accessible_rounded, const Color(0xFF006D44)));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Nearby Accessible Places',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onViewAll,
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AccessiblePlace>>(
          stream: _places.watchPlaces(limit: 80),
          builder: (context, snap) {
            final places = _places.search(
              snap.data ?? const [],
              sort: PlaceSort.distance,
              originLat: _origin.lat,
              originLng: _origin.lng,
            );
            final shown = places.take(6).toList();
            final items = shown.isNotEmpty ? shown : _fallbackPlaces;
            return SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (context, i) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  if (shown.isNotEmpty) {
                    return _PlaceCard(
                      name: shown[i].name,
                      category: shown[i].categoryLabel,
                      distance: shown[i].distanceLabel(_origin.lat, _origin.lng),
                      rating: shown[i].rating.toStringAsFixed(1),
                      image: shown[i].imageUrl,
                      features: _featureIcons(shown[i]),
                      onTap: () => widget.onPlace(shown[i]),
                    );
                  } else {
                    final f = _fallbackPlaces[i];
                    return _PlaceCard(
                      name: f.$1,
                      category: f.$2,
                      distance: f.$3,
                      rating: f.$4,
                      image: '',
                      features: const [
                        (Icons.accessible_rounded, Color(0xFF006D44)),
                        (Icons.local_parking_rounded, Color(0xFF006D44)),
                        (Icons.wifi_rounded, Color(0xFF006D44)),
                        (Icons.elevator_rounded, Color(0xFF006D44)),
                      ],
                      onTap: widget.onViewAll,
                    );
                  }
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

const _fallbackPlaces = [
  ('Café Joyeux', 'Café', '0.3 km', '4.6'),
  ('Louvre Museum', 'Museum', '1.2 km', '4.8'),
  ('Access Hospital', 'Hospital', '0.8 km', '4.7'),
];

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.name,
    required this.category,
    required this.distance,
    required this.rating,
    required this.image,
    required this.features,
    required this.onTap,
  });

  final String name;
  final String category;
  final String distance;
  final String rating;
  final String image;
  final List<(IconData, Color)> features;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 155,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  SizedBox(
                    width: 155,
                    height: 110,
                    child: image.isEmpty
                        ? Container(
                            color: AppColors.primaryLight,
                            child: const Icon(
                              Icons.place_rounded,
                              color: AppColors.primary,
                              size: 40,
                            ),
                          )
                        : DecodedNetworkImage(
                            image,
                            width: 155,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 10, color: Colors.white),
                          const SizedBox(width: 2),
                          Text(
                            rating,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_border_rounded,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$distance · $category',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (final f in features.take(4))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: f.$2.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(f.$1, size: 13, color: f.$2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
