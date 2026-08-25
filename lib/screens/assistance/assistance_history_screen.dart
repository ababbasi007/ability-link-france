import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/assistance_taxonomy.dart';
import '../../models/assistance.dart';
import '../../services/assistance_service.dart';
import '../../theme/app_colors.dart';
import '../providers/provider_profile_screen.dart';

class AssistanceHistoryScreen extends StatelessWidget {
  const AssistanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final assist = AssistanceService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Assistance bookings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<AssistanceBooking>>(
        stream: assist.watchMyBookings(),
        builder: (context, snap) {
          final bookings = snap.data ?? const <AssistanceBooking>[];
          if (bookings.isEmpty) {
            return Center(
              child: Text(
                'No assistance bookings yet.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            itemCount: bookings.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final b = bookings[i];
              final when = b.startAt.toLocal();
              final whenLabel =
                  '${when.month}/${when.day} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
              return Card(
                child: ListTile(
                  title: Text(
                    b.providerName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  subtitle: Text(
                    '${assistanceTypeLabel(b.assistanceType)}\n'
                    '${b.service} · ${b.modeLabel}\n'
                    '$whenLabel · ${b.priceLabel} · ${b.paymentStatus}\n'
                    'Status: ${b.status}',
                  ),
                  isThreeLine: true,
                  onTap: b.providerId.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ProviderProfileScreen(
                                providerId: b.providerId,
                              ),
                            ),
                          );
                        },
                  trailing: b.status == 'booked'
                      ? TextButton(
                          onPressed: () => assist.cancelBooking(b.id),
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
