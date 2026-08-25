import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/expansion.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/emergency_actions.dart';
import '../../services/expansion_service.dart';
import '../../theme/app_colors.dart';
import '../emergency/emergency_screen.dart';
import '../accessibility/accessibility_ux_screen.dart';

class ExpansionHubScreen extends StatefulWidget {
  const ExpansionHubScreen({super.key});

  @override
  State<ExpansionHubScreen> createState() => _ExpansionHubScreenState();
}

class _ExpansionHubScreenState extends State<ExpansionHubScreen> {
  final _expansion = ExpansionService();
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
    runInBackground(_expansion.ensureSeeded(), 'seed expansion data');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Global expansion',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Markets'),
              Tab(text: 'Standards'),
              Tab(text: 'Emergency'),
              Tab(text: 'Partners'),
            ],
          ),
        ),
        body: StreamBuilder<UserProfile?>(
          stream: _auth.watchCurrentProfile(),
          builder: (context, profileSnap) {
            final profile = profileSnap.data;
            final selected = _expansion.marketCodeFor(profile);
            return StreamBuilder<List<Market>>(
              stream: _expansion.watchMarkets(),
              builder: (context, marketSnap) {
                final markets = marketSnap.data ?? const <Market>[];
                if (markets.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final mine = markets.firstWhere(
                  (m) => m.code == selected,
                  orElse: () => markets.first,
                );
                return TabBarView(
                  children: [
                    _MarketsTab(
                      markets: markets,
                      selected: mine,
                      onSelect: (code) => _expansion.setMyMarket(code),
                    ),
                    _StandardsTab(market: mine, profile: profile),
                    _EmergencyTab(market: mine),
                    _PartnersTab(expansion: _expansion, market: mine),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MarketsTab extends StatelessWidget {
  const _MarketsTab({
    required this.markets,
    required this.selected,
    required this.onSelect,
  });

  final List<Market> markets;
  final Market selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Your market: ${selected.name}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Currency ${selected.formatMoney(selected.samplePrice)} · languages ${selected.languages.join(', ')}. UI language is still under Access & language.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AccessibilityUxScreen(),
              ),
            );
          },
          child: const Text('Open app language settings'),
        ),
        const SizedBox(height: 8),
        for (final m in markets)
          Card(
            color: m.code == selected.code ? AppColors.primaryLight : null,
            child: ListTile(
              title: Text('${m.name} · ${m.currency}'),
              subtitle: Text('Emergency ${m.emergencyNumber} · ${m.standard}'),
              trailing: m.code == selected.code
                  ? const Icon(Icons.check_circle, color: AppColors.success)
                  : null,
              onTap: () => onSelect(m.code),
            ),
          ),
      ],
    );
  }
}

class _StandardsTab extends StatelessWidget {
  const _StandardsTab({required this.market, required this.profile});

  final Market market;
  final UserProfile? profile;

  @override
  Widget build(BuildContext context) {
    final tags = ExpansionService().matchingStandards(profile, market);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          market.standard,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          market.standardSummary,
          style: GoogleFonts.plusJakartaSans(height: 1.4),
        ),
        const SizedBox(height: 16),
        Text(
          'Matched to your Passport',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final t in tags) Chip(label: Text(t))],
        ),
        const SizedBox(height: 16),
        Text(
          'Place taxonomy',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        Text(market.placeTaxonomy.join(' · ')),
        const SizedBox(height: 12),
        Text(
          'Provider taxonomy',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        Text(market.providerTaxonomy.join(' · ')),
      ],
    );
  }
}

class _EmergencyTab extends StatelessWidget {
  const _EmergencyTab({required this.market});

  final Market market;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Text(
          'Call ${market.emergencyNumber}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Relay / captioned: ${market.relayNumber.isEmpty ? 'use local relay' : market.relayNumber}',
          style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => EmergencyActions.call(market.emergencyNumber),
          icon: const Icon(Icons.phone_in_talk_rounded),
          label: Text('Call ${market.emergencyNumber}'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const EmergencyScreen()),
            );
          },
          icon: const Icon(Icons.sos_rounded),
          label: const Text('Open SOS & local resources'),
        ),
        const SizedBox(height: 12),
        Text(
          'SOS and the Emergency screen filter resources to ${market.name}. Always call ${market.emergencyNumber} if you are in danger.',
          style: GoogleFonts.plusJakartaSans(height: 1.4),
        ),
      ],
    );
  }
}

class _PartnersTab extends StatefulWidget {
  const _PartnersTab({required this.expansion, required this.market});

  final ExpansionService expansion;
  final Market market;

  @override
  State<_PartnersTab> createState() => _PartnersTabState();
}

class _PartnersTabState extends State<_PartnersTab> {
  final _name = TextEditingController();
  final _summary = TextEditingController();
  String _kind = 'ngo';

  @override
  void dispose() {
    _name.dispose();
    _summary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ExpansionPartner?>(
      stream: widget.expansion.watchMyPartner(),
      builder: (context, mineSnap) {
        return StreamBuilder<List<ExpansionPartner>>(
          stream: widget.expansion.watchPartners(
            marketCode: widget.market.code,
          ),
          builder: (context, listSnap) {
            final mine = mineSnap.data;
            final list = listSnap.data ?? const <ExpansionPartner>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  'Partner portal · ${widget.market.name}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Cities, NGOs, and operators can list a local desk. This is not the provider or employer portal.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                if (mine != null)
                  Card(
                    color: AppColors.primaryLight,
                    child: ListTile(
                      title: Text(mine.name),
                      subtitle: Text(
                        '${mine.kind} · ${mine.marketCode} · ${mine.status}',
                      ),
                    ),
                  ),
                TextField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: mine == null
                        ? 'Organisation name'
                        : 'Update name',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _kind,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Partner type',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'city',
                      child: Text('City / region'),
                    ),
                    DropdownMenuItem(value: 'gov', child: Text('Government')),
                    DropdownMenuItem(value: 'ngo', child: Text('NGO')),
                    DropdownMenuItem(
                      value: 'operator',
                      child: Text('Transit / venue operator'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _kind = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _summary,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'How you help locally',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    await widget.expansion.registerPartner(
                      name: _name.text.isEmpty
                          ? (mine?.name ?? 'Local partner')
                          : _name.text,
                      marketCode: widget.market.code,
                      kind: _kind,
                      summary: _summary.text,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Partner listing saved')),
                    );
                  },
                  child: Text(
                    mine == null ? 'Publish partner listing' : 'Update listing',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'In ${widget.market.name}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('No partners in this market yet.'),
                  )
                else
                  for (final p in list)
                    ListTile(
                      title: Text(p.name),
                      subtitle: Text('${p.kind} · ${p.summary}'),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}
