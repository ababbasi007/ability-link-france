import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/inclusive_job.dart';
import '../../services/jobs_service.dart';
import '../../theme/app_colors.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final _jobs = JobsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My applications',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<JobApplication>>(
        stream: _jobs.watchMyApplications(),
        builder: (context, snap) {
          final list = snap.data ?? const <JobApplication>[];
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No applications yet. Apply from a job listing.',
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
                  title: Text(
                    a.jobTitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${a.employerName}\n${a.status} · ${a.matchScore}% match'
                    '${a.requestedAccommodations.isEmpty ? '' : '\n${a.requestedAccommodations.join(', ')}'}',
                  ),
                  isThreeLine: true,
                  trailing: a.status == 'submitted'
                      ? TextButton(
                          onPressed: () => _jobs.withdraw(a.id),
                          child: const Text('Withdraw'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
