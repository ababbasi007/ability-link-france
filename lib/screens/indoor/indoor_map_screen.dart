import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/indoor_venue.dart';
import '../../models/route_direction_style.dart';
import '../../models/ux_prefs.dart';
import '../../services/auth_service.dart';
import '../../services/indoor_navigation_service.dart';
import '../../services/voice_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/ux_scope.dart';

class IndoorMapScreen extends StatefulWidget {
  const IndoorMapScreen({
    super.key,
    this.venueId,
    this.placeId,
    this.initialFromId,
    this.initialToId,
  });

  final String? venueId;
  final String? placeId;
  final String? initialFromId;
  final String? initialToId;

  @override
  State<IndoorMapScreen> createState() => _IndoorMapScreenState();
}

class _IndoorMapScreenState extends State<IndoorMapScreen> {
  final _nav = IndoorNavigationService();
  final _auth = AuthService();
  final _voice = VoiceService.instance;

  late IndoorVenue _venue;
  late String _floorId;
  IndoorNode? _from;
  IndoorNode? _to;
  IndoorRoute? _route;
  bool _accessibleOnly = true;
  bool _voiceGuidance = false;
  String _ttsLanguage = 'en-US';
  IndoorPoiKind? _filterKind;

  @override
  void initState() {
    super.initState();
    final venues = _nav.venues;
    _venue = _nav.venueById(widget.venueId ?? '') ??
        _nav.venueForPlace(widget.placeId ?? '') ??
        venues.first;
    _floorId = _venue.floors.first.id;
    _from = _venue.nodeById(widget.initialFromId ?? '') ??
        _venue.nodesOfKind(IndoorPoiKind.entrance).firstOrNull ??
        _venue.nodes.first;
    _to = _venue.nodeById(widget.initialToId ?? '');
    if (_from != null) _floorId = _from!.floorId;
    _loadVoicePrefs();
    _recompute();
  }

  @override
  void dispose() {
    _voice.stopSpeaking();
    CaptionBus.clear();
    super.dispose();
  }

  Future<void> _loadVoicePrefs() async {
    final profile = await _auth.getCurrentProfile();
    final prefs = UxPrefs.fromProfile(profile);
    if (!mounted) return;
    setState(() {
      _voiceGuidance = prefs.voiceNavigation || prefs.screenReader;
      _ttsLanguage = prefs.ttsCode;
    });
  }

  void _recompute() {
    final from = _from;
    final to = _to;
    if (from == null || to == null) {
      setState(() => _route = null);
      return;
    }
    setState(() {
      _route = _nav.route(
        venue: _venue,
        fromNodeId: from.id,
        toNodeId: to.id,
        preferAccessible: _accessibleOnly,
      );
    });
    _announceRoute();
  }

  Future<void> _announceRoute({bool force = false}) async {
    if (!_voiceGuidance && !force) return;
    final route = _route;
    if (route == null || route.steps.isEmpty) return;
    final lines = <String>[
      for (final s in route.steps.take(6)) s.instruction,
    ];
    if (route.steps.length > 6) {
      lines.add('${route.steps.length - 6} more steps');
    }
    final text = lines.join('. ');
    CaptionBus.set(text);
    await _voice.speak(text, languageCode: _ttsLanguage);
  }

