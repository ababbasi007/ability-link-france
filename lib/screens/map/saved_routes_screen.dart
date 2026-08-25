import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/local_route_cache.dart';
import '../../theme/app_colors.dart';

/// Lists navigation routes saved on-device for offline replay.
class SavedRoutesScreen extends StatefulWidget {
  const SavedRoutesScreen({
    super.key,
    required this.onOpenRoute,
  });

  final void Function(CachedNavigationRoute route) onOpenRoute;

  @override
  State<SavedRoutesScreen> createState() => _SavedRoutesScreenState();
}

class _SavedRoutesScreenState extends State<SavedRoutesScreen> {
  final _cache = LocalRouteCache.instance;
  List<CachedNavigationRoute> _routes = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final rows = await _cache.loadAll();
    if (!mounted) return;
    setState(() {
      _routes = rows;
      _loading = false;
    });
  }

  Future<void> _delete(CachedNavigationRoute route) async {
    await _cache.delete(route.id);
    await _reload();
  }

  void _open(CachedNavigationRoute route) {
    widget.onOpenRoute(route);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Saved routes',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Plan a route while online and it will appear here for offline navigation.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: _routes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final route = _routes[i];
                return _RouteCard(
                  route: route,
                  onOpen: () => _open(route),
                  onDelete: () => _delete(route),
                );
              },
            ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.onOpen,
    required this.onDelete,
  });

  final CachedNavigationRoute route;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  String get _when {
    final dt = route.savedAt;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Saved just now';
    if (diff.inHours < 1) return 'Saved ${diff.inMinutes} min ago';
    if (diff.inDays < 1) return 'Saved ${diff.inHours} h ago';
    if (diff.inDays < 7) return 'Saved ${diff.inDays} d ago';
    return 'Saved ${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final walking = route.route;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.destinationName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                        Text(
                          '${walking.distanceLabel} · ${walking.durationLabel}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$_when · ${walking.points.length} points · offline ready',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onOpen,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Open on map'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
