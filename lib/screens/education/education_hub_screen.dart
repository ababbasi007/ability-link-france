import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/education_program.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/education_service.dart';
import '../../theme/app_colors.dart';
import '../assistance/assistance_marketplace_screen.dart';
import 'education_detail_screen.dart';
import 'education_institution_screen.dart';
import 'education_interests_screen.dart';

class EducationHubScreen extends StatefulWidget {
  const EducationHubScreen({super.key, this.initialKind = 'All'});

  final String initialKind;

  @override
  State<EducationHubScreen> createState() => _EducationHubScreenState();
}

class _EducationHubScreenState extends State<EducationHubScreen> {
  final _edu = EducationService();
  final _auth = AuthService();
  final _search = TextEditingController();
  late String _kind;
  bool _verifiedOnly = false;
  bool _onlineOnly = false;
  bool _specialEdOnly = false;
  bool _signLanguageOnly = false;

  static const _kinds = [
    ('All', 'All'),
    ('school', 'Schools'),
    ('university', 'Universities'),
    ('institute', 'Institutes'),
    ('course', 'Courses'),
    ('scholarship', 'Scholarships'),
    ('special_ed', 'Special ed'),
    ('assistive_tech', 'AT'),
    ('materials', 'Materials'),
    ('sign_language', 'Sign language'),
  ];

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    runInBackground(_edu.ensureSeeded(), 'seed edu');
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
          'Accessible Education',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Institutions',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EducationInstitutionsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_outlined),
          ),
          IconButton(
            tooltip: 'Saved / applications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EducationInterestsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
          IconButton(
            tooltip: 'Education assistance',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AssistanceMarketplaceScreen(
                    title: 'Education support',
                    initialTypeId: 'education_support',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.support_agent_rounded),
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
                    hintText: 'Search schools, courses, AT, scholarships…',
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
                    for (final k in _kinds) ...[
                      FilterChip(
                        label: Text(k.$2),
                        selected: _kind == k.$1,
                        onSelected: (_) => setState(() => _kind = k.$1),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Verified'),
                        selected: _verifiedOnly,
                        onSelected: (v) => setState(() => _verifiedOnly = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Online'),
                        selected: _onlineOnly,
                        onSelected: (v) => setState(() => _onlineOnly = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Special education'),
                        selected: _specialEdOnly,
                        onSelected: (v) => setState(() => _specialEdOnly = v),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Sign language'),
                        selected: _signLanguageOnly,
                        onSelected: (v) =>
                            setState(() => _signLanguageOnly = v),
                      ),
                    ],
                  ),
                ),
              ),
              if (profile != null && profile.accessibilityProfiles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Matched to your Passport: ${profile.accessibilityProfiles.join(', ')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: StreamBuilder<List<EducationProgram>>(
                  stream: _edu.watchPrograms(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = _edu.filter(
                      snap.data ?? const [],
                      query: _search.text,
                      kind: _kind,
                      verifiedOnly: _verifiedOnly,
                      onlineOnly: _onlineOnly,
                      specialEdOnly: _specialEdOnly,
                      signLanguageOnly: _signLanguageOnly,
                      profile: profile,
                    );
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'No opportunities match those filters.',
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
                        final p = list[i];
                        final score = _edu.matchScore(p, profile);
                        return _EduCard(
                          program: p,
                          score: score,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => EducationDetailScreen(
                                  program: p,
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

class _EduCard extends StatelessWidget {
  const _EduCard({
    required this.program,
    required this.score,
    required this.onTap,
  });

  final EducationProgram program;
  final int score;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = program;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      p.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$score% match',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '${p.kindLabel} · ${p.institution} · ${p.modeLabel}'
                '${p.verified ? ' · Verified' : ''}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                p.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
              if (p.accessFeatures.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  p.accessFeatures.take(3).join(' · '),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