  void _evacuate() {
    final from = _from;
    if (from == null) return;
    final r = _nav.evacuate(
      venue: _venue,
      fromNodeId: from.id,
      preferAccessible: _accessibleOnly,
    );
    if (r == null || r.nodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No evacuation path found')),
      );
      return;
    }
    setState(() {
      _to = r.nodes.last;
      _route = r;
      _floorId = from.floorId;
    });
    _announceRoute();
  }

  Future<void> _pickNode({required bool pickingFrom}) async {
    final floorNodes = _venue.nodesOnFloor(_floorId);
    final all = [...floorNodes, ..._venue.nodes.where((n) => n.floorId != _floorId)];
    final picked = await showModalBottomSheet<IndoorNode>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.65,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    pickingFrom ? 'Start from' : 'Go to',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: all.length,
                    itemBuilder: (_, i) {
                      final n = all[i];
                      final floor = _venue.floorById(n.floorId)?.label ?? '';
                      return ListTile(
                        leading: Icon(n.kind.icon, color: n.kind.color),
                        title: Text(n.name),
                        subtitle: Text('$floor · ${n.kind.label}'),
                        trailing: n.accessible
                            ? null
                            : const Icon(Icons.block, size: 16),
                        onTap: () => Navigator.pop(ctx, n),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (pickingFrom) {
        _from = picked;
        _floorId = picked.floorId;
      } else {
        _to = picked;
      }
    });
    _recompute();
  }

  @override
  Widget build(BuildContext context) {
    final floorNodes = [
      for (final n in _venue.nodesOnFloor(_floorId))
        if (_filterKind == null || n.kind == _filterKind) n,
    ];
    final routeOnFloor = [
      for (final n in _route?.nodes ?? const <IndoorNode>[])
        if (n.floorId == _floorId) n,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indoor map',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            Text(
              _venue.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          if (_nav.venues.length > 1)
            PopupMenuButton<String>(
              tooltip: 'Switch venue',
              onSelected: (id) {
                final v = _nav.venueById(id);
                if (v == null) return;
                setState(() {
                  _venue = v;
                  _floorId = v.floors.first.id;
                  _from = v.nodesOfKind(IndoorPoiKind.entrance).isNotEmpty
                      ? v.nodesOfKind(IndoorPoiKind.entrance).first
                      : v.nodes.first;
                  _to = null;
                  _route = null;
                });
              },
              itemBuilder: (_) => [
                for (final v in _nav.venues)
                  PopupMenuItem(value: v.id, child: Text(v.name)),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Floor selector
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              itemCount: _venue.floors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _venue.floors[i];
                final selected = f.id == _floorId;
                return ChoiceChip(
                  selected: selected,
                  label: Text(f.label),
                  avatar: Icon(
                    Icons.layers_rounded,
                    size: 16,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : AppColors.textPrimary,
                  ),
                  onSelected: (_) => setState(() => _floorId = f.id),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _venue.floorById(_floorId)?.subtitle ?? '',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // POI filter chips
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                FilterChip(
                  selected: _filterKind == null,
                  label: const Text('All'),
                  onSelected: (_) => setState(() => _filterKind = null),
                ),
                const SizedBox(width: 6),
                for (final k in const [
                  IndoorPoiKind.elevator,
                  IndoorPoiKind.restroom,
                  IndoorPoiKind.exit,
                  IndoorPoiKind.reception,
                  IndoorPoiKind.help,
                  IndoorPoiKind.room,
                ]) ...[
                  FilterChip(
                    selected: _filterKind == k,
                    avatar: Icon(k.icon, size: 14, color: k.color),
                    label: Text(k.label.split(' ').first),
                    onSelected: (on) => setState(() {
                      _filterKind = on ? k : null;
                    }),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Floor plan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onTapUp: (d) {
                          // Snap tap to nearest node on this floor.
                          final w = constraints.maxWidth;
                          final h = constraints.maxHeight;
                          final tx = d.localPosition.dx / w;
                          final ty = d.localPosition.dy / h;
                          IndoorNode? nearest;
                          var best = 0.12;
                          for (final n in _venue.nodesOnFloor(_floorId)) {
                            final dx = n.x - tx;
                            final dy = n.y - ty;
                            final dist = dx * dx + dy * dy;
                            if (dist < best) {
                              best = dist;
                              nearest = n;
                            }
                          }
                          if (nearest == null) return;
                          setState(() {
                            if (_from == null || (_from != null && _to != null)) {
                              _from = nearest;
                              _to = null;
                              _route = null;
                            } else {
                              _to = nearest;
                            }
                          });
                          if (_from != null && _to != null) _recompute();
                        },
                        child: CustomPaint(
                          painter: _FloorPlanPainter(
                            nodes: floorNodes,
                            routeNodes: routeOnFloor,
                            fromId: _from?.id,
                            toId: _to?.id,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // From / to
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickNode(pickingFrom: true),
                    child: Text(
                      _from == null ? 'From…' : 'From: ${_from!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickNode(pickingFrom: false),
                    child: Text(
                      _to == null ? 'To…' : 'To: ${_to!.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  selected: _accessibleOnly,
                  label: const Text('Step-free / elevators'),
                  onSelected: (v) {
                    setState(() => _accessibleOnly = v);
                    _recompute();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _voiceGuidance,
                  avatar: Icon(
                    _voiceGuidance
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    size: 16,
                  ),
                  label: const Text('Voice'),
                  onSelected: (v) async {
                    setState(() => _voiceGuidance = v);
                    if (v) {
                      await _announceRoute(force: true);
                    } else {
                      await _voice.stopSpeaking();
                      CaptionBus.clear();
                    }
                  },
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _evacuate,
                  icon: const Icon(Icons.emergency_outlined, size: 18),
                  label: const Text('Evacuate'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.sos),
                ),
              ],
            ),
          ),
          if (_route != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Route · ${_route!.distanceLabel}'
                          '${_route!.accessible ? ' · accessible' : ' · may include stairs'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Speak route',
                        onPressed: () => _announceRoute(force: true),
                        icon: const Icon(Icons.record_voice_over_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._route!.steps.take(5).map((s) {
                    final style = RouteDirectionStyle.forInstruction(
                      s.instruction,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(style.icon, size: 18, color: style.color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${s.instruction}'
                              '${s.meters > 0 ? ' (${s.meters.round()} m)' : ''}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          RouteDirectionChip(style: style, compact: true),
                        ],
                      ),
                    );
                  }),
                  if (_route!.steps.length > 5)
                    Text(
                      '+ ${_route!.steps.length - 5} more steps',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on List<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

class _FloorPlanPainter extends CustomPainter {
  _FloorPlanPainter({
    required this.nodes,
    required this.routeNodes,
    this.fromId,
    this.toId,
  });

  final List<IndoorNode> nodes;
  final List<IndoorNode> routeNodes;
  final String? fromId;
  final String? toId;

  @override
  void paint(Canvas canvas, Size size) {
    // Soft corridor grid
    final grid = Paint()
      ..color = const Color(0xFFD5E5DC)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      final y = size.height * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Route polyline
    if (routeNodes.length >= 2) {
      final path = Path();
      for (var i = 0; i < routeNodes.length; i++) {
        final n = routeNodes[i];
        final o = Offset(n.x * size.width, n.y * size.height);
        if (i == 0) {
          path.moveTo(o.dx, o.dy);
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    for (final n in nodes) {
      final c = Offset(n.x * size.width, n.y * size.height);
      final selected = n.id == fromId || n.id == toId;
      canvas.drawCircle(
        c,
        selected ? 14 : 11,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        c,
        selected ? 11 : 8,
        Paint()..color = n.kind.color,
      );
      if (!n.accessible) {
        canvas.drawCircle(
          c,
          4,
          Paint()..color = const Color(0xFF6B7280),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter oldDelegate) =>
      oldDelegate.nodes != nodes ||
      oldDelegate.routeNodes != routeNodes ||
      oldDelegate.fromId != fromId ||
      oldDelegate.toId != toId;
}
