import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/inclusive_job.dart';
import '../../services/jobs_service.dart';
import '../../theme/app_colors.dart';
import 'employer_profile_screen.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({
    super.key,
    required this.job,
    required this.matchScore,
  });

  final InclusiveJob job;
  final int matchScore;

  Future<void> _apply(BuildContext context) async {
    final note = TextEditingController();
    final selected = {...job.accommodations.take(3)};
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Apply — ${job.title}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Passport match $matchScore%. Request accommodations with this application.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final a in job.accommodations)
                            FilterChip(
                              label: Text(a),
                              selected: selected.contains(a),
                              onSelected: (v) {
                                setModal(() {
                                  if (v) {
                                    selected.add(a);
                                  } else {
                                    selected.remove(a);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: note,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Note to employer (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Submit application'),
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
      if (ok != true || !context.mounted) return;
      await JobsService().apply(
        job: job,
        note: note.text.trim().isEmpty
            ? 'I would like to be considered. Please see requested accommodations.'
            : note.text.trim(),
        requestedAccommodations: selected.toList(),
        matchScoreValue: matchScore,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Application submitted.')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      note.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          job.employerName,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            job.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${job.workLabel} · ${job.salaryLabel} · $matchScore% match',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          // Inline rather than a bottom bar: the app-wide navigation already
          // occupies the bottom of every screen.
          ElevatedButton(
            onPressed: () => _apply(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Apply with accommodations',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            job.description,
            style: GoogleFonts.plusJakartaSans(height: 1.45, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            'Accommodations offered',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in job.accommodations)
                Chip(
                  label: Text(a),
                  backgroundColor: AppColors.primaryLight,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Inclusive for',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [for (final t in job.inclusiveFor) Chip(label: Text(t))],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Text(
                job.employerName.characters.first,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              job.employerName,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              job.verifiedEmployer
                  ? 'Verified inclusive employer'
                  : 'Employer profile',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      EmployerProfileScreen(employerId: job.employerId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
