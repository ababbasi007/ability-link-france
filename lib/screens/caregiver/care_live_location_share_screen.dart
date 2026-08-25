import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/care_circle_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';

class CareLiveLocationShareScreen extends StatefulWidget {
  const CareLiveLocationShareScreen({super.key});

  @override
  State<CareLiveLocationShareScreen> createState() =>
      _CareLiveLocationShareScreenState();
}

class _CareLiveLocationShareScreenState
    extends State<CareLiveLocationShareScreen> {
  final _care = CareCircleService();

  Timer? _timer;
  bool _sharing = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _sharing = true;
      _error = null;
    });

    // Publish immediately, then periodically.
    await _publishOnce();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) async {
      await _publishOnce();
    });
  }

  Future<void> _publishOnce() async {
    try {
      final loc = await LocationService.instance.refresh();
      await _care.updateSelfLocation(lat: loc.lat, lng: loc.lng);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _sharing = false;
    });
  }

  String _formatCoords(AppLatLng? loc) {
    if (loc == null) return 'No location shared yet';
    return 'Lat ${loc.lat.toStringAsFixed(5)} · Lng ${loc.lng.toStringAsFixed(5)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live location sharing',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      backgroundColor: AppColors.background,
      body: StreamBuilder<AppLatLng?>(
        stream: _care.watchSelfLocation(),
        builder: (context, locSnap) {
          return StreamBuilder<DateTime?>(
            stream: _care.watchSelfLocationUpdatedAt(),
            builder: (context, updatedSnap) {
              final loc = locSnap.data;
              final updatedAt = updatedSnap.data;

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your current GPS position will be updated every 20 seconds.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _formatCoords(loc),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                updatedAt == null
                                    ? 'Not shared yet'
                                    : 'Last updated: ${updatedAt.toLocal()}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Error: $_error',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _sharing ? null : _start,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Start sharing'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _sharing ? _stop : null,
                              icon: const Icon(Icons.stop_rounded),
                              label: const Text('Stop'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Note: This demo writes location into your care circle data so other care screens can read it. It does not send location to external users.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

