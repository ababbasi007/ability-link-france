import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/favorite_list.dart';
import '../../models/place.dart';
import '../../services/local_place_cache.dart';
import '../../services/places_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/place_detail_sheet.dart';
import '../../widgets/favorite_list_sheet.dart';

class FavoriteListsScreen extends StatefulWidget {
  const FavoriteListsScreen({super.key});

  @override
  State<FavoriteListsScreen> createState() => _FavoriteListsScreenState();
}

class _FavoriteListsScreenState extends State<FavoriteListsScreen> {
  final _places = PlacesService();

  List<AccessiblePlace>? _recentPlaces;

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await LocalPlaceCache.instance.loadRecent();
    if (mounted) setState(() => _recentPlaces = recent);
  }

  Future<void> _createList() async {
    final controller = TextEditingController();
    var category = FavoriteList.generalCategory;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('New list'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'List name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Accessibility category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final id in FavoriteList.categoryIds)
                    DropdownMenuItem(
                      value: id,
                      child: Text(FavoriteList.categoryLabel(id)),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) setModal(() => category = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, (controller.text.trim(), category)),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (result == null || result.$1.isEmpty) return;
    try {
      await _places.createFavoriteList(result.$1, category: result.$2);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _renameList(FavoriteList list) async {
    if (list.id == FavoriteList.defaultId) return;
    final controller = TextEditingController(text: list.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename list'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty) return;
    try {
      await _places.renameFavoriteList(listId: list.id, name: name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _deleteList(FavoriteList list) async {
    if (list.id == FavoriteList.defaultId) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${list.name}"?'),
        content: const Text('Places stay saved if they are in another list.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _places.deleteFavoriteList(list.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Favorite lists',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'New list',
            onPressed: _createList,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<FavoriteList>>(
        stream: _places.watchFavoriteLists(),
        builder: (context, snap) {
          final lists = snap.data ?? const [];
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (lists.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/empty_states/empty_favorites.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save your first place',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap the heart on any place to keep it here, or start a list of your own.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _createList,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create a list'),
                    ),
                  ],
                ),
              ),
            );
          }
          final recent = _recentPlaces ?? const <AccessiblePlace>[];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lists.length + (recent.isNotEmpty ? 2 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              // Recent places header + cards prepended above the lists.
              if (recent.isNotEmpty) {
                if (i == 0) {
                  return Text(
                    'Recently viewed',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                if (i <= recent.length) {
                  final p = recent[i - 1];
                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.history_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        p.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(p.categoryLabel),
                      onTap: () => PlaceDetailSheet.show(
                        context,
                        place: p,
                        isFavorite: false,
                        onFavorite: () => _places.toggleFavorite(p.id),
                        onAddToList: () => FavoriteListSheet.show(
                          context,
                          placeId: p.id,
                          places: _places,
                        ),
                      ),
                    ),
                  );
                }
                // Separator between recent and favorite lists sections.
                if (i == recent.length + 1) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Your lists',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
              }

              final listIndex = recent.isNotEmpty ? i - recent.length - 2 : i;
              final list = lists[listIndex];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      list.id == FavoriteList.defaultId
                          ? Icons.favorite_rounded
                          : Icons.folder_special_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(list.name),
                  subtitle: Text(
                    '${FavoriteList.categoryLabel(list.category)} · ${list.count} places'
                    '${list.sharedWithCareCircle ? ' · Shared' : ''}',
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (action) async {
                      try {
                        if (action == 'toggleShared') {
                          await _places.setFavoriteListShared(
                            listId: list.id,
                            shared: !list.sharedWithCareCircle,
                          );
                        }
                        if (action == 'rename') _renameList(list);
                        if (action == 'delete') _deleteList(list);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    },
                    itemBuilder: (_) {
                      final sharedAction = list.sharedWithCareCircle
                          ? 'Unshare from care circle'
                          : 'Share with care circle';
                      return [
                        PopupMenuItem(
                          value: 'toggleShared',
                          child: Text(sharedAction),
                        ),
                        if (list.id != FavoriteList.defaultId) ...[
                          const PopupMenuItem(
                            value: 'rename',
                            child: Text('Rename'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ];
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
