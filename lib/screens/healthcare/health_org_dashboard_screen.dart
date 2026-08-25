import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_appointment.dart';
import '../../models/health_org.dart';
import '../../models/service_provider.dart';
import '../../services/background_task.dart';
import '../../services/health_org_service.dart';
import '../../services/providers_service.dart';
import '../../theme/app_colors.dart';

class HealthOrgDashboardScreen extends StatefulWidget {
  const HealthOrgDashboardScreen({super.key});

  @override
  State<HealthOrgDashboardScreen> createState() =>
      _HealthOrgDashboardScreenState();
}

class _HealthOrgDashboardScreenState extends State<HealthOrgDashboardScreen> {
  final _orgs = HealthOrgService();
  final _providers = ProvidersService();

  @override
  void initState() {
    super.initState();
    runInBackground(_providers.ensureSeeded(), 'seed providers');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HealthOrg?>(
      stream: _orgs.watchMyOrg(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final org = snap.data;
        if (org == null) return _ClinicSignup(orgs: _orgs);
        return DefaultTabController(
          length: 5,
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(
                'Clinic dashboard',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              bottom: const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Reports'),
                  Tab(text: 'Providers'),
                  Tab(text: 'Patients'),
                  Tab(text: 'Referrals'),
                  Tab(text: 'Appointments'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _ReportsTab(org: org, orgs: _orgs),
                _StaffTab(org: org, orgs: _orgs, providers: _providers),
                _PatientsTab(org: org, orgs: _orgs),
                _ReferralsTab(org: org, orgs: _orgs),
                _AppointmentsTab(org: org, orgs: _orgs),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClinicSignup extends StatefulWidget {
  const _ClinicSignup({required this.orgs});

  final HealthOrgService orgs;

  @override
  State<_ClinicSignup> createState() => _ClinicSignupState();
}

class _ClinicSignupState extends State<_ClinicSignup> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _about = TextEditingController();
  String _kind = 'clinic';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clinic name is required')));
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.orgs.createOrg(
        name: _name.text,
        city: _city.text,
        kind: _kind,
        about: _about.text,
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
          'Clinic dashboard',
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
            'Manage staff, consented accessibility needs, referrals, and clinic appointments.',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Clinic / hospital name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: _kind,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'clinic', child: Text('Clinic')),
              DropdownMenuItem(value: 'hospital', child: Text('Hospital')),
              DropdownMenuItem(value: 'rehab', child: Text('Rehab network')),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _kind = v);
            },
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
              labelText: 'About',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _busy ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            child: Text(_busy ? 'Saving…' : 'Create organisation'),
          ),
        ],
      ),
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab({required this.org, required this.orgs});

  final HealthOrg org;
  final HealthOrgService orgs;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrgStaffMember>>(
      stream: orgs.watchStaff(org.id),
      builder: (context, staffSnap) {
        return StreamBuilder<List<PatientConsent>>(
          stream: orgs.watchConsents(org.id),
          builder: (context, consentSnap) {
            return StreamBuilder<List<CareAppointment>>(
              stream: orgs.watchOrgAppointments(org.id),
              builder: (context, apptSnap) {
                return StreamBuilder<List<CareReferral>>(
                  stream: orgs.watchOrgReferrals(org.id),
                  builder: (context, refSnap) {
                    final staff = staffSnap.data ?? const <OrgStaffMember>[];
                    final patients =
                        consentSnap.data ?? const <PatientConsent>[];
                    final appts = apptSnap.data ?? const <CareAppointment>[];
                    final refs = refSnap.data ?? const <CareReferral>[];
                    final upcoming = appts.where((a) => a.isUpcoming).length;
                    final needs = orgs.needsReport(patients);
                    final top = needs.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));
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
                          '${org.kindLabel} · ${org.city}',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Kpi(label: 'Staff', value: '${staff.length}'),
                            _Kpi(
                              label: 'Patients',
                              value: '${patients.length}',
                            ),
                            _Kpi(label: 'Upcoming', value: '$upcoming'),
                            _Kpi(label: 'Referrals', value: '${refs.length}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Consented needs',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (top.isEmpty)
                          Text(
                            'No consented Passport needs yet. Patients share from Healthcare.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          for (final e in top.take(8))
                            ListTile(
                              dense: true,
                              title: Text(e.key),
                              trailing: Text(
                                '${e.value}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
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

class _StaffTab extends StatelessWidget {
  const _StaffTab({
    required this.org,
    required this.orgs,
    required this.providers,
  });

  final HealthOrg org;
  final HealthOrgService orgs;
  final ProvidersService providers;

  Future<void> _add(BuildContext context) async {
    final all = await providers.watchProviders().first;
    if (!context.mounted) return;
    final picked = await showModalBottomSheet<ServiceProvider>(
      context: context,
      builder: (ctx) {
        return ListView(
          children: [
            for (final p in all)
              ListTile(
                title: Text(p.name),
                subtitle: Text('${p.specialty} · ${p.city}'),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        );
      },
    );
    if (picked != null) await orgs.addStaff(org.id, picked);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrgStaffMember>>(
      stream: orgs.watchStaff(org.id),
      builder: (context, snap) {
        final list = snap.data ?? const <OrgStaffMember>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Add provider from directory'),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Text(
                'Add clinicians from Find Providers to this organisation.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final s in list)
                Card(
                  child: ListTile(
                    title: Text(s.name),
                    subtitle: Text(s.specialty),
                    trailing: IconButton(
                      tooltip: 'Remove staff member',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => orgs.removeStaff(org.id, s.providerId),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _PatientsTab extends StatelessWidget {
  const _PatientsTab({required this.org, required this.orgs});

  final HealthOrg org;
  final HealthOrgService orgs;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PatientConsent>>(
      stream: orgs.watchConsents(org.id),
      builder: (context, snap) {
        final list = snap.data ?? const <PatientConsent>[];
        if (list.isEmpty) {
          return Center(
            child: Text(
              'Patients who consent from Healthcare appear here with Passport needs only.',
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
            final c = list[i];
            return Card(
              child: ListTile(
                title: Text(c.patientName),
                subtitle: Text(
                  c.needs.isEmpty ? 'No tagged needs' : c.needs.join(', '),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ReferralsTab extends StatelessWidget {
  const _ReferralsTab({required this.org, required this.orgs});

  final HealthOrg org;
  final HealthOrgService orgs;

  Future<void> _add(BuildContext context) async {
    final patients = await orgs.watchConsents(org.id).first;
    final staff = await orgs.watchStaff(org.id).first;
    if (!context.mounted) return;
    if (patients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need a consented patient first')),
      );
      return;
    }
    var patient = patients.first;
    OrgStaffMember? match = staff.isEmpty ? null : staff.first;
    final specialty = TextEditingController(text: match?.specialty ?? 'Physio');
    final reason = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return AlertDialog(
                title: const Text('New referral'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<PatientConsent>(
                        // ignore: deprecated_member_use
                        value: patient,
                        items: [
                          for (final p in patients)
                            DropdownMenuItem(
                              value: p,
                              child: Text(p.patientName),
                            ),
                        ],
                        onChanged: (v) {
                          if (v != null) setModal(() => patient = v);
                        },
                      ),
                      TextField(
                        controller: specialty,
                        decoration: const InputDecoration(
                          labelText: 'Specialty',
                        ),
                      ),
                      TextField(
                        controller: reason,
                        decoration: const InputDecoration(labelText: 'Reason'),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Create'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (ok == true) {
        await orgs.createOrgReferral(
          orgId: org.id,
          patient: patient,
          toSpecialty: specialty.text,
          reason: reason.text,
          staff: match,
        );
      }
    } finally {
      specialty.dispose();
      reason.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CareReferral>>(
      stream: orgs.watchOrgReferrals(org.id),
      builder: (context, snap) {
        final list = snap.data ?? const <CareReferral>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.assignment_add),
              label: const Text('Create referral'),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Text(
                'Clinic referrals for consented patients show here.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final r in list)
                Card(
                  child: ListTile(
                    title: Text(
                      r.patientName.isEmpty ? r.toSpecialty : r.patientName,
                    ),
                    subtitle: Text(
                      '${r.toSpecialty} · ${r.status}'
                      '${r.matchedProviderName.isEmpty ? '' : '\n${r.matchedProviderName}'}',
                    ),
                    isThreeLine: r.matchedProviderName.isNotEmpty,
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _AppointmentsTab extends StatelessWidget {
  const _AppointmentsTab({required this.org, required this.orgs});

  final HealthOrg org;
  final HealthOrgService orgs;

  Future<void> _add(BuildContext context) async {
    final patients = await orgs.watchConsents(org.id).first;
    final staff = await orgs.watchStaff(org.id).first;
    if (!context.mounted) return;
    if (patients.isEmpty || staff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add staff and a consented patient first'),
        ),
      );
      return;
    }
    var patient = patients.first;
    var member = staff.first;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              title: const Text('Book clinic visit'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<PatientConsent>(
                    // ignore: deprecated_member_use
                    value: patient,
                    items: [
                      for (final p in patients)
                        DropdownMenuItem(value: p, child: Text(p.patientName)),
                    ],
                    onChanged: (v) {
                      if (v != null) setModal(() => patient = v);
                    },
                  ),
                  DropdownButtonFormField<OrgStaffMember>(
                    // ignore: deprecated_member_use
                    value: member,
                    items: [
                      for (final s in staff)
                        DropdownMenuItem(value: s, child: Text(s.name)),
                    ],
                    onChanged: (v) {
                      if (v != null) setModal(() => member = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('Scheduled for tomorrow 10:00'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Book'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      final now = DateTime.now();
      await orgs.createOrgAppointment(
        orgId: org.id,
        patient: patient,
        staff: member,
        startAt: DateTime(now.year, now.month, now.day + 1, 10),
        notes:
            'Booked from clinic dashboard. Needs: ${patient.needs.join(', ')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CareAppointment>>(
      stream: orgs.watchOrgAppointments(org.id),
      builder: (context, snap) {
        final list = snap.data ?? const <CareAppointment>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            FilledButton.icon(
              onPressed: () => _add(context),
              icon: const Icon(Icons.event_available),
              label: const Text('Book appointment'),
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              Text(
                'Clinic-booked visits for consented patients show here.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              )
            else
              for (final a in list)
                Card(
                  child: ListTile(
                    title: Text(
                      a.patientName.isEmpty ? a.providerName : a.patientName,
                    ),
                    subtitle: Text(
                      '${a.whenLabel} · ${a.providerName}\n${a.status}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (s) => orgs.setAppointmentStatus(a.id, s),
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
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
