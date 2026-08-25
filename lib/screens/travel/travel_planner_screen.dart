import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/travel_destination.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/travel_service.dart';
import '../../theme/app_colors.dart';
import '../ai/ai_assistant_screen.dart';
import 'travel_detail_screen.dart';

class TravelPlannerScreen extends StatefulWidget {
  const TravelPlannerScreen({super.key, this.mustInclude});

  final TravelDestination? mustInclude;

  @override
  State<TravelPlannerScreen> createState() => _TravelPlannerScreenState();
}

class _TravelPlannerScreenState extends State<TravelPlannerScreen> {
  final _travel = TravelService();
  final _auth = AuthService();
  int _days = 2;
  PlannedTrip? _trip;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    runInBackground(_travel.ensureSeeded(), 'seed travel');
  }

  void _build(List<TravelDestination> catalog, UserProfile? profile) {
    setState(() {
      _trip = _travel.planTrip(
        catalog: catalog,
        profile: profile,
        days: _days,
        mustInclude: widget.mustInclude,
      );
    });
  }

  Future<void> _save() async {
    final trip = _trip;
    if (trip == null) return;
    setState(() => _saving = true);
    try {
      await _travel.saveItinerary(trip);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Itinerary saved.')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'AI trip planner',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _auth.watchCurrentProfile(),
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          return StreamBuilder<List<TravelDestination>>(
            stream: _travel.watchDestinations(),
            builder: (context, destSnap) {
              final catalog = destSnap.data ?? const <TravelDestination>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  Text(
                    widget.mustInclude == null
                        ? 'Builds a paced, access-aware NYC sketch from your Passport and verified listings. Refine with the assistant after.'
                        : 'Includes ${widget.mustInclude!.name} in your accessible itinerary.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Days',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final d in [1, 2, 3])
                        ChoiceChip(
                          label: Text('$d'),
                          selected: _days == d,
                          onSelected: (_) => setState(() => _days = d),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: catalog.isEmpty
                        ? null
                        : () => _build(catalog, profile),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate accessible itinerary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  if (_trip != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _trip!.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _trip!.notes,
                      style: GoogleFonts.plusJakartaSans(height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _trip!.stops.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        title: Text(
                          _trip!.stops[i].name,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${_trip!.stops[i].kindLabel} · ${_trip!.stops[i].accessFeatures.take(2).join(', ')}',
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => TravelDetailScreen(
                                destination: _trip!.stops[i],
                                matchScore: _travel.matchScore(
                                  _trip!.stops[i],
                                  profile,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        final t = _trip!;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AiAssistantScreen(
                              initialPrompt:
                                  'Refine this accessible itinerary for ${profile?.firstName ?? 'me'}:\n'
                                  '${t.title}\n${t.notes}\n'
                                  'Stops: ${t.stops.map((s) => s.name).join(', ')}.\n'
                                  'Suggest quieter times and step-free transfers.',
                            ),
                          ),
                        );
                      },
                      child: const Text('Refine with AI assistant'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(_saving ? 'Saving…' : 'Save itinerary'),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
