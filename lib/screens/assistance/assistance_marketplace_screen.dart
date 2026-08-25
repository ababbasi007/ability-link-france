import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/assistance_taxonomy.dart';
import '../../models/service_provider.dart';
import '../../services/assistance_service.dart';
import '../../services/background_task.dart';
import '../../services/providers_service.dart';
import '../../theme/app_colors.dart';
import '../emergency/emergency_screen.dart';
import '../providers/provider_profile_screen.dart';
import 'assistance_booking_sheet.dart';
import 'assistance_chat_screens.dart';
import 'assistance_history_screen.dart';

/// Major Assistance Marketplace module.
class AssistanceMarketplaceScreen extends StatefulWidget {
  const AssistanceMarketplaceScreen({
    super.key,
    this.initialTypeId = '',
    this.title = 'Assistance Marketplace',
  });

  final String initialTypeId;
  final String title;

  @override
  State<AssistanceMarketplaceScreen> createState() =>
      _AssistanceMarketplaceScreenState();
}

class _AssistanceMarketplaceScreenState
    extends State<AssistanceMarketplaceScreen> {
  final _assist = AssistanceService();
  final _providers = ProvidersService();
  final _search = TextEditingController();
  late String _typeId;
  String _city = '';
  bool _availableOnly = false;
  bool _verifiedOnly = false;
  int? _maxPrice;

  @override
  void initState() {
    super.initState();
    _typeId = widget.initialTypeId;
    runInBackground(_providers.ensureSeeded(), 'seed providers');
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
        actions: [
          IconButton(
            tooltip: 'Messages',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AssistanceInboxScreen(),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline_rounded),
          ),
          IconButton(
            tooltip: 'Booking history',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AssistanceHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            tooltip: 'Emergency',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EmergencyScreen(),
                ),
              );
            },
            icon: const Icon(Icons.sos_rounded, color: Color(0xFFEF4444)),
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceProvider>>(
        stream: _assist.watchAssistants(),
        builder: (context, snap) {
          final all = snap.data ?? const <ServiceProvider>[];
          final cities = _assist.citiesFrom(all);
          final list = _assist.filterAssistants(
            all,
            query: _search.text,
            assistanceType: _typeId,
            city: _city,
            availableNowOnly: _availableOnly,
            verifiedOnly: _verifiedOnly,
            maxPrice: _maxPrice,
          );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search assistants, skills, languages…',
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
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        selected: _typeId.isEmpty,
                        label: const Text('All services'),
                        onSelected: (_) => setState(() => _typeId = ''),
                        selectedColor: AppColors.primary,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _typeId.isEmpty
                              ? Colors.white
                              : const Color(0xFF1E1B4B),
                        ),
                        backgroundColor: Colors.white,
                        showCheckmark: false,
                      ),
                    ),
                    for (final t in kAssistanceTypes)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: _typeId == t.id,
                          label: Text(t.shortLabel),
                          onSelected: (_) => setState(() => _typeId = t.id),
                          selectedColor: AppColors.primary,
                          labelStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _typeId == t.id
                                ? Colors.white
                                : const Color(0xFF1E1B4B),
                          ),
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                        ),
                      ),
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
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (v) => setState(() => _city = v),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: '',
                            child: Text('Any location'),
                          ),
                          for (final c in cities)
                            PopupMenuItem(value: c, child: Text(c)),
                        ],
                        child: Chip(
                          label: Text(
                            _city.isEmpty ? 'Location' : _city,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          ),
                          avatar: const Icon(Icons.place_outlined, size: 16),
                          backgroundColor: _city.isEmpty
                              ? Colors.white
                              : AppColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<int?>(
                        onSelected: (v) => setState(() => _maxPrice = v),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: null, child: Text('Any price')),
                          PopupMenuItem(value: 25, child: Text('Up to \$25')),
                          PopupMenuItem(value: 35, child: Text('Up to \$35')),
                          PopupMenuItem(value: 50, child: Text('Up to \$50')),
                          PopupMenuItem(value: 75, child: Text('Up to \$75')),
                        ],
                        child: Chip(
                          label: Text(
                            _maxPrice == null ? 'Price' : '≤ \$${_maxPrice}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          ),
                          avatar: const Icon(Icons.payments_outlined, size: 16),
                          backgroundColor: _maxPrice == null
                              ? Colors.white
                              : AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${list.length} assistant${list.length == 1 ? '' : 's'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EmergencyScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Emergency support',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? Center(
                        child: Text(
                          'No assistants match your filters.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final p = list[i];
                          return _AssistantCard(
                            provider: p,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ProviderProfileScreen(
                                    providerId: p.id,
                                    provider: p,
                                  ),
                                ),
                              );
                            },
                            onBook: () => showAssistanceBookingSheet(
                              context,
                              provider: p,
                            ),
                            onMessage: () async {
                              await _assist.ensureThread(provider: p);
                              if (!context.mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      AssistanceChatScreen(provider: p),
                                ),
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

class _AssistantCard extends StatelessWidget {
  const _AssistantCard({
    required this.provider,
    required this.onTap,
    required this.onBook,
    required this.onMessage,
  });

  final ServiceProvider provider;
  final VoidCallback onTap;
  final VoidCallback onBook;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final typeLabel = assistanceTypeLabel(provider.assistanceType);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: provider.photoUrl.isEmpty
                        ? null
                        : NetworkImage(provider.photoUrl),
                    child: provider.photoUrl.isEmpty
                        ? Text(provider.name.isEmpty ? '?' : provider.name[0])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                provider.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            if (provider.verified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          typeLabel.isEmpty
                              ? provider.specialty
                              : '$typeLabel · ${provider.specialty}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.priceLabel}/hr · ${provider.city}'
                          '${provider.availableNow ? ' · Available now' : ''}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: provider.availableNow
                                ? const Color(0xFF22C55E)
                                : const Color(0xFF1E1B4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF59E0B),
                        size: 18,
                      ),
                      Text(
                        provider.rating.toStringAsFixed(1),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (provider.skills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in provider.skills.take(4))
                      Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: AppColors.primaryLight,
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMessage,
                      child: const Text('Message'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: onBook,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text('Book & pay'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
