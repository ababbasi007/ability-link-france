import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/education_program.dart';
import '../../services/education_service.dart';
import '../../theme/app_colors.dart';
import '../assistance/assistance_marketplace_screen.dart';
import 'education_institution_screen.dart';

class EducationDetailScreen extends StatelessWidget {
  const EducationDetailScreen({
    super.key,
    required this.program,
    required this.matchScore,
  });

  final EducationProgram program;
  final int matchScore;

  Future<void> _submit(BuildContext context, {required String status}) async {
    final note = TextEditingController();
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status == 'applied'
                        ? 'Application / enquire'
                        : 'Save / bookmark',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${program.name} · Passport match $matchScore%',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (program.applicationSteps.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Application steps',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    for (var i = 0; i < program.applicationSteps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${i + 1}. ${program.applicationSteps[i]}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                  ],
                  if (program.applicationNotes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      program.applicationNotes,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: note,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Access needs or questions',
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
                      child: Text(
                        status == 'applied'
                            ? 'Submit application interest'
                            : 'Bookmark',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      if (ok != true || !context.mounted) return;
      await EducationService().expressInterest(
        program: program,
        status: status,
        matchScoreValue: matchScore,
        note: note.text.trim().isEmpty
            ? 'Please consider my Accessibility Passport needs.'
            : note.text.trim(),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'applied'
                ? 'Application interest recorded.'
                : 'Saved to your education list.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      note.dispose();
    }
  }

  Widget _section(String title, List<String> items, IconData icon) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = program;
    final edu = EducationService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          p.kindLabel,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            p.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${p.institution} · ${p.city} · ${p.modeLabel} · $matchScore% match'
            '${p.verified ? ' · Verified' : ''}',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
          if (p.awardLabel.isNotEmpty || p.deadlineLabel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (p.awardLabel.isNotEmpty) p.awardLabel,
                if (p.deadlineLabel.isNotEmpty) 'Deadline: ${p.deadlineLabel}',
              ].join(' · '),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
          const SizedBox(height: 14),
          // Inline rather than a bottom bar: the app-wide navigation already
          // occupies the bottom of every screen.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _submit(context, status: 'interested'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Bookmark'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () => _submit(context, status: 'applied'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    p.kind == 'scholarship'
                        ? 'Apply for award'
                        : p.kind == 'course' || p.kind == 'materials'
                        ? 'Enroll / save'
                        : 'Apply / enquire',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            p.description,
            style: GoogleFonts.plusJakartaSans(height: 1.45, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            'Disability-friendly features',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (p.specialEducation)
                Chip(
                  avatar: const Icon(Icons.diversity_3, size: 16),
                  label: const Text('Special education'),
                  backgroundColor: const Color(0xFFE8F1FF),
                  side: BorderSide.none,
                ),
              if (p.signLanguageSupport)
                Chip(
                  avatar: const Icon(Icons.sign_language, size: 16),
                  label: const Text('Sign-language support'),
                  backgroundColor: const Color(0xFFFFF0E8),
                  side: BorderSide.none,
                ),
              if (p.online || p.mode == 'online')
                Chip(
                  avatar: const Icon(Icons.wifi_rounded, size: 16),
                  label: const Text('Online'),
                  backgroundColor: const Color(0xFFE8F8EF),
                  side: BorderSide.none,
                ),
              for (final f in p.accessFeatures)
                Chip(
                  label: Text(f),
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
            children: [for (final t in p.inclusiveFor) Chip(label: Text(t))],
          ),
          _section(
            'Accessible classrooms',
            p.classrooms,
            Icons.meeting_room_outlined,
          ),
          _section(
            'Accessible learning materials',
            p.learningMaterials,
            Icons.menu_book_outlined,
          ),
          _section(
            'Assistive technology',
            p.assistiveTech,
            Icons.hearing_disabled_outlined,
          ),
          if (p.applicationSteps.isNotEmpty ||
              p.applicationNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Application information',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            if (p.applicationNotes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                p.applicationNotes,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 6),
            for (var i = 0; i < p.applicationSteps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${i + 1}. ${p.applicationSteps[i]}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
          ],
          const SizedBox(height: 16),
          if (p.institutionId.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.account_balance_outlined,
                color: AppColors.primary,
              ),
              title: Text(
                'Institution profile',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(p.institution),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final inst = await edu.getInstitution(p.institutionId);
                if (!context.mounted || inst == null) return;
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        EducationInstitutionDetailScreen(institution: inst),
                  ),
                );
              },
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.support_agent, color: AppColors.primary),
            title: Text(
              'Education assistance',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Hire classroom / IEP support assistants'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AssistanceMarketplaceScreen(
                    title: 'Education support',
                    initialTypeId: 'education_support',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
