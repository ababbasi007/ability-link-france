import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_shared_route.dart';
import '../../services/care_circle_service.dart';
import '../../theme/app_colors.dart';

class CareSharedRoutesScreen extends StatelessWidget {
  const CareSharedRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final care = CareCircleService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Shared routes',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<CareSharedRoute>>(
        stream: care.watchSharedRoutes(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final routes = snap.data ?? const <CareSharedRoute>[];
          if (routes.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No shared routes yet.\nShare a planned route from the Accessibility Map so caregivers can follow the same trip.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = routes[i];
              return Card(
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: Icon(
                      r.profile == 'wheelchair'
                          ? Icons.accessible_rounded
                          : Icons.route_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    r.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${r.destinationName} · ${r.distanceLabel} · ${r.durationLabel}'
                    '${r.createdByName.isEmpty ? '' : '\n${r.createdByName}'}',
                  ),
                  children: [
                    if (r.steps.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text('No turn-by-turn steps stored.'),
                      )
                    else
                      for (final step in r.steps.take(12))
                        ListTile(
                          dense: true,
                          leading: const Icon(Icons.directions_rounded, size: 18),
                          title: Text(step, style: const TextStyle(fontSize: 13)),
                        ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => care.deleteSharedRoute(r.id),
                        child: const Text('Remove'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
