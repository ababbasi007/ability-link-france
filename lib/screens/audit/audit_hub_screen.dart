import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/accessibility_audit.dart';
import '../../models/place.dart';
import '../../services/audit_service.dart';
import '../../services/background_task.dart';
import '../../services/places_service.dart';
import '../../theme/app_colors.dart';
import 'audit_wizard_screen.dart';

class AuditHubScreen extends StatefulWidget {
  const AuditHubScreen({super.key, this.place});

  final AccessiblePlace? place;

  @override
  State<AuditHubScreen> createState() => _AuditHubScreenState();
}

class _AuditHubScreenState extends State<AuditHubScreen> {
  final _audits = AuditService();
  final _places = PlacesService();

  @override
  void initState() {
    super.initState();
    runInBackground(_audits.ensureSeeded(), 'seed audits');
    runInBackground(_places.ensureSeeded(), 'seed places');
    if (widget.place != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openWizard(place: widget.place);
      });
    }
  }

  Future<void> _openWizard({
    AccessiblePlace? place,
    AccessibilityAudit? existing,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuditWizardScreen(place: place, existing: existing),
      ),
    );
  }

  Future<void> _pickPlaceAndStart() async {
    final places = await _places.watchPlaces().first;
    if (!mounted) return;
    final result = await showModalBottomSheet<Object>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Audit which place?',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('New / unlisted place'),
            onTap: () => Navigator.pop(ctx, 'new'),
          ),
          for (final p in places)
            ListTile(
              title: Text(p.name),
              subtitle: Text(p.address),
              onTap: () => Navigator.pop(ctx, p),
            ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    await _openWizard(place: result is AccessiblePlace ? result : null);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Accessibility Audit',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'My drafts'),
              Tab(text: 'My submitted'),
              Tab(text: 'Community'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _pickPlaceAndStart,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('New audit'),
        ),
        body: TabBarView(
          children: [
            _MineList(
              stream: _audits.watchMine(),
              draftsOnly: true,
              onOpen: (a) => _openWizard(existing: a),
            ),
            _MineList(
              stream: _audits.watchMine(),
              draftsOnly: false,
              onOpen: (a) => _openWizard(existing: a),
            ),
            StreamBuilder<List<AccessibilityAudit>>(
              stream: _audits.watchSubmitted(),
              builder: (context, snap) {
                final list = snap.data ?? const <AccessibilityAudit>[];
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (list.isEmpty) {
                  return const Center(child: Text('No submitted audits yet.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final a = list[i];
                    return _AuditTile(
                      audit: a,
                      onTap: () => _openWizard(existing: a),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MineList extends StatelessWidget {
  const _MineList({
    required this.stream,
    required this.draftsOnly,
    required this.onOpen,
  });

  final Stream<List<AccessibilityAudit>> stream;
  final bool draftsOnly;
  final ValueChanged<AccessibilityAudit> onOpen;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccessibilityAudit>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = (snap.data ?? const <AccessibilityAudit>[])
            .where((a) => draftsOnly ? a.isDraft : !a.isDraft)
            .toList();
        if (list.isEmpty) {
          return Center(
            child: Text(
              draftsOnly
                  ? 'No drafts. Start a new audit.'
                  : 'You have not submitted an audit yet.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) =>
              _AuditTile(audit: list[i], onTap: () => onOpen(list[i])),
        );
      },
    );
  }
}

class _AuditTile extends StatelessWidget {
  const _AuditTile({required this.audit, required this.onTap});

  final AccessibilityAudit audit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          audit.placeName.isEmpty ? 'Untitled place' : audit.placeName,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${audit.isDraft ? 'Draft' : 'Submitted'} · score ${audit.score} · ${audit.answeredCount()}/${audit.totalItems} items · ${audit.photos.length} photos',
        ),
        trailing: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Text(
            '${audit.score}',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
