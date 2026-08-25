import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/education_program.dart';
import '../../services/education_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';
import 'education_detail_screen.dart';

class EducationInstitutionsScreen extends StatelessWidget {
  const EducationInstitutionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final edu = EducationService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Institution profiles',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<EducationInstitution>>(
        stream: edu.watchInstitutions(),
        builder: (context, snap) {
          final list = snap.data ?? const <EducationInstitution>[];
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No institutions yet.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final inst = list[i];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            EducationInstitutionDetailScreen(institution: inst),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                inst.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (inst.verified)
                              const Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                        Text(
                          '${inst.kindLabel} · ${inst.city}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          inst.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ],
                    ),
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

class EducationInstitutionDetailScreen extends StatelessWidget {
  const EducationInstitutionDetailScreen({
    super.key,
    required this.institution,
  });

  final EducationInstitution institution;

  @override
  Widget build(BuildContext context) {
    final inst = institution;
    final edu = EducationService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          inst.kindLabel,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<EducationProgram>>(
        stream: edu.watchPrograms(),
        builder: (context, snap) {
          final programs = edu.programsForInstitution(
            snap.data ?? const [],
            inst.id,
          );
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              if (inst.photoUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecodedNetworkImage(
                    inst.photoUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                inst.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${inst.city}${inst.verified ? ' · Verified' : ''}',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
              if (inst.websiteLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  inst.websiteLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                inst.description,
                style: GoogleFonts.plusJakartaSans(height: 1.45, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Text(
                'Accessibility',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final f in inst.accessFeatures)
                    Chip(
                      label: Text(f),
                      backgroundColor: AppColors.primaryLight,
                      side: BorderSide.none,
                    ),
                ],
              ),
              if (inst.disabilityServices.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Disability services',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                for (final s in inst.disabilityServices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (inst.classrooms.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Accessible classrooms',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                for (final c in inst.classrooms)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.meeting_room_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              Text(
                'Programs & opportunities',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (programs.isEmpty)
                Text(
                  'No linked programs yet.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                for (final p in programs)
                  Card(
                    child: ListTile(
                      title: Text(
                        p.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(p.kindLabel),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => EducationDetailScreen(
                              program: p,
                              matchScore: edu.matchScore(p, null),
                            ),
                          ),
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
