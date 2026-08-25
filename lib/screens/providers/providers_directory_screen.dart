import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/service_provider.dart';
import '../../services/background_task.dart';
import '../../services/providers_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';
import 'provider_profile_screen.dart';

class ProvidersDirectoryScreen extends StatefulWidget {
  const ProvidersDirectoryScreen({
    super.key,
    this.initialCategory = 'All',
    this.title = 'Providers',
    this.initialSpecialty = '',
    this.availableNowOnly = false,
  });

  final String initialCategory;
  final String title;
  final String initialSpecialty;
  final bool availableNowOnly;

  @override
  State<ProvidersDirectoryScreen> createState() =>
      _ProvidersDirectoryScreenState();
}

class _ProvidersDirectoryScreenState extends State<ProvidersDirectoryScreen> {
  final _service = ProvidersService();
  final _search = TextEditingController();

  late String _category;
  late String _specialty;
  bool _verifiedOnly = false;
  bool _availableOnly = false;

  static const _categories = [
    'All',
    'Assistance',
    'Healthcare',
    'Rehabilitation',
    'Education',
    'Caregiving',
  ];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    _specialty = widget.initialSpecialty;
    _availableOnly = widget.availableNowOnly;
    runInBackground(_service.ensureSeeded(), 'seed service');
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
          widget.title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search doctors, therapists, services…',
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
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = _categories[i];
                final selected = _category == c;
                return ChoiceChip(
                  selected: selected,
                  label: Text(c),
                  onSelected: (_) => setState(() => _category = c),
                  selectedColor: AppColors.primary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                FilterChip(
                  selected: _verifiedOnly,
                  label: const Text('Verified'),
                  onSelected: (v) => setState(() => _verifiedOnly = v),
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _availableOnly,
                  label: const Text('Available now'),
                  onSelected: (v) => setState(() => _availableOnly = v),
                  selectedColor: AppColors.primaryLight,
                  checkmarkColor: AppColors.primary,
                ),
                if (_specialty.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: true,
                    label: Text(_specialty),
                    onSelected: (_) => setState(() => _specialty = ''),
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ServiceProvider>>(
              stream: _service.watchProviders(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text(
                      'Could not load providers.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                final list = _service.filter(
                  snap.data ?? const [],
                  query: _search.text,
                  category: _category,
                  verifiedOnly: _verifiedOnly,
                  availableNowOnly: _availableOnly,
                  specialty: _specialty,
                );
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      'No providers match your filters.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final p = list[i];
                    return _ProviderCard(
                      provider: p,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProviderProfileScreen(providerId: p.id),
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
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});

  final ServiceProvider provider;
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: provider.photoUrl.isEmpty
                    ? Container(
                        width: 64,
                        height: 64,
                        color: AppColors.primaryLight,
                        child: const Icon(
                          Icons.person,
                          color: AppColors.primary,
                        ),
                      )
                    : DecodedNetworkImage(
                        provider.photoUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 64,
                          height: 64,
                          color: AppColors.primaryLight,
                          child: const Icon(
                            Icons.person,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E1B4B),
                            ),
                          ),
                        ),
                        if (provider.verified)
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                      ],
                    ),
                    Text(
                      '${provider.specialty} · ${provider.categoryLabel}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${provider.rating.toStringAsFixed(1)} (${provider.reviewCount})',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (provider.availableNow)
                          Text(
                            'Available',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF22C55E),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          provider.priceLabel,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
