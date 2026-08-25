import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/benefit_scheme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/benefits_service.dart';
import '../../theme/app_colors.dart';
import 'benefit_applications_screen.dart';
import 'benefit_detail_screen.dart';
import 'benefit_eligibility_screen.dart';
import 'government_offices_screen.dart';

class BenefitsHubScreen extends StatefulWidget {
  const BenefitsHubScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<BenefitsHubScreen> createState() => _BenefitsHubScreenState();
}

class _BenefitsHubScreenState extends State<BenefitsHubScreen> {
  final _benefits = BenefitsService();
  final _auth = AuthService();
  late final TextEditingController _query;
  String _category = 'all';

  static const _categories = <(String, String)>[
    ('all', 'All'),
    ('disability', 'Disability'),
    ('financial', 'Financial'),
    ('healthcare', 'Healthcare'),
    ('education', 'Education'),
    ('employment', 'Employment'),
    ('transport', 'Transport'),
    ('housing', 'Housing'),
    ('tax', 'Tax'),
    ('certificate', 'Certificates'),
  ];

  @override
  void initState() {
    super.initState();
    _query = TextEditingController(text: widget.initialQuery);
    runInBackground(_benefits.ensureSeeded(), 'seed benefits');
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Government Benefits',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Eligibility checker',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BenefitEligibilityScreen(),
                ),
              );
            },
            icon: const Icon(Icons.fact_check_outlined),
          ),
          IconButton(
            tooltip: 'My applications',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BenefitApplicationsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.assignment_outlined),
          ),
          IconButton(
            tooltip: 'Offices & contacts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const GovernmentOfficesScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_outlined),
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _auth.watchCurrentProfile(),
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          return StreamBuilder<List<BenefitScheme>>(
            stream: _benefits.watchSchemes(),
            builder: (context, snap) {
              final list = _benefits.filter(
                snap.data ?? seedBenefits,
                query: _query.text,
                category: _category,
                profile: profile,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Text(
                    'Disability, financial, healthcare, education, employment, transport, housing, tax, and certificates — matched to your Passport. Confirm on official sites.',
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
                      ActionChip(
                        avatar: const Icon(Icons.fact_check_outlined, size: 18),
                        label: const Text('Eligibility'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const BenefitEligibilityScreen(),
                            ),
                          );
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.assignment_outlined, size: 18),
                        label: const Text('Applications'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const BenefitApplicationsScreen(),
                            ),
                          );
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(
                          Icons.account_balance_outlined,
                          size: 18,
                        ),
                        label: const Text('Offices'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const GovernmentOfficesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _query,
                    decoration: InputDecoration(
                      hintText: 'Search benefits…',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final (id, label) = _categories[i];
                        final selected = _category == id;
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) => setState(() => _category = id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (list.isEmpty)
                    const Text(
                      'No schemes match. Try another category or search.',
                    )
                  else
                    for (final b in list) ...[
                      _BenefitCard(
                        scheme: b,
                        matchScore: _benefits.matchScore(b, profile),
                        onOpen: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => BenefitDetailScreen(
                                scheme: b,
                                matchScore: _benefits.matchScore(b, profile),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.scheme,
    required this.matchScore,
    required this.onOpen,
  });

  final BenefitScheme scheme;
  final int matchScore;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      scheme.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    '$matchScore%',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${scheme.categoryLabel} · ${scheme.country}${scheme.agency.isEmpty ? '' : ' · ${scheme.agency}'}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                scheme.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.35),
              ),
              if (scheme.deadlineLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Deadline: ${scheme.deadlineLabel}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Open for steps, documents, contacts →',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
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
