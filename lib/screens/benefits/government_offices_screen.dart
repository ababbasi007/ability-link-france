import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/benefit_scheme.dart';
import '../../services/background_task.dart';
import '../../services/benefits_service.dart';
import '../../theme/app_colors.dart';

class GovernmentOfficesScreen extends StatefulWidget {
  const GovernmentOfficesScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<GovernmentOfficesScreen> createState() =>
      _GovernmentOfficesScreenState();
}

class _GovernmentOfficesScreenState extends State<GovernmentOfficesScreen> {
  final _benefits = BenefitsService();
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.text = widget.initialQuery;
    runInBackground(_benefits.ensureSeeded(), 'seed benefits');
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _maps(GovernmentOffice o) async {
    final uri = o.hasCoords
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${o.lat},${o.lng}',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${o.name} ${o.address}')}',
          );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _dial(String phone) async {
    await launchUrl(Uri.parse('tel:${phone.replaceAll(' ', '')}'));
  }

  Future<void> _mail(String email) async {
    if (!email.contains('@')) return;
    await launchUrl(Uri.parse('mailto:$email'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Government offices',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<GovernmentOffice>>(
        stream: _benefits.watchOffices(),
        builder: (context, snap) {
          final all = snap.data ?? seedGovernmentOffices;
          final list = _benefits.filterOffices(all, query: _query.text);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Text(
                'MDPH, CAF, CPAM, tax, and employment desks — phone, email, hours, and map links.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _query,
                decoration: InputDecoration(
                  hintText: 'Search city, agency, or service…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Text('No offices match.')
              else
                for (final o in list) ...[
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.name,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${o.agency} · ${o.city}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            o.address,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            o.hours,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (o.accessibleNotes.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              o.accessibleNotes,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final s in o.services)
                                Chip(
                                  label: Text(s),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (o.phone.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => _dial(o.phone),
                                  icon: const Icon(
                                    Icons.phone_outlined,
                                    size: 18,
                                  ),
                                  label: Text(o.phone),
                                ),
                              if (o.email.contains('@'))
                                TextButton.icon(
                                  onPressed: () => _mail(o.email),
                                  icon: const Icon(
                                    Icons.email_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Email'),
                                ),
                              TextButton.icon(
                                onPressed: () => _maps(o),
                                icon: const Icon(Icons.map_outlined, size: 18),
                                label: const Text('Map'),
                              ),
                              if (o.url.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => launchUrl(
                                    Uri.parse(o.url),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  icon: const Icon(Icons.open_in_new, size: 18),
                                  label: const Text('Website'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          );
        },
      ),
    );
  }
}
