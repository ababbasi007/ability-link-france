import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/travel_destination.dart';
import '../../services/travel_service.dart';
import '../../theme/app_colors.dart';
import 'travel_detail_screen.dart';

class TravelSavedScreen extends StatelessWidget {
  const TravelSavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final travel = TravelService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Saved destinations',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<TravelDestination>>(
        stream: travel.watchDestinations(),
        builder: (context, destSnap) {
          final catalog = destSnap.data ?? const <TravelDestination>[];
          return StreamBuilder<Set<String>>(
            stream: travel.watchSavedIds(),
            builder: (context, savedSnap) {
              final ids = savedSnap.data ?? const <String>{};
              final list = catalog.where((d) => ids.contains(d.id)).toList();
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'Save hotels, tours, and attractions from their pages.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final d = list[i];
                  return ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      d.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text('${d.kindLabel} · ${d.city}'),
                    trailing: IconButton(
                      tooltip: 'Remove from saved',
                      icon: const Icon(Icons.bookmark_remove_outlined),
                      onPressed: () => travel.toggleSaved(d),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TravelDetailScreen(
                            destination: d,
                            matchScore: travel.matchScore(d, null),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class TravelBookingsScreen extends StatelessWidget {
  const TravelBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final travel = TravelService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Travel bookings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<TravelBooking>>(
        stream: travel.watchMyBookings(),
        builder: (context, snap) {
          final list = snap.data ?? const <TravelBooking>[];
          if (list.isEmpty) {
            return Center(
              child: Text(
                'No tourism bookings yet.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = list[i];
              final when = b.startAt.toLocal();
              return Card(
                child: ListTile(
                  title: Text(
                    b.destinationName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${b.kind} · ${b.service}\n'
                    '${when.month}/${when.day} · ${b.priceLabel} · ${b.paymentStatus}\n'
                    'Status: ${b.status}',
                  ),
                  isThreeLine: true,
                  trailing: b.status == 'booked'
                      ? TextButton(
                          onPressed: () => travel.cancelBooking(b.id),
                          child: const Text('Cancel'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
