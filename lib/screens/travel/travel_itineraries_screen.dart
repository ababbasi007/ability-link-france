import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/travel_destination.dart';
import '../../services/travel_service.dart';
import '../../theme/app_colors.dart';

class TravelItinerariesScreen extends StatelessWidget {
  const TravelItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final travel = TravelService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My itineraries',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<TravelItinerary>>(
        stream: travel.watchMyItineraries(),
        builder: (context, snap) {
          final list = snap.data ?? const <TravelItinerary>[];
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No saved trips yet. Use the AI trip planner.',
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
              final t = list[i];
              return Card(
                child: ListTile(
                  title: Text(
                    t.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${t.days} day(s) · ${t.stopNames.join(' → ')}',
                  ),
                  isThreeLine: t.stopNames.length > 2,
                  trailing: TextButton(
                    onPressed: () => travel.archiveItinerary(t.id),
                    child: const Text('Remove'),
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
