import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/travel_destination.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/reviews_service.dart';
import '../../services/travel_service.dart';
import '../../theme/app_colors.dart';
import '../assistance/assistance_marketplace_screen.dart';
import '../transport/transport_hub_screen.dart';
import 'travel_detail_screen.dart';
import 'travel_itineraries_screen.dart';
import 'travel_planner_screen.dart';
import 'travel_saved_screen.dart';

class TravelHubScreen extends StatefulWidget {
  const TravelHubScreen({super.key});

  @override
  State<TravelHubScreen> createState() => _TravelHubScreenState();
}

class _TravelHubScreenState extends State<TravelHubScreen> {
  final _travel = TravelService();
  final _auth = AuthService();
  final _search = TextEditingController();
  String _kind = 'All';
  bool _verifiedOnly = false;
  bool _wheelchairOnly = false;

  static const _kinds = [
    ('All', 'All'),
    ('hotel', 'Hotels'),
    ('restaurant', 'Restaurants'),
    ('attraction', 'Attractions'),
    ('tour', 'Tours'),
    ('transport', 'Transport'),
  ];

  @override
  void initState() {
    super.initState();
    runInBackground(_travel.ensureSeeded(), 'seed travel');
    runInBackground(ReviewsService().ensureSeeded(), 'seed reviews');
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
          'Accessible Tourism',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Saved',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TravelSavedScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
          IconButton(
            tooltip: 'Bookings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TravelBookingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.confirmation_number_outlined),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              switch (v) {
                case 'itineraries':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TravelItinerariesScreen(),
                    ),
                  );
                case 'transport':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TransportHubScreen(),
                    ),
                  );
                case 'assistance':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AssistanceMarketplaceScreen(
                        title: 'Travel assistance',
                        initialTypeId: 'travel_assistant',
                      ),
                    ),
                  );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'itineraries', child: Text('Itineraries')),
              PopupMenuItem(value: 'transport', child: Text('Transport hub')),
              PopupMenuItem(
                value: 'assistance',
                child: Text('Travel assistance'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const TravelPlannerScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Plan trip'),
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
                    hintText: 'Search hotels, tours, transport…',
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
                    FilterChip(
                      label: const Text('Wheelchair'),
                      selected: _wheelchairOnly,
                      onSelected: (v) => setState(() => _wheelchairOnly = v),
                      avatar: const Icon(Icons.accessible_rounded, size: 16),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Verified'),
                      selected: _verifiedOnly,
                      onSelected: (v) => setState(() => _verifiedOnly = v),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<TravelDestination>>(
                  stream: _travel.watchDestinations(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = _travel.filter(
                      snap.data ?? const [],
                      query: _search.text,
                      kind: _kind,
                      verifiedOnly: _verifiedOnly,
                      wheelchairOnly: _wheelchairOnly,
                      profile: profile,
                    );
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'No destinations match those filters.',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final d = list[i];
                        final score = _travel.matchScore(d, profile);
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TravelDetailScreen(
                                    destination: d,
                                    matchScore: score,
                                  ),
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
                                          d.name,
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
                                    '${d.kindLabel} · ${d.area.isEmpty ? d.city : d.area}'
                                    '${d.wheelchairAccessible ? ' · Wheelchair' : ''}'
                                    '${d.bookable ? ' · Bookable' : ''}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    d.summary,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (d.rating > 0) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      '★ ${d.rating.toStringAsFixed(1)} · ${d.accessFeatures.take(2).join(' · ')}',
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
