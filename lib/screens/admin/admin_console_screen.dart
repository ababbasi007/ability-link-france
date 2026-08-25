import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/accessibility_review.dart';
import '../../models/community.dart';
import '../../models/place.dart';
import '../../models/platform_admin.dart';
import '../../models/service_provider.dart';
import '../../services/admin_service.dart';
import '../../theme/app_colors.dart';

class AdminConsoleScreen extends StatefulWidget {
  const AdminConsoleScreen({super.key});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> {
  final _admin = AdminService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PlatformConfig?>(
      stream: _admin.watchConfig(),
      builder: (context, snap) {
        final config = snap.data;
        final uid = _admin.uid;
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (config == null || !config.isModerator(uid)) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Admin console',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'This console is for platform operators. Only listed admins and moderators can enter — roles are seeded from the Firebase console.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        final isAdmin = config.isAdmin(uid);
        return DefaultTabController(
          length: isAdmin ? 6 : 5,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                'Admin console',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  const Tab(text: 'Overview'),
                  const Tab(text: 'Users'),
                  const Tab(text: 'Providers'),
                  const Tab(text: 'Map'),
                  const Tab(text: 'Moderation'),
                  if (isAdmin) const Tab(text: 'RBAC / config'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(config: config, admin: _admin),
                _UsersTab(admin: _admin, isAdmin: isAdmin),
                _ProvidersTab(admin: _admin),
                _MapTab(admin: _admin, config: config),
                _ModerationTab(admin: _admin),
                if (isAdmin) _ConfigTab(admin: _admin, config: config),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.config, required this.admin});

  final PlatformConfig config;
  final AdminService admin;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Platform ops',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${config.adminUids.length} admins · ${config.moderatorUids.length} moderators',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
        ),
        if (config.maintenanceMessage.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: const Color(0xFFFFF1E8),
            child: ListTile(
              title: const Text('Maintenance banner'),
              subtitle: Text(config.maintenanceMessage),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Map taxonomy: ${config.placeCategories.join(', ')}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        const SizedBox(height: 8),
        Text(
          'Provider taxonomy: ${config.providerCategories.join(', ')}',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<AdminUserRecord>>(
          stream: admin.watchUsers(),
          builder: (context, snap) {
            final users = snap.data ?? const <AdminUserRecord>[];
            final suspended = users
                .where((u) => u.accountStatus == 'suspended')
                .length;
            final fraud = users.where((u) => u.fraudScore >= 3).length;
            return Row(
              children: [
                _Kpi(label: 'Users', value: '${users.length}'),
                _Kpi(label: 'Suspended', value: '$suspended'),
                _Kpi(label: 'Fraud flags', value: '$fraud'),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.admin, required this.isAdmin});

  final AdminService admin;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminUserRecord>>(
      stream: admin.watchUsers(),
      builder: (context, snap) {
        final list = snap.data ?? const <AdminUserRecord>[];
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final u = list[i];
            return Card(
              child: ListTile(
                title: Text(u.name),
                subtitle: Text(
                  '${u.email}\n${u.role} · ${u.accountStatus} · fraud ${u.fraudScore}'
                  '${u.platformRole.isEmpty ? '' : ' · ${u.platformRole}'}',
                ),
                isThreeLine: true,
                trailing: isAdmin
                    ? PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'suspend') {
                            await admin.setUserStatus(
                              uid: u.uid,
                              accountStatus: 'suspended',
                              fraudScore: u.fraudScore + 1,
                              fraudNotes: 'Suspended from admin console',
                            );
                          } else if (v == 'activate') {
                            await admin.setUserStatus(
                              uid: u.uid,
                              accountStatus: 'active',
                            );
                          } else if (v == 'fraud') {
                            await admin.setUserStatus(
                              uid: u.uid,
                              accountStatus: u.accountStatus,
                              fraudScore: u.fraudScore + 1,
                              fraudNotes: 'Manual fraud flag',
                            );
                          } else if (v == 'mod') {
                            await admin.setModerator(u.uid, enabled: true);
                          } else if (v == 'unmod') {
                            await admin.setModerator(u.uid, enabled: false);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'fraud',
                            child: Text('Flag fraud'),
                          ),
                          const PopupMenuItem(
                            value: 'suspend',
                            child: Text('Suspend'),
                          ),
                          const PopupMenuItem(
                            value: 'activate',
                            child: Text('Activate'),
                          ),
                          const PopupMenuItem(
                            value: 'mod',
                            child: Text('Make moderator'),
                          ),
                          const PopupMenuItem(
                            value: 'unmod',
                            child: Text('Remove moderator'),
                          ),
                        ],
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _ProvidersTab extends StatelessWidget {
  const _ProvidersTab({required this.admin});

  final AdminService admin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ServiceProvider>>(
      stream: admin.watchAllProviders(),
      builder: (context, snap) {
        final list = snap.data ?? const <ServiceProvider>[];
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = list[i];
            return Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(
                  '${p.categoryLabel} · ${p.hidden ? 'hidden' : 'visible'}'
                  '${p.verified ? ' · verified' : ''}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'verify') {
                      admin.setProviderFlags(id: p.id, verified: !p.verified);
                    } else if (v == 'hide') {
                      admin.setProviderFlags(id: p.id, hidden: !p.hidden);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'verify',
                      child: Text(p.verified ? 'Unverify' : 'Verify'),
                    ),
                    PopupMenuItem(
                      value: 'hide',
                      child: Text(p.hidden ? 'Show listing' : 'Hide listing'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MapTab extends StatelessWidget {
  const _MapTab({required this.admin, required this.config});

  final AdminService admin;
  final PlatformConfig config;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccessiblePlace>>(
      stream: admin.watchAllPlaces(),
      builder: (context, snap) {
        final list = snap.data ?? const <AccessiblePlace>[];
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = list[i];
            return Card(
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(
                  '${p.category} · ${p.hidden ? 'hidden' : 'on map'}'
                  '${p.verified ? ' · verified' : ''}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'hide') {
                      admin.setPlaceFlags(id: p.id, hidden: !p.hidden);
                    } else if (v == 'verify') {
                      admin.setPlaceFlags(id: p.id, verified: !p.verified);
                    } else {
                      admin.setPlaceFlags(id: p.id, category: v);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'hide',
                      child: Text(p.hidden ? 'Show on map' : 'Hide from map'),
                    ),
                    PopupMenuItem(
                      value: 'verify',
                      child: Text(p.verified ? 'Unverify' : 'Verify'),
                    ),
                    for (final c in config.placeCategories)
                      PopupMenuItem(value: c, child: Text('Category: $c')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ModerationTab extends StatelessWidget {
  const _ModerationTab({required this.admin});

  final AdminService admin;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccessibilityReview>>(
      stream: admin.watchReviews(),
      builder: (context, reviewSnap) {
        return StreamBuilder<List<CommunityPost>>(
          stream: admin.watchPosts(),
          builder: (context, postSnap) {
            final items = <ModerationItem>[];
            for (final r in reviewSnap.data ?? const <AccessibilityReview>[]) {
              if (r.flagCount > 0 || r.status == 'hidden') {
                items.add(
                  ModerationItem(
                    id: r.id,
                    kind: 'review',
                    title: r.targetName,
                    subtitle: r.comment,
                    status: r.status,
                    flagCount: r.flagCount,
                  ),
                );
              }
            }
            for (final p in postSnap.data ?? const <CommunityPost>[]) {
              if (p.flagCount > 0 || p.status == 'hidden') {
                items.add(
                  ModerationItem(
                    id: p.id,
                    kind: 'post',
                    title: p.title,
                    subtitle: p.body,
                    status: p.status,
                    flagCount: p.flagCount,
                  ),
                );
              }
            }
            items.sort((a, b) => b.flagCount.compareTo(a.flagCount));
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'No flagged reviews or posts. Community and place reports land here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final m = items[i];
                return Card(
                  child: ListTile(
                    title: Text('${m.kind} · ${m.title}'),
                    subtitle: Text(
                      '${m.flagCount} flags · ${m.status}\n${m.subtitle}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (s) => admin.setContentStatus(
                        kind: m.kind,
                        id: m.id,
                        status: s,
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'published',
                          child: Text('Publish'),
                        ),
                        PopupMenuItem(value: 'hidden', child: Text('Hide')),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ConfigTab extends StatefulWidget {
  const _ConfigTab({required this.admin, required this.config});

  final AdminService admin;
  final PlatformConfig config;

  @override
  State<_ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<_ConfigTab> {
  late final TextEditingController _places;
  late final TextEditingController _providers;
  late final TextEditingController _maintenance;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _places = TextEditingController(
      text: widget.config.placeCategories.join(', '),
    );
    _providers = TextEditingController(
      text: widget.config.providerCategories.join(', '),
    );
    _maintenance = TextEditingController(
      text: widget.config.maintenanceMessage,
    );
  }

  @override
  void dispose() {
    _places.dispose();
    _providers.dispose();
    _maintenance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.admin.saveTaxonomy(
        placeCategories: _places.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        providerCategories: _providers.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        maintenanceMessage: _maintenance.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Config saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Admins: ${widget.config.adminUids.length}. Promote moderators from Users.',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _places,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Place categories (comma-separated)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _providers,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Provider categories (comma-separated)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _maintenance,
          decoration: const InputDecoration(
            labelText: 'Maintenance message (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(_busy ? 'Saving…' : 'Save config'),
        ),
      ],
    );
  }
}
