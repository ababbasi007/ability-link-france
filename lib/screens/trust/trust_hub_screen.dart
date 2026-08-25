import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/ai_safety.dart';
import '../../models/place.dart';
import '../../models/service_provider.dart';
import '../../services/background_task.dart';
import '../../services/trust_service.dart';
import '../../theme/app_colors.dart';
import '../admin/admin_console_screen.dart';
import '../ai/ai_assistant_screen.dart';

class TrustHubScreen extends StatefulWidget {
  const TrustHubScreen({super.key});

  @override
  State<TrustHubScreen> createState() => _TrustHubScreenState();
}

class _TrustHubScreenState extends State<TrustHubScreen> {
  final _trust = TrustService();

  @override
  void initState() {
    super.initState();
    runInBackground(_trust.ensureSeeded(), 'seed trust policy');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _trust.watchIsModerator(),
      builder: (context, modSnap) {
        final moderator = modSnap.data == true;
        return DefaultTabController(
          length: 4,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                'Trust & safety',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Policy'),
                  Tab(text: 'Verification'),
                  Tab(text: 'Oversight'),
                  Tab(text: 'Fraud'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _PolicyTab(trust: _trust, moderator: moderator),
                _VerifyTab(trust: _trust),
                _OversightTab(trust: _trust, moderator: moderator),
                _FraudTab(trust: _trust),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PolicyTab extends StatelessWidget {
  const _PolicyTab({required this.trust, required this.moderator});

  final TrustService trust;
  final bool moderator;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: trust.watchPolicy(),
      builder: (context, snap) {
        final data = snap.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              (data?['title'] as String?) ?? 'Responsible AI',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (data?['body'] as String?) ?? 'Loading policy…',
              style: GoogleFonts.plusJakartaSans(height: 1.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Live checks: citations from mapped places, ableist-language flags, medical-diagnosis blocks, human review queue.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AiAssistantScreen(),
                  ),
                );
              },
              child: const Text('Open assistant (safety on)'),
            ),
            if (moderator) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AdminConsoleScreen(),
                    ),
                  );
                },
                child: const Text('Admin fraud scores & suspensions'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _VerifyTab extends StatelessWidget {
  const _VerifyTab({required this.trust});

  final TrustService trust;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccessiblePlace>>(
      stream: trust.watchUnverifiedPlaces(),
      builder: (context, placeSnap) {
        return StreamBuilder<List<ServiceProvider>>(
          stream: trust.watchUnverifiedProviders(),
          builder: (context, provSnap) {
            final places = placeSnap.data ?? const <AccessiblePlace>[];
            final providers = provSnap.data ?? const <ServiceProvider>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  '${places.length} unverified places · ${providers.length} unverified providers',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final p in places.take(12))
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.category),
                    trailing: TextButton(
                      onPressed: () async {
                        await trust.requestVerification(
                          targetType: 'place',
                          targetId: p.id,
                          name: p.name,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification requested'),
                          ),
                        );
                      },
                      child: const Text('Request'),
                    ),
                  ),
                for (final p in providers.take(12))
                  ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.categoryLabel),
                    trailing: TextButton(
                      onPressed: () async {
                        await trust.requestVerification(
                          targetType: 'provider',
                          targetId: p.id,
                          name: p.name,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verification requested'),
                          ),
                        );
                      },
                      child: const Text('Request'),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OversightTab extends StatelessWidget {
  const _OversightTab({required this.trust, required this.moderator});

  final TrustService trust;
  final bool moderator;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OversightCase>>(
      stream: trust.watchOversight(moderator: moderator),
      builder: (context, snap) {
        final list = snap.data ?? const <OversightCase>[];
        if (list.isEmpty) {
          return const Center(
            child: Text(
              'No queued replies. Risky or flagged answers land here.',
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final c = list[i];
            return Card(
              child: ListTile(
                title: Text(c.status.toUpperCase()),
                subtitle: Text(
                  '${c.flags.join(', ')}\n${c.reply}',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                isThreeLine: true,
                trailing: moderator && c.status == 'pending'
                    ? TextButton(
                        onPressed: () =>
                            trust.reviewCase(c.id, status: 'reviewed'),
                        child: const Text('Mark reviewed'),
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

class _FraudTab extends StatefulWidget {
  const _FraudTab({required this.trust});

  final TrustService trust;

  @override
  State<_FraudTab> createState() => _FraudTabState();
}

class _FraudTabState extends State<_FraudTab> {
  final _reason = TextEditingController();
  final _target = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    _target.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: widget.trust.watchMyFraudReports(),
      builder: (context, snap) {
        final mine = snap.data ?? const <Map<String, dynamic>>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Report a fake listing or review farm. Moderators see account fraud scores in Admin.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _target,
              decoration: const InputDecoration(
                labelText: 'Place or provider name / id',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reason,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What looks fraudulent?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                await widget.trust.reportFraud(
                  targetType: 'listing',
                  targetId: _target.text.trim(),
                  reason: _reason.text,
                );
                if (!mounted) return;
                _target.clear();
                _reason.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fraud report filed')),
                );
              },
              child: const Text('Submit report'),
            ),
            const SizedBox(height: 16),
            for (final r in mine)
              ListTile(
                title: Text((r['targetId'] as String?) ?? 'Report'),
                subtitle: Text(
                  '${r['status'] ?? 'open'} · ${r['reason'] ?? ''}',
                ),
              ),
          ],
        );
      },
    );
  }
}
