import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/care_appointment.dart';
import '../../models/impact_report.dart';
import '../../models/inclusive_job.dart';
import '../../models/user_activity.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/healthcare_service.dart';
import '../../services/impact_service.dart';
import '../../services/jobs_service.dart';
import '../../services/places_service.dart';
import '../../services/user_activity_service.dart';
import '../../theme/app_colors.dart';

class ImpactHubScreen extends StatefulWidget {
  const ImpactHubScreen({super.key});

  @override
  State<ImpactHubScreen> createState() => _ImpactHubScreenState();
}

class _ImpactHubScreenState extends State<ImpactHubScreen> {
  final _impact = ImpactService();
  final _auth = AuthService();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      await _impact.refreshSnapshot();
    } catch (e) {
      // Tapping refresh and seeing stale numbers with no explanation reads as
      // a frozen screen.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not refresh the snapshot: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Impact & analytics',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh snapshot',
              onPressed: _busy ? null : _refresh,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'KPIs'),
              Tab(text: 'Coverage'),
              Tab(text: 'Gaps'),
              Tab(text: 'My activity'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: StreamBuilder<ImpactSnapshot?>(
          stream: _impact.watchLatest(),
          builder: (context, snap) {
            final data = snap.data;
            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            return StreamBuilder<UserProfile?>(
              stream: _auth.watchCurrentProfile(),
              builder: (context, profileSnap) {
                final profile = profileSnap.data;
                final passport = _impact.passportNeeds(profile);
                return TabBarView(
                  children: [
                    _KpiTab(snapshot: data),
                    _CoverageTab(snapshot: data),
                    _GapsTab(snapshot: data, passportNeeds: passport),
                    const _ActivityTab(),
                    _ReportsTab(impact: _impact, snapshot: data),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _KpiTab extends StatelessWidget {
  const _KpiTab({required this.snapshot});

  final ImpactSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Social-impact index ${snapshot.socialReach}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Reviews + jobs with accommodations + community posts. Snapshot is public map data, not private profiles.',
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
            _stat(
              'Places',
              '${snapshot.placesVerified}/${snapshot.places} verified',
            ),
            _stat('Avg score', '${snapshot.avgPlaceScore.round()}'),
            _stat(
              'Providers',
              '${snapshot.providersVerified}/${snapshot.providers} verified',
            ),
            _stat('Reviews', '${snapshot.reviews}'),
            _stat(
              'Inclusive jobs',
              '${snapshot.jobsWithAccommodations}/${snapshot.jobs} with accommodations',
            ),
            _stat(
              'Barriers',
              '${snapshot.barriersOpen} open · ${snapshot.barriersResolved} resolved',
            ),
            _stat('Community', '${snapshot.communityPosts} posts'),
            _stat('Education', '${snapshot.educationPrograms} programs'),
            _stat('Travel', '${snapshot.destinations} destinations'),
            if (snapshot.topSearchedCategories.isNotEmpty)
              _stat(
                'Top search',
                snapshot.topSearchedCategories.entries.first.key,
              ),
            if (snapshot.scoreImprovements > 0)
              _stat(
                'Score lifts',
                '${snapshot.scoreImprovements} · avg +${snapshot.avgScoreDelta.toStringAsFixed(1)}',
              ),
          ],
        ),
        if (snapshot.topSearchedCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Most searched categories',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final e in snapshot.topSearchedCategories.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.key,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'Need coverage',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final e in snapshot.needCoverage.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.key} · ${(e.value * 100).round()}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: e.value.clamp(0, 1),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary,
                  backgroundColor: AppColors.primaryLight,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverageTab extends StatelessWidget {
  const _CoverageTab({required this.snapshot});

  final ImpactSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final cells = snapshot.cells;
    final center = cells.isNotEmpty
        ? cells.first.point
        : const LatLng(
            PlacesService.defaultOriginLat,
            PlacesService.defaultOriginLng,
          );
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: FlutterMap(
            options: MapOptions(initialCenter: center, initialZoom: 12),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.abilitylink.app',
              ),
              CircleLayer(
                circles: [
                  for (final c in cells)
                    CircleMarker(
                      point: c.point,
                      radius: (18 + (c.placeCount * 6))
                          .clamp(18, 58)
                          .toDouble(),
                      color: AppColors.primary.withValues(alpha: 0.28),
                      borderStrokeWidth: 2,
                      borderColor: AppColors.primary,
                    ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: cells.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final c = cells[i];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text('Cluster ${c.key}'),
                subtitle: Text('${c.label} · ${c.verified} verified'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GapsTab extends StatelessWidget {
  const _GapsTab({required this.snapshot, required this.passportNeeds});

  final ImpactSnapshot snapshot;
  final List<String> passportNeeds;

  @override
  Widget build(BuildContext context) {
    final mine = snapshot.gaps
        .where((g) => g.need.isNotEmpty && passportNeeds.contains(g.need))
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (passportNeeds.isNotEmpty)
          Card(
            color: AppColors.primaryLight,
            child: ListTile(
              title: const Text('Matched to your Passport'),
              subtitle: Text(
                mine.isEmpty
                    ? 'Coverage looks reasonable for: ${passportNeeds.join(', ')}'
                    : '${mine.length} gap${mine.length == 1 ? '' : 's'} touch your needs: ${passportNeeds.join(', ')}',
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (snapshot.gaps.isEmpty)
          const Text('No major gaps in the current map snapshot.')
        else
          for (final g in snapshot.gaps)
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.warning_amber_rounded,
                  color: g.severity == 'high'
                      ? AppColors.sos
                      : const Color(0xFFF59E0B),
                ),
                title: Text(g.title),
                subtitle: Text(g.detail),
                trailing: Text(
                  g.severity,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    final places = PlacesService();
    final care = HealthcareService();
    final jobs = JobsService();
    final activity = UserActivityService();
    return StreamBuilder<UserActivityStats>(
      stream: activity.watchStats(),
      builder: (context, statsSnap) {
        final stats = statsSnap.data ?? const UserActivityStats();
        return StreamBuilder<List<ActivityEvent>>(
          stream: activity.watchRecentActivity(),
          builder: (context, logSnap) {
            final log = logSnap.data ?? const <ActivityEvent>[];
            return StreamBuilder<Set<String>>(
              stream: places.watchFavoriteIds(),
              builder: (context, favSnap) {
                return StreamBuilder<List<CareAppointment>>(
                  stream: care.watchAppointments(),
                  builder: (context, apptSnap) {
                    return StreamBuilder<List<JobApplication>>(
                      stream: jobs.watchMyApplications(),
                      builder: (context, appSnap) {
                        final favs = favSnap.data?.length ?? 0;
                        final appts = apptSnap.data?.length ?? 0;
                        final apps = appSnap.data?.length ?? 0;
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            Text(
                              'Your activity',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Only you can see this. Platform KPIs never include your Passport.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              leading: const Icon(Icons.place_outlined),
                              title: Text('${stats.visitCount} places visited'),
                              subtitle: stats.recentVisits.isEmpty
                                  ? null
                                  : Text(
                                      'Latest: ${stats.recentVisits.first.title.replaceFirst('Visited ', '')}',
                                    ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.route_outlined),
                              title: Text(
                                '${stats.distanceLabel} traveled · ${stats.tripCount} trips',
                              ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.search_rounded),
                              title: Text('${stats.searchCount} map searches'),
                              subtitle: stats.topCategories.isEmpty
                                  ? null
                                  : Text(
                                      'Top: ${stats.topCategories.entries.take(3).map((e) => '${e.key} (${e.value})').join(' · ')}',
                                    ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.trending_up_rounded),
                              title: Text(
                                '${stats.scoreImprovements} accessibility score lifts',
                              ),
                              subtitle: stats.scoreImprovements == 0
                                  ? const Text('Submit audits to improve place scores')
                                  : Text(
                                      'Avg +${stats.avgScoreDelta.toStringAsFixed(1)} points',
                                    ),
                            ),
                            ListTile(
                              leading: const Icon(Icons.favorite_outline),
                              title: Text('$favs saved places'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.event_available_outlined),
                              title: Text('$appts healthcare visits on file'),
                            ),
                            ListTile(
                              leading: const Icon(Icons.work_outline),
                              title: Text('$apps job applications'),
                            ),
                            if (log.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Activity history',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final e in log.take(25))
                                ListTile(
                                  dense: true,
                                  leading: Icon(_iconFor(e.kind), size: 20),
                                  title: Text(e.title),
                                  subtitle: Text(
                                    e.detail.isEmpty
                                        ? e.createdAt.toLocal().toString()
                                        : '${e.detail} · ${e.createdAt.toLocal()}',
                                  ),
                                ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _iconFor(String kind) => switch (kind) {
        'visit' => Icons.place_outlined,
        'search' => Icons.search_rounded,
        'trip' => Icons.route_outlined,
        'score' => Icons.trending_up_rounded,
        _ => Icons.history_rounded,
      };
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.impact, required this.snapshot});

  final ImpactService impact;
  final ImpactSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SavedImpactReport>>(
      stream: impact.watchMyReports(),
      builder: (context, snap) {
        final reports = snap.data ?? const <SavedImpactReport>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            FilledButton.icon(
              onPressed: () async {
                await impact.saveReport(snapshot);
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Report saved')));
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save snapshot as report'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(
                  ClipboardData(text: snapshot.summaryText),
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied report text')),
                );
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy KPI summary'),
            ),
            const SizedBox(height: 16),
            if (reports.isEmpty)
              Text(
                'Saved reports land here. Toggle share if a partner needs a public copy.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final r in reports)
                Card(
                  child: ListTile(
                    title: Text(r.title),
                    subtitle: Text(
                      '${r.shared ? 'Shared' : 'Private'}\n${r.body}',
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'share') {
                          impact.setShared(r.id, !r.shared);
                        } else if (v == 'delete') {
                          impact.deleteReport(r.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'share',
                          child: Text(r.shared ? 'Make private' : 'Share'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
