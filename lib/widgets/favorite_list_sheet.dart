import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/favorite_list.dart';
import '../services/places_service.dart';
import '../screens/favorites/favorite_lists_screen.dart';

/// Pick named lists when saving a place.
class FavoriteListSheet {
  static Future<void> show(
    BuildContext context, {
    required String placeId,
    required PlacesService places,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _FavoriteListSheetBody(
        placeId: placeId,
        places: places,
      ),
    );
  }
}

class _FavoriteListSheetBody extends StatefulWidget {
  const _FavoriteListSheetBody({
    required this.placeId,
    required this.places,
  });

  final String placeId;
  final PlacesService places;

  @override
  State<_FavoriteListSheetBody> createState() => _FavoriteListSheetBodyState();
}

class _FavoriteListSheetBodyState extends State<_FavoriteListSheetBody> {
  final _name = TextEditingController();

  Future<void> _createList() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    try {
      final id = await widget.places.createFavoriteList(name);
      await widget.places.addToFavoriteList(listId: id, placeId: widget.placeId);
      _name.clear();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save to list',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<FavoriteList>>(
              stream: widget.places.watchFavoriteLists(),
              builder: (context, snap) {
                final lists = snap.data ?? const [];
                if (lists.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Loading your lists…'),
                  );
                }
                return Column(
                  children: [
                    for (final list in lists)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(list.name),
                        subtitle: Text(
                          '${FavoriteList.categoryLabel(list.category)} · ${list.count} places',
                        ),
                        value: list.placeIds.contains(widget.placeId),
                        onChanged: (on) async {
                          try {
                            if (on == true) {
                              await widget.places.addToFavoriteList(
                                listId: list.id,
                                placeId: widget.placeId,
                              );
                            } else {
                              await widget.places.removeFromFavoriteList(
                                listId: list.id,
                                placeId: widget.placeId,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                      ),
                  ],
                );
              },
            ),
            const Divider(),
            TextField(
              controller: _name,
              decoration: InputDecoration(
                labelText: 'New list name',
                hintText: 'Paris trip, Daily cafes…',
                suffixIcon: IconButton(
                  tooltip: 'Create list',
                  icon: const Icon(Icons.add_rounded),
                  onPressed: _createList,
                ),
              ),
              onSubmitted: (_) => _createList(),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FavoriteListsScreen(),
                    ),
                  );
                },
                child: const Text('Manage lists'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
