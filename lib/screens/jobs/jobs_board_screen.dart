import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/inclusive_job.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/jobs_service.dart';
import '../../theme/app_colors.dart';
import 'applications_screen.dart';
import 'job_detail_screen.dart';

class JobsBoardScreen extends StatefulWidget {
  const JobsBoardScreen({super.key});

  @override
  State<JobsBoardScreen> createState() => _JobsBoardScreenState();
}

class _JobsBoardScreenState extends State<JobsBoardScreen> {
  final _jobs = JobsService();
  final _auth = AuthService();
  final _search = TextEditingController();
  String _category = 'All';
  bool _remoteOnly = false;
  bool _verifiedOnly = false;

  static const _categories = [
    'All',
    'Technology',
    'Healthcare',
    'Education',
    'Support',
  ];

  @override
  void initState() {
    super.initState();
    runInBackground(_jobs.ensureSeeded(), 'seed jobs');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Inclusive jobs',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ApplicationsScreen(),
                ),
              );
            },
            child: const Text('My applications'),
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _auth.watchCurrentProfile(),
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search roles, employers, accommodations…',
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
                    for (final c in _categories) ...[
                      FilterChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) => setState(() => _category = c),
                      ),
                      const SizedBox(width: 8),
                    ],
                    FilterChip(
                      label: const Text('Remote'),
                      selected: _remoteOnly,
                      onSelected: (v) => setState(() => _remoteOnly = v),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Verified employer'),
                      selected: _verifiedOnly,
                      onSelected: (v) => setState(() => _verifiedOnly = v),
                    ),
                  ],
                ),
              ),
              if (profile != null && profile.accessibilityProfiles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ranked for your Passport: ${profile.accessibilityProfiles.join(', ')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<InclusiveJob>>(
                  stream: _jobs.watchJobs(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = _jobs.filter(
                      snap.data ?? const [],
                      query: _search.text,
                      category: _category,
                      remoteOnly: _remoteOnly,
                      verifiedOnly: _verifiedOnly,
                      profile: profile,
                    );
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'No roles match those filters.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final job = list[i];
                        final score = _jobs.matchScore(job, profile);
                        return _JobCard(
                          job: job,
                          score: score,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => JobDetailScreen(
                                  job: job,
                                  matchScore: score,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job, required this.score, required this.onTap});

  final InclusiveJob job;
  final int score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$score% match',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${job.employerName} · ${job.workLabel}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                job.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.35),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (job.verifiedEmployer)
                    const _MiniChip(
                      label: 'Verified',
                      color: AppColors.primary,
                    ),
                  if (job.remote)
                    const _MiniChip(label: 'Remote', color: Color(0xFF14B8A6)),
                  _MiniChip(
                    label: job.salaryLabel,
                    color: const Color(0xFF6B7280),
                  ),
                  for (final a in job.accommodations.take(2))
                    _MiniChip(label: a, color: const Color(0xFF6B7280)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
