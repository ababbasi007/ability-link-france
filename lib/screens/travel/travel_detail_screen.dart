import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/travel_destination.dart';
import '../../services/travel_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';
import '../../widgets/reviews_section.dart';
import '../ai/ai_assistant_screen.dart';
import '../assistance/assistance_marketplace_screen.dart';
import '../map/accessibility_map_screen.dart';
import '../transport/step_free_route_screen.dart';
import '../transport/transport_hub_screen.dart';
import '../../models/transport_option.dart';
import 'travel_booking_sheet.dart';
import 'travel_planner_screen.dart';

class TravelDetailScreen extends StatelessWidget {
  const TravelDetailScreen({
    super.key,
    required this.destination,
    required this.matchScore,
  });

  final TravelDestination destination;
  final int matchScore;

  @override
  Widget build(BuildContext context) {
    final d = destination;
    final travel = TravelService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          d.kindLabel,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          StreamBuilder<Set<String>>(
            stream: travel.watchSavedIds(),
            builder: (context, snap) {
              final saved = snap.data?.contains(d.id) == true;
              return IconButton(
                tooltip: saved ? 'Unsave' : 'Save destination',
                onPressed: () => travel.toggleSaved(d),
                icon: Icon(
                  saved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: AppColors.primary,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (d.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecodedNetworkImage(
                d.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            d.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            '${d.city} · ${d.area} · $matchScore% match'
            '${d.verified ? ' · Verified' : ''}'
            '${d.wheelchairAccessible ? ' · Wheelchair' : ''}',
            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
          ),
          if (d.rating > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${d.rating.toStringAsFixed(1)} (${d.reviewCount} reviews)',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          // Inline rather than a bottom bar: the app-wide navigation
          // already occupies the bottom of every screen.
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AiAssistantScreen(
                          initialPrompt:
                              'Help me visit ${d.name} in ${d.city} with my accessibility needs. Features: ${d.accessFeatures.join(', ')}. Route: ${d.routeNotes}',
                        ),
                      ),
                    );
                  },
                  child: const Text('Ask AI'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AssistanceMarketplaceScreen(
                          title: 'Travel assistance',
                          initialTypeId: 'travel_assistant',
                        ),
                      ),
                    );
                  },
                  child: const Text('Get help'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => TravelPlannerScreen(mustInclude: d),
                      ),
                    );
                  },
                  child: const Text('Add to itinerary'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: d.bookable
                      ? () async {
                          final ok = await showTravelBookingSheet(
                            context,
                            destination: d,
                          );
                          if (ok == true && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Travel service booked.'),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    d.bookable ? 'Book ${d.bookPriceLabel}' : 'Not bookable',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            d.description,
            style: GoogleFonts.plusJakartaSans(height: 1.45, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Text(
            'Accessibility information',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (d.wheelchairAccessible)
                Chip(
                  avatar: const Icon(Icons.accessible_rounded, size: 16),
                  label: const Text('Wheelchair accessible'),
                  backgroundColor: const Color(0xFFE8F8EF),
                  side: BorderSide.none,
                ),
              for (final f in d.accessFeatures)
                Chip(
                  label: Text(f),
                  backgroundColor: AppColors.primaryLight,
                  side: BorderSide.none,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [for (final t in d.inclusiveFor) Chip(label: Text(t))],
          ),
          if (d.accessibleRooms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Accessible rooms',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final r in d.accessibleRooms)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.hotel_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (d.accessibleBathrooms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Accessible bathrooms',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final r in d.accessibleBathrooms)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.wc_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        r,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (d.routeNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Accessible routes',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              d.routeNotes,
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.route_rounded, size: 16),
                  label: const Text('Step-free route'),
                  onPressed: () {
                    if (!d.hasCoords) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TransportHubScreen(),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => StepFreeRouteScreen(
                          destination: TransportOption(
                            id: d.id,
                            kind: 'transit',
                            name: d.name,
                            lat: d.lat,
                            lng: d.lng,
                            summary: d.routeNotes.isEmpty
                                ? d.summary
                                : d.routeNotes,
                            features: d.accessFeatures,
                            stepFree: d.wheelchairAccessible,
                            elevatorStatus: d.wheelchairAccessible
                                ? 'in-service'
                                : 'unknown',
                            verified: d.verified,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Ability Map'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const AccessibilityMapScreen(),
                      ),
                    );
                  },
                ),
                if (d.kind == 'transport')
                  ActionChip(
                    avatar: const Icon(Icons.directions_transit, size: 16),
                    label: const Text('Transport hub'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TransportHubScreen(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          ReviewsSection(
            targetType: 'travel',
            targetId: d.id,
            targetName: d.name,
            fallbackRating: d.rating,
            fallbackCount: d.reviewCount,
            listingVerified: d.verified,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
