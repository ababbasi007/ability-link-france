import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/inclusive_job.dart';
import '../../services/background_task.dart';
import '../../services/jobs_service.dart';
import '../../theme/app_colors.dart';
import '../billing/billing_screen.dart';
import 'employer_profile_screen.dart';

class EmployerPortalScreen extends StatefulWidget {
  const EmployerPortalScreen({super.key});

  @override
  State<EmployerPortalScreen> createState() => _EmployerPortalScreenState();
}

class _EmployerPortalScreenState extends State<EmployerPortalScreen> {
  final _jobs = JobsService();

  @override
  void initState() {
    super.initState();
    runInBackground(_jobs.ensureSeeded(), 'seed jobs');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EmployerProfile?>(
      stream: _jobs.watchMyEmployer(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final org = snap.data;
        if (org == null) return _EmployerSignup(jobs: _jobs);
        return DefaultTabController(
          length: 6,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                'Employer platform',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'KPIs'),
                  Tab(text: 'Profile'),
                  Tab(text: 'Jobs'),
                  Tab(text: 'Candidates'),
                  Tab(text: 'Accommodations'),
                  Tab(text: 'Billing'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _KpiTab(org: org, jobs: _jobs),
                _ProfileTab(org: org, jobs: _jobs),
                _JobsTab(org: org, jobs: _jobs),
                _CandidatesTab(org: org, jobs: _jobs),
                _AccommodationsTab(org: org, jobs: _jobs),
                const BillingScreen(embedded: true),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmployerSignup extends StatefulWidget {
  const _EmployerSignup({required this.jobs});

  final JobsService jobs;

  @override
  State<_EmployerSignup> createState() => _EmployerSignupState();
}

class _EmployerSignupState extends State<_EmployerSignup> {
  final _name = TextEditingController();
  final _industry = TextEditingController(text: 'Technology');
  final _city = TextEditingController();
  final _about = TextEditingController();
  final _pledges = <String>{'Flexible hours', 'Captioned meetings'};
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _industry.dispose();
    _city.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Company name is required')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.jobs.createEmployer(
        name: _name.text,
        industry: _industry.text,
        city: _city.text,
        about: _about.text,
        pledges: _pledges.toList(),
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
          'Employer platform',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Register your company',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Post inclusive roles, rank candidates by Passport match, and track accommodations.',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Company name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _industry,
            decoration: const InputDecoration(
              labelText: 'Industry',
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
            controller: _about,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Inclusion statement',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pledges',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          ),
          Wrap(
            spacing: 8,
            children: [
              for (final p in kInclusionPledges)
                FilterChip(
                  label: Text(p),
                  selected: _pledges.contains(p),
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        _pledges.add(p);
                      } else {
                        _pledges.remove(p);
                      }
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_busy ? 'Saving…' : 'Create employer profile'),
          ),
        ],
      ),
    );
  }
}

class _KpiTab extends StatelessWidget {
  const _KpiTab({required this.org, required this.jobs});

  final EmployerProfile org;
  final JobsService jobs;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InclusiveJob>>(
      stream: jobs.watchJobsForEmployer(org.id),
      builder: (context, jobSnap) {
        return StreamBuilder<List<JobApplication>>(
          stream: jobs.watchEmployerApplications(org.id),
          builder: (context, appSnap) {
            final roles = jobSnap.data ?? const <InclusiveJob>[];
            final apps = appSnap.data ?? const <JobApplication>[];
            final active = apps.where((a) => a.status != 'withdrawn').toList();
            final withAcc = active
                .where((a) => a.requestedAccommodations.isNotEmpty)
                .toList();
            final fulfilled = withAcc
                .where((a) => a.accommodationStatus == 'fulfilled')
                .length;
            final avg = active.isEmpty
                ? 0
                : (active.fold<int>(0, (s, a) => s + a.matchScore) /
                          active.length)
                      .round();
            final accPct = withAcc.isEmpty
                ? 0
                : ((fulfilled / withAcc.length) * 100).round();
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
                  '${org.industry} · ${org.city}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Kpi(label: 'Open jobs', value: '${roles.length}'),
                    _Kpi(label: 'Candidates', value: '${active.length}'),
                    _Kpi(label: 'Avg match', value: '$avg%'),
                    _Kpi(label: 'Accom. done', value: '$accPct%'),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${org.inclusivePledges.length} inclusion pledges published',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EmployerProfileScreen(employerId: org.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.public),
                  label: const Text('View public employer page'),
                ),
              ],
            );
          },
        );
      },
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
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
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

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({required this.org, required this.jobs});

  final EmployerProfile org;
  final JobsService jobs;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late final TextEditingController _about;
  late final TextEditingController _city;
  late final TextEditingController _industry;
  late Set<String> _pledges;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _about = TextEditingController(text: widget.org.about);
    _city = TextEditingController(text: widget.org.city);
    _industry = TextEditingController(text: widget.org.industry);
    _pledges = {...widget.org.inclusivePledges};
  }

  @override
  void dispose() {
    _about.dispose();
    _city.dispose();
    _industry.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await widget.jobs.updateEmployer(
        id: widget.org.id,
        about: _about.text,
        pledges: _pledges.toList(),
        city: _city.text,
        industry: _industry.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
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
        TextField(
          controller: _industry,
          decoration: const InputDecoration(
            labelText: 'Industry',
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
          controller: _about,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'About / inclusion statement',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final p in kInclusionPledges)
              FilterChip(
                label: Text(p),
                selected: _pledges.contains(p),
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _pledges.add(p);
                    } else {
                      _pledges.remove(p);
                    }
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _busy ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(_busy ? 'Saving…' : 'Save profile'),
        ),
      ],
    );
  }
}

