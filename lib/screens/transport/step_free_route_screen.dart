import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../models/transport_option.dart';
import '../../services/location_service.dart';
import '../../services/routing_service.dart';
import '../../theme/app_colors.dart';

class StepFreeRouteScreen extends StatefulWidget {
  const StepFreeRouteScreen({super.key, required this.destination});

  final TransportOption destination;

  @override
  State<StepFreeRouteScreen> createState() => _StepFreeRouteScreenState();
}

class _StepFreeRouteScreenState extends State<StepFreeRouteScreen> {
  WalkingRoute? _route;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final origin = LocationService.instance.current;
    final dest = widget.destination;
    final route = await RoutingService().walking(
      fromLat: origin.lat,
      fromLng: origin.lng,
      toLat: dest.lat,
      toLng: dest.lng,
    );
    if (mounted) setState(() => _route = route);
  }

  @override
  Widget build(BuildContext context) {
    final destination = widget.destination;
    final origin = LocationService.instance.current;
    final start = LatLng(origin.lat, origin.lng);
    final end = LatLng(destination.lat, destination.lng);
    final route = _route;
    final points = route?.points ?? [start, end];
    final minutes = route != null
        ? (route.seconds / 60).round().clamp(4, 90)
        : (destination.distanceKm(origin.lat, origin.lng) / 4.2 * 60)
              .clamp(4, 90)
              .round();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Step-free route',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(initialCenter: start, initialZoom: 14),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.abilitylink.app',
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      color: AppColors.primary,
                      strokeWidth: 5,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: start,
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.my_location,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    Marker(
                      point: end,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.place, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  route == null
                      ? 'About ${destination.distanceLabel(origin.lat, origin.lng)} · ~$minutes min at walking pace'
                      : '${route.distanceLabel} · ${route.durationLabel}'
                            '${route.isLive ? ' · OSRM walking' : ' · straight-line fallback'}',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  destination.stepFree
                      ? 'Prefer this destination: marked step-free. ${destination.elevatorLabel}.'
                      : 'This destination may have stairs. ${destination.elevatorLabel}.',
                  style: GoogleFonts.plusJakartaSans(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
