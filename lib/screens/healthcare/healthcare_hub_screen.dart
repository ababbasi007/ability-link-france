import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_appointment.dart';
import '../../models/place.dart';
import '../../services/background_task.dart';
import '../../services/healthcare_service.dart';
import '../../services/places_service.dart';
import '../../services/providers_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/place_detail_sheet.dart';
import '../providers/provider_profile_screen.dart';
import '../providers/providers_directory_screen.dart';
import '../search/search_screen.dart';
import '../tele_rehab/tele_rehab_screen.dart';
import '../telehealth/telehealth_screen.dart';
import 'appointments_screen.dart';
import 'share_needs_screen.dart';

class HealthcareHubScreen extends StatefulWidget {
  const HealthcareHubScreen({super.key});

  @override
  State<HealthcareHubScreen> createState() => _HealthcareHubScreenState();
}

class _HealthcareHubScreenState extends State<HealthcareHubScreen> {
  final _care = HealthcareService();
  final _places = PlacesService();
  final _providers = ProvidersService();

  @override
  void initState() {
    super.initState();
    runInBackground(_care.ensureDemoAppointments(), 'seed appointments');
    runInBackground(_places.ensureSeeded(), 'seed places');
    runInBackground(_providers.ensureSeeded(), 'seed providers');
  }

  Future<void> _referral() async {
    final specialty = TextEditingController(text: 'Physiotherapist');
    final reason = TextEditingController();
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              20 + MediaQuery.viewInsetsOf(ctx).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request a referral',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: specialty.text,
                  decoration: const InputDecoration(
                    labelText: 'Specialty',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Physiotherapist',
                      child: Text('Physiotherapist / Rehab'),
                    ),
                    DropdownMenuItem(
                      value: 'Neurologist',
                      child: Text('Neurologist'),
                    ),
                    DropdownMenuItem(
                      value: 'Occupational Therapist',
                      child: Text('Occupational Therapist'),
                    ),
                    DropdownMenuItem(
                      value: 'Cardiologist',
                      child: Text('Cardiologist'),
                    ),
                    DropdownMenuItem(
                      value: 'Dermatologist',
                      child: Text('Dermatologist'),
                    ),
                    DropdownMenuItem(
                      value: 'Pediatrician',
                      child: Text('Pediatrician'),
                    ),
                    DropdownMenuItem(
                      value: 'Psychiatrist',
                      child: Text('Psychiatrist'),
                    ),
                    DropdownMenuItem(
                      value: 'General Physician',
                      child: Text('General Physician'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) specialty.text = v;
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reason,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Reason / access needs',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Send referral'),
                  ),
                ),
              ],
            ),
          );
        },
      );
      if (ok != true) return;
      try {
        await _care.requestReferral(
          toSpecialty: specialty.text,
          reason: reason.text.trim().isEmpty
              ? 'Accessibility-informed referral'
              : reason.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Referral sent. We matched a provider when possible.',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      specialty.dispose();
      reason.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Healthcare & Rehab',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _HubTile(
            icon: Icons.health_and_safety_rounded,
            title: 'Telehealth',
            subtitle: 'Doctors, video visits, specialists',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const TelehealthScreen()),
            ),
          ),
          _HubTile(
            icon: Icons.accessibility_new_rounded,
            title: 'Tele-rehabilitation',
            subtitle: 'Therapy sessions and home plans',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const TeleRehabScreen()),
            ),
          ),
          _HubTile(
            icon: Icons.local_hospital_outlined,
            title: 'Find clinics',
            subtitle: 'Accessible hospitals and clinics on the map',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const SearchScreen(initialQuery: 'hospital'),
              ),
            ),
          ),
          _HubTile(
            icon: Icons.medical_services_outlined,
            title: 'Find doctors',
            subtitle: 'Verified healthcare providers',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ProvidersDirectoryScreen(
                  initialCategory: 'Healthcare',
                  title: 'Doctors',
                ),
              ),
            ),
          ),
          _HubTile(
            icon: Icons.fitness_center_rounded,
            title: 'Find rehab therapists',
            subtitle: 'PT, OT, and tele-rehab',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ProvidersDirectoryScreen(
                  initialCategory: 'Rehabilitation',
                  title: 'Rehab therapists',
                ),
              ),
            ),
          ),
          _HubTile(
            icon: Icons.event_available_rounded,
            title: 'My appointments',
            subtitle: 'Upcoming visits and sessions',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const AppointmentsScreen(),
              ),
            ),
          ),
          _HubTile(
            icon: Icons.assignment_ind_outlined,
            title: 'Request a referral',
            subtitle: 'Match to a specialist or therapist',
            onTap: _referral,
          ),
          _HubTile(
            icon: Icons.verified_user_outlined,
            title: 'Share needs with a clinic',
            subtitle: 'Consent to share Passport accessibility tags',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const ShareNeedsScreen()),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nearby clinics',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<AccessiblePlace>>(
            stream: _places.watchPlaces(),
            builder: (context, snap) {
              final clinics = (snap.data ?? const <AccessiblePlace>[])
                  .where((p) => p.category == 'hospital')
                  .take(4)
                  .toList();
              if (clinics.isEmpty) {
                return Text(
                  'No clinics in the demo map yet.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                );
              }
              return Column(
                children: [
                  for (final c in clinics)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        c.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(c.address),
                      onTap: () => PlaceDetailSheet.show(
                        context,
                        place: c,
                        isFavorite: false,
                        onFavorite: () {},
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Your referrals',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<CareReferral>>(
            stream: _care.watchReferrals(),
            builder: (context, snap) {
              final list = snap.data ?? const [];
              if (list.isEmpty) {
                return Text(
                  'No referrals yet.',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.textSecondary,
                  ),
                );
              }
              return Column(
                children: [
                  for (final r in list)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        r.toSpecialty,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        r.status == 'matched'
                            ? 'Matched: ${r.matchedProviderName}'
                            : 'Requested · ${r.reason}',
                      ),
                      trailing: r.matchedProviderId.isEmpty
                          ? null
                          : TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => ProviderProfileScreen(
                                      providerId: r.matchedProviderId,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Open'),
                            ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<CareAppointment>>(
            stream: _care.watchAppointments(),
            builder: (context, snap) {
              final n = (snap.data ?? const <CareAppointment>[])
                  .where((a) => a.isUpcoming)
                  .length;
              return Text(
                n == 0
                    ? 'Book a visit from a doctor or therapist profile.'
                    : '$n upcoming appointment${n == 1 ? '' : 's'}.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