class _JobsTab extends StatelessWidget {
  const _JobsTab({required this.org, required this.jobs});

  final EmployerProfile org;
  final JobsService jobs;

  Future<void> _post(BuildContext context) async {
    final title = TextEditingController();
    final summary = TextEditingController();
    final salary = TextEditingController(text: 'Competitive');
    final acc = <String>{'Flexible hours', 'Captioned meetings'};
    var category = 'Technology';
    var workType = 'full-time';
    var remote = true;
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Post a role',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: summary,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Summary',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: salary,
                        decoration: const InputDecoration(
                          labelText: 'Salary label',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Remote'),
                        value: remote,
                        onChanged: (v) => setModal(() => remote = v),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final a in [
                            'Flexible hours',
                            'Captioned meetings',
                            'Wheelchair-accessible office',
                            'Screen reader tooling',
                            'Caregiver leave',
                          ])
                            FilterChip(
                              label: Text(a),
                              selected: acc.contains(a),
                              onSelected: (v) {
                                setModal(() {
                                  if (v) {
                                    acc.add(a);
                                  } else {
                                    acc.remove(a);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Publish'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      if (ok != true || title.text.trim().isEmpty) return;
      await jobs.postJob(
        employer: org,
        title: title.text,
        category: category,
        workType: workType,
        city: org.city,
        summary: summary.text,
        description: summary.text,
        salaryLabel: salary.text,
        remote: remote,
        accommodations: acc.toList(),
        inclusiveFor: const ['mobility', 'hearing', 'cognitive'],
      );
    } finally {
      title.dispose();
      summary.dispose();
      salary.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InclusiveJob>>(
      stream: jobs.watchJobsForEmployer(org.id),
      builder: (context, snap) {
        final list = snap.data ?? const <InclusiveJob>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            FilledButton.icon(
              onPressed: () => _post(context),
              icon: const Icon(Icons.add),
              label: const Text('Post job'),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Text(
                'No roles yet. Posted jobs also appear on Inclusive Jobs.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final j in list)
                Card(
                  child: ListTile(
                    title: Text(j.title),
                    subtitle: Text('${j.workLabel}\n${j.salaryLabel}'),
                    isThreeLine: true,
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _CandidatesTab extends StatelessWidget {
  const _CandidatesTab({required this.org, required this.jobs});

  final EmployerProfile org;
  final JobsService jobs;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JobApplication>>(
      stream: jobs.watchEmployerApplications(org.id),
      builder: (context, snap) {
        final list = snap.data ?? const <JobApplication>[];
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (list.isEmpty) {
          return Center(
            child: Text(
              'No applications yet. Ranked by Passport match when people apply.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final a = list[i];
            return Card(
              child: ListTile(
                title: Text('${a.userName} · ${a.matchScore}% match'),
                subtitle: Text(
                  '${a.jobTitle}\n${a.note.isEmpty ? a.status : a.note}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (s) => jobs.setApplicationStatus(a.id, s),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'submitted', child: Text('Submitted')),
                    PopupMenuItem(value: 'reviewing', child: Text('Reviewing')),
                    PopupMenuItem(value: 'interview', child: Text('Interview')),
                    PopupMenuItem(value: 'offered', child: Text('Offered')),
                    PopupMenuItem(value: 'withdrawn', child: Text('Closed')),
                  ],
                  child: Chip(label: Text(a.status)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AccommodationsTab extends StatelessWidget {
  const _AccommodationsTab({required this.org, required this.jobs});

  final EmployerProfile org;
  final JobsService jobs;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<JobApplication>>(
      stream: jobs.watchEmployerApplications(org.id),
      builder: (context, snap) {
        final list = (snap.data ?? const <JobApplication>[])
            .where((a) => a.requestedAccommodations.isNotEmpty)
            .toList();
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Accommodation requests from applications show here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondary,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final a = list[i];
            return Card(
              child: ListTile(
                title: Text(a.userName),
                subtitle: Text(
                  '${a.jobTitle}\n${a.requestedAccommodations.join(', ')}',
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (s) => jobs.setAccommodationStatus(a.id, s),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'requested', child: Text('Requested')),
                    PopupMenuItem(
                      value: 'in_progress',
                      child: Text('In progress'),
                    ),
                    PopupMenuItem(value: 'fulfilled', child: Text('Fulfilled')),
                  ],
                  child: Chip(label: Text(a.accommodationStatus)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
