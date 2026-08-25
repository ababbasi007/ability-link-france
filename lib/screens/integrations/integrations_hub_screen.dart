import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_appointment.dart';
import '../../models/integration.dart';
import '../../services/background_task.dart';
import '../../services/healthcare_service.dart';
import '../../services/integrations_service.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../theme/app_colors.dart';
import '../ai/ai_tools_screen.dart';
import '../billing/billing_screen.dart';
import '../../services/ai_tools_service.dart';

class IntegrationsHubScreen extends StatefulWidget {
  const IntegrationsHubScreen({super.key});

  @override
  State<IntegrationsHubScreen> createState() => _IntegrationsHubScreenState();
}

class _IntegrationsHubScreenState extends State<IntegrationsHubScreen> {
  final _svc = IntegrationsService();

  @override
  void initState() {
    super.initState();
    runInBackground(_svc.ensureSeeded(), 'seed integrations');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Integrations & APIs',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Catalog'),
              Tab(text: 'Routing'),
              Tab(text: 'Calendar'),
              Tab(text: 'Open data'),
              Tab(text: 'API keys'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _CatalogTab(svc: _svc),
            const _RoutingTab(),
            _CalendarTab(svc: _svc),
            _OpenDataTab(svc: _svc),
            _ApiKeysTab(svc: _svc),
          ],
        ),
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({required this.svc});

  final IntegrationsService svc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<IntegrationItem>>(
      stream: svc.watchCatalog(),
      builder: (context, snap) {
        final items = snap.data ?? const <IntegrationItem>[];
        if (items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Connected systems',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'No third-party secrets are stored. Payments stay sandbox (no card numbers).',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Card(
                child: ListTile(
                  title: Text(item.name),
                  subtitle: Text('${item.endpoint}\n${item.notes}'),
                  isThreeLine: true,
                  trailing: Text(
                    item.status,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: item.status == 'live'
                          ? AppColors.success
                          : item.status == 'fallback'
                          ? const Color(0xFFF59E0B)
                          : AppColors.primary,
                    ),
                  ),
                  onTap: () {
                    if (item.id == 'translation') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AiToolsScreen(
                            initialTool: AiToolKind.translate,
                          ),
                        ),
                      );
                    } else if (item.id == 'payments') {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BillingScreen(),
                        ),
                      );
                    }
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RoutingTab extends StatefulWidget {
  const _RoutingTab();

  @override
  State<_RoutingTab> createState() => _RoutingTabState();
}

class _RoutingTabState extends State<_RoutingTab> {
  final _routing = RoutingService();
  WalkingRoute? _route;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final origin = await LocationService.instance.ensure();
      final route = await _routing.walking(
        fromLat: origin.lat,
        fromLng: origin.lng,
        toLat: 40.758,
        toLng: -73.9855,
      );
      if (!mounted) return;
      setState(() => _route = route);
    } catch (e) {
      // A denied location permission or an offline routing call used to leave
      // the spinner running with no way out.
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    if (_busy) {
      return const Center(child: CircularProgressIndicator());
    }
    if (route == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.map_outlined,
                size: 44,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                _error == null
                    ? 'No route available yet.'
                    : 'Could not load the route.\n$_error',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: route.points.first,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.abilitylink.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route.points,
                    color: AppColors.primary,
                    strokeWidth: 5,
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Text(
            '${route.isLive ? 'OSRM walking' : 'Straight-line fallback'} · '
            '${route.distanceLabel} · ${route.durationLabel}. '
            'Step-free Transport routes use the same engine.',
            style: GoogleFonts.plusJakartaSans(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab({required this.svc});

  final IntegrationsService svc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CareAppointment>>(
      stream: HealthcareService().watchAppointments(),
      builder: (context, snap) {
        final items = snap.data ?? const <CareAppointment>[];
        final ics = svc.appointmentsToIcs(items);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              '${items.length} visit${items.length == 1 ? '' : 's'} in your calendar export',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: ics));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'ICS copied. Paste into Calendar, Outlook, or Google.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Copy .ics'),
            ),
            const SizedBox(height: 12),
            SelectableText(ics, style: GoogleFonts.robotoMono(fontSize: 11)),
          ],
        );
      },
    );
  }
}

class _OpenDataTab extends StatelessWidget {
  const _OpenDataTab({required this.svc});

  final IntegrationsService svc;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OpenDataBundle?>(
      stream: svc.watchOpenPlaces(),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              '${data.featureCount} public place features',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'No names, emails, or Passport fields. Refresh rebuilds openData/places.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => svc.refreshOpenPlaces(),
              child: const Text('Rebuild open data'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: data.json));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('GeoJSON copied')));
              },
              child: const Text('Copy GeoJSON'),
            ),
            const SizedBox(height: 12),
            SelectableText(
              data.json.length > 4000
                  ? '${data.json.substring(0, 4000)}\n…'
                  : data.json,
              style: GoogleFonts.robotoMono(fontSize: 11),
            ),
          ],
        );
      },
    );
  }
}

class _ApiKeysTab extends StatefulWidget {
  const _ApiKeysTab({required this.svc});

  final IntegrationsService svc;

  @override
  State<_ApiKeysTab> createState() => _ApiKeysTabState();
}

class _ApiKeysTabState extends State<_ApiKeysTab> {
  final _explore = TextEditingController();
  String? _freshToken;
  String? _exploreOut;
  bool _busy = false;

  @override
  void dispose() {
    _explore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ApiKeyRecord>>(
      stream: widget.svc.watchMyKeys(),
      builder: (context, snap) {
        final keys = snap.data ?? const <ApiKeyRecord>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Future public API',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Keys are yours only. Explorer runs GET /v1/places against live Firestore. A hosted REST gateway is the next hook.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        final created = await widget.svc.createKey();
                        if (!mounted) return;
                        setState(() => _freshToken = created.token);
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: const Text('Create API key'),
            ),
            if (_freshToken != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'Copy now — shown once:\n$_freshToken',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 12),
            for (final k in keys)
              ListTile(
                title: Text('${k.prefix}…'),
                subtitle: Text(k.revoked ? 'Revoked' : 'Active'),
                trailing: k.revoked
                    ? null
                    : TextButton(
                        onPressed: () => widget.svc.revokeKey(k.id),
                        child: const Text('Revoke'),
                      ),
              ),
            TextField(
              controller: _explore,
              decoration: const InputDecoration(
                labelText: 'Paste key to call GET /v1/places',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () async {
                final out = await widget.svc.explorePlaces(_explore.text);
                if (!mounted) return;
                setState(() => _exploreOut = out);
              },
              child: const Text('Run explorer'),
            ),
            if (_exploreOut != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                _exploreOut!,
                style: GoogleFonts.robotoMono(fontSize: 11),
              ),
            ],
          ],
        );
      },
    );
  }
}
