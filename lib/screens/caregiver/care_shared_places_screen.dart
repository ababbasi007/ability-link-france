import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/favorite_list.dart';
import '../../models/place.dart';
import '../../services/places_service.dart';
import '../../widgets/place_detail_sheet.dart';
import '../../widgets/favorite_list_sheet.dart';
import '../../theme/app_colors.dart';

class CareSharedPlacesScreen extends StatefulWidget {
  const CareSharedPlacesScreen({super.key});

  @override
  State<CareSharedPlacesScreen> createState() =>
      _CareSharedPlacesScreenState();
}

class _CareSharedPlacesScreenState extends State<CareSharedPlacesScreen> {
  final _places = PlacesService();

  String? _idsKey;
  Future<List<AccessiblePlace>>? _placesFuture;

  Future<List<AccessiblePlace>> _loadPlacesForIds(Set<String> ids) {
    final sorted = ids.toList()..sort();
    final key = sorted.join(',');
    if (_idsKey == key && _placesFuture != null) return _placesFuture!;

    _idsKey = key;
    _placesFuture = _places.fetchPlacesByIds(sorted);
    return _placesFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Shared saved places',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<FavoriteList>>(
        stream: _places.watchFavoriteLists(),
        builder: (context, snap) {
          final lists = snap.data ?? const <FavoriteList>[];
          final sharedIds = <String>{};
          for (final l in lists) {
            if (l.sharedWithCareCircle) {
              sharedIds.addAll(l.placeIds);
            }
          }

          if (lists.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sharedIds.isEmpty) {
            return const Center(child: Text('No shared places yet'));
          }

          return FutureBuilder<List<AccessiblePlace>>(
            future: _loadPlacesForIds(sharedIds),
            builder: (context, placesSnap) {
              if (placesSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final places = placesSnap.data ?? const <AccessiblePlace>[];

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: places.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = places[i];
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.place_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        p.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(p.categoryLabel),
                      onTap: () {
                        PlaceDetailSheet.show(
                          context,
                          place: p,
                          isFavorite: true,
                          onFavorite: () {},
                          onAddToList: () => FavoriteListSheet.show(
                            context,
                            placeId: p.id,
                            places: _places,
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

