import '../../services/background_task.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/transport_option.dart';
import '../../services/location_service.dart';
import '../../services/transport_service.dart';
import '../../theme/app_colors.dart';
import '../map/accessibility_map_screen.dart';
import 'step_free_route_screen.dart';

class TransportHubScreen extends StatefulWidget {
  const TransportHubScreen({super.key});

  @override
  State<TransportHubScreen> createState() => _TransportHubScreenState();
}

class _TransportHubScreenState extends State<TransportHubScreen> {
  final _transport = TransportService();
  final _location = LocationService.instance;
  final _search = TextEditingController();
  String _kind = 'All';
  bool _stepFreeOnly = true;
  AppLatLng _origin = LocationService.instance.current;
  StreamSubscription<AppLatLng>? _locSub;

  @override
  void initState() {
    super.initState();
    runInBackground(_transport.ensureSeeded(), 'seed transport');
    _locSub = _location.stream.listen((loc) {
      if (mounted) setState(() => _origin = loc);
    });
    _location.ensure();
  }

  @override
  void dispose() {
    _locSub?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _report() async {
    final title = TextEditingController();
    final detail = TextEditingController();
    var severity = 'medium';
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report a barrier',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(
                        labelText: 'What’s blocked?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: detail,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Details',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in ['low', 'medium', 'high'])
                          ChoiceChip(
                            label: Text(s),
                            selected: severity == s,
                            onSelected: (_) => setModal(() => severity = s),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Submit alert'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      if (ok != true || !mounted) return;
      if (title.text.trim().isEmpty) return;
      await _transport.reportBarrier(
        title: title.text.trim(),
        detail: detail.text.trim(),
        severity: severity,
        lat: _origin.lat,
        lng: _origin.lng,
        placeName: 'Near current location',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barrier alert posted for others nearby.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      title.dispose();
      detail.dispose();
    }
  }

  void _openOption(TransportOption o) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                o.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${o.kindLabel} · ${o.distanceLabel(_origin.lat, _origin.lng)}'
                '${o.stepFree ? ' · Step-free' : ''}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(o.summary, style: GoogleFonts.plusJakartaSans(height: 1.4)),
              if (o.kind == 'transit') ...[
                const SizedBox(height: 6),
                Text(
                  o.elevatorLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: o.elevatorStatus == 'out'
                        ? const Color(0xFFEF4444)
                        : AppColors.primary,
                  ),
                ),
              ],
              if (o.phone.isNotEmpty) ...[
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: AppColors.primary),
                  title: Text(o.phone),
                  subtitle: const Text('Tap to copy (demo dispatch)'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: o.phone));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied ${o.phone}')),
                    );
                  },
                ),
              ],
              if (o.spaces > 0)
                Text(
                  '${o.spaces} accessible spaces (demo occupancy feed)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in o.features)
                    Chip(
                      label: Text(f),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'API hook: ${o.apiHook.isEmpty ? 'none' : o.apiHook}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AccessibilityMapScreen(
                              initialPlaceId: o.kind == 'transit'
                                  ? 'metro-hub'
                                  : null,
                            ),
                          ),
                        );
                      },
                      child: const Text('Open map'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StepFreeRouteScreen(destination: o),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Step-free route'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Transport & mobility',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Report barrier',
            onPressed: _report,
            icon: const Icon(Icons.report_gmailerrorred_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search stations, bus stops, taxis, EV, parking…',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final k in [
                  ('All', 'All'),
                  ('transit', 'Metro'),
                  ('bus', 'Bus'),
                  ('taxi', 'Taxis'),
                  ('parking', 'Parking'),
                  ('ev', 'EV'),
                ]) ...[
                  FilterChip(
                    label: Text(k.$2),
                    selected: _kind == k.$1,
                    onSelected: (_) => setState(() => _kind = k.$1),
                  ),
                  const SizedBox(width: 8),
                ],
                FilterChip(
                  label: const Text('Step-free'),
                  selected: _stepFreeOnly,
                  onSelected: (v) => setState(() => _stepFreeOnly = v),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Live GPS used for distance. Transit APIs are demo hooks (GTFS / WAV / parking).',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TransportOption>>(
              stream: _transport.watchOptions(),
              builder: (context, snap) {
                final list = _transport.filter(
                  snap.data ?? const [],
                  query: _search.text,
                  kind: _kind,
                  stepFreeOnly: _stepFreeOnly,
                  originLat: _origin.lat,
                  originLng: _origin.lng,
                );
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    StreamBuilder<List<BarrierAlert>>(
                      stream: _transport.watchAlerts(),
                      builder: (context, alertSnap) {
                        final open = (alertSnap.data ?? const <BarrierAlert>[])
                            .where((a) => a.status == 'open')
                            .toList();
                        if (open.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Barrier alerts',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final a in open.take(4))
                              Card(
                                color: a.severity == 'high'
                                    ? const Color(0xFFFFF1F2)
                                    : Colors.white,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.warning_amber_rounded,
                                    color: a.severity == 'high'
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFFF59E0B),
                                  ),
                                  title: Text(
                                    a.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(a.detail),
                                ),
                              ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData)
                      const Center(child: CircularProgressIndicator())
                    else if (list.isEmpty)
                      Text(
                        'No options for those filters.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      for (final o in list)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            onTap: () => _openOption(o),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(
                                switch (o.kind) {
                                  'taxi' => Icons.local_taxi_rounded,
                                  'parking' => Icons.local_parking_rounded,
                                  'bus' => Icons.directions_bus_rounded,
                                  'ev' => Icons.ev_station_rounded,
                                  _ => Icons.directions_subway_rounded,
                                },
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              o.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${o.distanceLabel(_origin.lat, _origin.lng)} · '
                              '${o.stepFree ? 'Step-free' : 'Check access'} · '
                              '${o.kindLabel}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
