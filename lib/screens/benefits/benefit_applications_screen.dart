import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/benefit_scheme.dart';
import '../../services/benefits_service.dart';
import '../../theme/app_colors.dart';

const _statuses = <String, String>{
  'draft': 'Draft',
  'submitted': 'Submitted',
  'in_review': 'In review',
  'approved': 'Approved',
  'denied': 'Denied',
  'withdrawn': 'Withdrawn',
};

class BenefitApplicationsScreen extends StatelessWidget {
  const BenefitApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final benefits = BenefitsService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My applications',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<BenefitApplication>>(
        stream: benefits.watchMyApplications(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data ?? const [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No tracked applications yet. Open a benefit and tap “Track application + set reminder”.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = list[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.schemeName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${a.agency.isEmpty ? a.category : a.agency} · ${_statuses[a.status] ?? a.status}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (a.deadlineLabel.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Deadline: ${a.deadlineLabel}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (a.remindAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Reminder: ${a.remindAt!.toLocal().toString().split('.').first}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (a.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          a.note,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in _statuses.entries)
                            ActionChip(
                              label: Text(e.value),
                              onPressed: a.status == e.key
                                  ? null
                                  : () async {
                                      try {
                                        await benefits.updateApplicationStatus(
                                          applicationId: a.id,
                                          status: e.key,
                                        );
                                      } catch (err) {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text('$err')),
                                        );
                                      }
                                    },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
