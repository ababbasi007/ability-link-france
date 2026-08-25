import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_appointment.dart';
import '../../models/accessibility_review.dart';
import '../../models/service_provider.dart';
import '../../services/background_task.dart';
import '../../services/providers_service.dart';
import '../../services/reviews_service.dart';
import '../../theme/app_colors.dart';
import '../billing/billing_screen.dart';
import '../healthcare/session_room_screen.dart';
import 'provider_profile_screen.dart';

class ProviderPortalScreen extends StatefulWidget {
  const ProviderPortalScreen({super.key});

  @override
  State<ProviderPortalScreen> createState() => _ProviderPortalScreenState();
}

class _ProviderPortalScreenState extends State<ProviderPortalScreen> {
  final _service = ProvidersService();
  final _reviews = ReviewsService();

  @override
  void initState() {
    super.initState();
    runInBackground(_service.ensureSeeded(), 'seed service');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ServiceProvider?>(
      stream: _service.watchMyOrg(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final org = snap.data;
        if (org == null) {
          return _OrgSignup(
            onCreate: (name, category, specialty, city, bio) {
              return _service.createOrg(
                name: name,
                category: category,
                specialty: specialty,
                city: city,
                bio: bio,
              );
            },
          );
        }
        return DefaultTabController(
          length: 7,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                'Provider portal',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Checklist'),
                  Tab(text: 'Evidence'),
                  Tab(text: 'Reviews'),
                  Tab(text: 'Leads'),
                  Tab(text: 'Bookings'),
                  Tab(text: 'Billing'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _OverviewTab(org: org, service: _service),
                _ChecklistTab(org: org, service: _service),
                _EvidenceTab(org: org, service: _service),
                _ReviewsTab(org: org, reviews: _reviews),
                _LeadsTab(org: org, service: _service),
                _BookingsTab(org: org, service: _service),
                const BillingScreen(embedded: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrgSignup extends StatefulWidget {
  const _OrgSignup({required this.onCreate});

  final Future<String> Function(
    String name,
    String category,
    String specialty,
    String city,
    String bio,
  )
  onCreate;

  @override
  State<_OrgSignup> createState() => _OrgSignupState();
}

class _OrgSignupState extends State<_OrgSignup> {
  final _name = TextEditingController();
  final _specialty = TextEditingController();
  final _city = TextEditingController();
  final _bio = TextEditingController();
  String _category = 'healthcare';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _specialty.dispose();
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation name is required')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onCreate(
        _name.text,
        _category,
        _specialty.text,
        _city.text,
        _bio.text,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Provider portal',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Register your organisation',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Publish an accessibility listing, collect leads, and manage bookings.',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Organisation / practice name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _category,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'healthcare', child: Text('Healthcare')),
              DropdownMenuItem(value: 'rehab', child: Text('Rehabilitation')),
              DropdownMenuItem(value: 'education', child: Text('Education')),
              DropdownMenuItem(value: 'assistance', child: Text('Assistance')),
              DropdownMenuItem(value: 'caregiving', child: Text('Caregiving')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _category = v);
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _specialty,
            decoration: const InputDecoration(
              labelText: 'Specialty',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _city,
            decoration: const InputDecoration(
              labelText: 'City',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bio,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'About / accessibility offer',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_busy ? 'Saving…' : 'Create listing'),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.org, required this.service});

  final ServiceProvider org;
  final ProvidersService service;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          org.name,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          '${org.categoryLabel} · ${org.city}',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Available for new bookings'),
          value: org.availableNow,
          onChanged: (v) => service.setAvailable(org.id, v),
        ),
        StreamBuilder<List<EnquiryLead>>(
          stream: service.watchLeads(org.id),
          builder: (context, leadSnap) {
            return StreamBuilder<List<CareAppointment>>(
              stream: service.watchProviderAppointments(org.id),
              builder: (context, bookSnap) {
                final leads = leadSnap.data ?? const <EnquiryLead>[];
                final books = bookSnap.data ?? const <CareAppointment>[];
                final pending = leads
                    .where((l) => l.status == 'pending')
                    .length;
                final upcoming = books.where((b) => b.isUpcoming).length;
                return Row(
                  children: [
                    _Stat(label: 'Leads', value: '${leads.length}'),
                    _Stat(label: 'Pending', value: '$pending'),
                    _Stat(label: 'Bookings', value: '$upcoming'),
                    _Stat(
                      label: 'Checklist',
                      value: '${org.checklistPercent}%',
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Evidence files: ${org.evidence.length}',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    ProviderProfileScreen(providerId: org.id, provider: org),
              ),
            );
          },
          icon: const Icon(Icons.public),
          label: const Text('View public listing'),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

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

class _ChecklistTab extends StatelessWidget {
  const _ChecklistTab({required this.org, required this.service});

  final ServiceProvider org;
  final ProvidersService service;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
          child: Text(
            'Mark what you offer. This shows on your public listing tags over time.',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
        ),
        for (final e in kAccessibilityChecklist.entries)
          SwitchListTile(
            title: Text(e.value),
            value: org.checklist[e.key] == true,
            onChanged: (v) {
              final next = Map<String, bool>.from(org.checklist);
              for (final k in kAccessibilityChecklist.keys) {
                next[k] = next[k] == true;
              }
              next[e.key] = v;
              service.saveChecklist(org.id, next);
            },
          ),
      ],
    );
  }
}

class _EvidenceTab extends StatelessWidget {
  const _EvidenceTab({required this.org, required this.service});

  final ServiceProvider org;
  final ProvidersService service;

  Future<void> _add(BuildContext context) async {
    final title = TextEditingController();
    final url = TextEditingController(text: 'https://');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Add evidence'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              TextField(
                controller: url,
                decoration: const InputDecoration(
                  labelText: 'Link (photo, PDF, page)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (ok == true &&
          title.text.trim().isNotEmpty &&
          url.text.trim().length > 8) {
        await service.addEvidence(org.id, title: title.text, url: url.text);
      }
    } finally {
      title.dispose();
      url.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        FilledButton.icon(
          onPressed: () => _add(context),
          icon: const Icon(Icons.upload_file_outlined),
          label: const Text('Add evidence link'),
        ),
        const SizedBox(height: 12),
        if (org.evidence.isEmpty)
          Text(
            'Add photos or documents that prove ramps, toilets, captions, or training.',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          )
        else
          for (final e in org.evidence)
            Card(
              child: ListTile(
                title: Text(e.title),
                subtitle: Text(
                  e.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.copy),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: e.url));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Link copied')));
                },
              ),
            ),
      ],
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.org, required this.reviews});

  final ServiceProvider org;
  final ReviewsService reviews;

  Future<void> _openReplySheet(
    BuildContext context,
    AccessibilityReview review,
  ) async {
    final ctrl = TextEditingController();
    bool submitting = false;
    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Reply to review',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.authorName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Your reply',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting
                            ? null
                            : () async {
                                final text = ctrl.text.trim();
                                if (text.isEmpty) return;
                                setLocal(() => submitting = true);
                                try {
                                  await reviews.reply(
                                    reviewId: review.id,
                                    reply: text,
                                  );
                                  if (!context.mounted) return;
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('Reply sent'),
                                    ),
                                  );
                                } catch (e) {
                                  setLocal(() => submitting = false);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(content: Text('$e')),
                                  );
                                }
                              },
                        child: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send reply'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } finally {
      ctrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AccessibilityReview>>(
      stream: reviews.watchFor(
        targetType: 'provider',
        targetId: org.id,
      ),
      builder: (context, snap) {
        final all = snap.data ?? const <AccessibilityReview>[];
        final visible = all.where((r) => r.isVisible).toList();

        if (snap.connectionState == ConnectionState.waiting && visible.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (visible.isEmpty) {
          return Center(
            child: Text(
              'No published reviews yet. Community reviews will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = visible[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            r.authorName.isEmpty
                                ? '?'
                                : r.authorName[0].toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            r.authorName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '★ ${r.overall}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        r.comment,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.4,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                    if (r.hasEvidence) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final e in r.evidence)
                            Chip(
                              label: Text(e),
                              backgroundColor: AppColors.primaryLight,
                            ),
                        ],
                      ),
                    ],
                    if (r.ownerReply.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Your reply',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.border.withValues(alpha: 0.7),
                          ),
                        ),
                        child: Text(
                          r.ownerReply,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            height: 1.4,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _openReplySheet(context, r),
                          icon: const Icon(Icons.reply_rounded),
                          label: const Text('Reply'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          try {
                            await reviews.helpful(r.id);
                            if (!context.mounted) return;
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.thumb_up_alt_outlined),
                        label: Text('Helpful ${r.helpfulCount}'),
                      ),
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

class _LeadsTab extends StatelessWidget {
  const _LeadsTab({required this.org, required this.service});

  final ServiceProvider org;
  final ProvidersService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<EnquiryLead>>(
      stream: service.watchLeads(org.id),
      builder: (context, snap) {
        final leads = snap.data ?? const <EnquiryLead>[];
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (leads.isEmpty) {
          return Center(
            child: Text(
              'No enquiries yet. They appear when someone uses Book / Enquire on your listing.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: leads.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final l = leads[i];
            return Card(
              child: ListTile(
                title: Text(l.userName),
                subtitle: Text(
                  '${l.service} · ${l.preferredSlot}\n${l.message}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (s) => service.setLeadStatus(l.id, s),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'pending', child: Text('Pending')),
                    PopupMenuItem(value: 'contacted', child: Text('Contacted')),
                    PopupMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  child: Chip(label: Text(l.status)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _BookingsTab extends StatelessWidget {
  const _BookingsTab({required this.org, required this.service});

  final ServiceProvider org;
  final ProvidersService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CareAppointment>>(
      stream: service.watchProviderAppointments(org.id),
      builder: (context, snap) {
        final books = snap.data ?? const <CareAppointment>[];
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (books.isEmpty) {
          return Center(
            child: Text(
              'No bookings yet. Confirmed sessions from Healthcare show here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: books.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final b = books[i];
            return Card(
              child: ListTile(
                title: Text(b.whenLabel),
                subtitle: Text('${b.modeLabel} · ${b.specialty}\n${b.notes}'),
                isThreeLine: true,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (b.isRemote && b.status == 'booked')
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SessionRoomScreen(appointment: b),
                            ),
                          );
                        },
                        child: const Text('Join'),
                      ),
                    PopupMenuButton<String>(
                      onSelected: (s) => service.setAppointmentStatus(b.id, s),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'booked', child: Text('Booked')),
                        PopupMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        PopupMenuItem(
                          value: 'cancelled',
                          child: Text('Cancelled'),
                        ),
                      ],
                      child: Chip(label: Text(b.status)),
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
