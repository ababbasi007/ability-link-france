import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/education_program.dart';
import '../../services/education_service.dart';
import '../../theme/app_colors.dart';

class EducationInterestsScreen extends StatelessWidget {
  const EducationInterestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final edu = EducationService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My education list',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<EducationInterest>>(
        stream: edu.watchMyInterests(),
        builder: (context, snap) {
          final list = snap.data ?? const <EducationInterest>[];
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (list.isEmpty) {
            return Center(
              child: Text(
                'Bookmark courses, schools, AT, and scholarships — or track applications.',
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
                    a.programName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${a.kind} · ${a.status} · ${a.matchScore}% match\n${a.note}',
                  ),
                  isThreeLine: true,
                  trailing: a.status == 'withdrawn'
                      ? null
                      : TextButton(
                          onPressed: () => edu.withdraw(a.id),
                          child: const Text('Withdraw'),
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
