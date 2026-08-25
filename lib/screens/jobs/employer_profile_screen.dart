import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/inclusive_job.dart';
import '../../services/jobs_service.dart';
import '../../theme/app_colors.dart';
import 'job_detail_screen.dart';

class EmployerProfileScreen extends StatefulWidget {
  const EmployerProfileScreen({super.key, required this.employerId});

  final String employerId;

  @override
  State<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends State<EmployerProfileScreen> {
  final _jobs = JobsService();
  EmployerProfile? _employer;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _jobs.ensureSeeded();
      final e = await _jobs.getEmployer(widget.employerId);
      if (!mounted) return;
      setState(() {
        _employer = e;
        _loading = false;
        if (e == null) _error = 'Employer not found';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final e = _employer;
    if (e == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          e.name,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  e.logoHint.isEmpty ? e.name.characters.first : e.logoHint,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.industry} · ${e.city}',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (e.verified)
                      Text(
                        'Verified inclusive employer',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(e.about, style: GoogleFonts.plusJakartaSans(height: 1.45)),
          const SizedBox(height: 16),
          Text(
            'Inclusive pledges',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final p in e.inclusivePledges)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle, color: Color(0xFF22C55E)),
              title: Text(p, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
            ),
          const SizedBox(height: 8),
          Text(
            'Open roles',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          StreamBuilder<List<InclusiveJob>>(
            stream: _jobs.watchJobs(),
            builder: (context, snap) {
              final roles = (snap.data ?? const <InclusiveJob>[])
                  .where((j) => j.employerId == e.id)
                  .toList();
              if (roles.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'No open roles right now.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (final job in roles)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        job.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(job.workLabel),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => JobDetailScreen(
                              job: job,
                              matchScore: _jobs.matchScore(job, null),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
