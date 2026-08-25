import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/emergency.dart';
import '../../models/place.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/emergency_actions.dart';
import '../../services/emergency_service.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../theme/app_colors.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key, this.autoShareLocation = false});

  final bool autoShareLocation;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final _auth = AuthService();
  final _emergency = EmergencyService();
  final _places = PlacesService();
  bool _sending = false;
  bool _seededContacts = false;
  bool _sharing = false;
  String _resourceKind = 'all';

  @override
  void initState() {
    super.initState();
    runInBackground(_emergency.ensureResourcesSeeded(), 'seed emergency');
    LocationService.instance.ensure();
    if (widget.autoShareLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final profile = await _auth.getCurrentProfile();
        if (profile == null || !mounted) return;
        final contacts = await _emergency.watchContacts().first;
        await _shareLocation(profile, contacts);
      });
    }
  }

  Future<void> _sos(UserProfile profile, List<TrustedContact> contacts) async {
    final market = _emergency.marketFor(profile);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send SOS?'),
        content: Text(
          'This saves your GPS, medical, and accessibility details, notifies linked contacts in-app, and opens SMS to your trusted numbers. Then call ${market.emergencyNumber} if you are in danger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _sending = true);
    try {
      final result = await _emergency.triggerSos(
        profile: profile,
        contacts: contacts,
      );
      await Clipboard.setData(ClipboardData(text: result.copyText));
      final phones = contacts
          .map((c) => c.phone)
          .where((p) => p.trim().isNotEmpty)
          .toList();
      if (phones.isNotEmpty) {
        await EmergencyActions.sms(phones: phones, body: result.copyText);
      }
      if (!mounted) return;
      final call = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('SOS sent'),
          content: Text(
            'Alert saved with location, medical, and accessibility details. '
            'SMS composer opened for your contacts.\n\nCall ${market.emergencyNumber} now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Call ${market.emergencyNumber}'),
            ),
          ],
        ),
      );
      if (call == true) {
        await EmergencyActions.call(market.emergencyNumber);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editContact({TrustedContact? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final relation = TextEditingController(text: existing?.relation ?? '');
    var isPrimary = existing?.isPrimary ?? false;
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setLocal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null ? 'Trusted contact' : 'Edit contact',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: relation,
                      decoration: const InputDecoration(
                        labelText: 'Relation',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Primary contact'),
                      value: isPrimary,
                      onChanged: (v) => setLocal(() => isPrimary = v),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text(existing == null ? 'Save' : 'Update'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      if (ok != true || name.text.trim().isEmpty) return;
      if (existing == null) {
        await _emergency.addContact(
          name: name.text,
          phone: phone.text,
          relation: relation.text,
          isPrimary: isPrimary,
        );
      } else {
        await _emergency.updateContact(
          id: existing.id,
          name: name.text,
          phone: phone.text,
          relation: relation.text,
          isPrimary: isPrimary,
          linkedUid: existing.linkedUid,
        );
      }
    } finally {
      name.dispose();
      phone.dispose();
      relation.dispose();
    }
  }

  Future<void> _shareLocation(
    UserProfile profile,
    List<TrustedContact> contacts,
  ) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final pin = await _emergency.shareLocation(profile: profile);
      final text = _emergency.locationShareMessage(pin, profile);
      await Clipboard.setData(ClipboardData(text: text));
      final phones = contacts
          .map((c) => c.phone)
          .where((p) => p.trim().isNotEmpty)
          .toList();
      if (phones.isNotEmpty) {
        await EmergencyActions.sms(phones: phones, body: text);
      }
      await EmergencyActions.maps(lat: pin.lat, lng: pin.lng, label: 'SOS');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location code ${pin.id.toUpperCase()} sent to contacts (2 hours).',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _openShare() async {
    final code = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Open location code'),
          content: TextField(
            controller: code,
            decoration: const InputDecoration(labelText: 'Code'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Open'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      final pin = await _emergency.openLocationShare(code.text);
      if (!mounted) return;
      if (pin == null || !pin.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code not found or expired.')),
        );
        return;
      }
      await EmergencyActions.maps(lat: pin.lat, lng: pin.lng);
    } finally {
      code.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final origin = LocationService.instance.current;
    return StreamBuilder<UserProfile?>(
      stream: _auth.watchCurrentProfile(),
      builder: (context, profileSnap) {
        final profile = profileSnap.data;
        if (profile != null && !_seededContacts) {
          _seededContacts = true;
          _emergency.ensureContactsFromPassport(profile);
        }
        final market = profile == null ? null : _emergency.marketFor(profile);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              'Emergency SOS',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            actions: [
              TextButton(onPressed: _openShare, child: const Text('Open code')),
            ],
          ),
          body: profile == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<List<TrustedContact>>(
                  stream: _emergency.watchContacts(),
                  builder: (context, contactSnap) {
                    final contacts =
                        contactSnap.data ?? const <TrustedContact>[];
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _sending
                                ? null
                                : () => _sos(profile, contacts),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.sos,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.sos_rounded),
                            label: Text(
                              _sending
                                  ? 'Sending…'
                                  : 'SOS — alert contacts & share location',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Saves GPS, medical, and accessibility needs, then opens SMS to your contacts. Always call ${market?.emergencyNumber ?? '112'} if you are in danger.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: market == null
                                    ? null
                                    : () => EmergencyActions.call(
                                        market.emergencyNumber,
                                      ),
                                icon: const Icon(Icons.phone_in_talk_rounded),
                                label: Text(
                                  'Call ${market?.emergencyNumber ?? ''}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (market != null && market.relayNumber.isNotEmpty)
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      EmergencyActions.call(market.relayNumber),
                                  icon: const Icon(Icons.hearing_rounded),
                                  label: Text('Relay ${market.relayNumber}'),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _sharing
                                    ? null
                                    : () => _shareLocation(profile, contacts),
                                icon: const Icon(Icons.share_location),
                                label: Text(
                                  _sharing ? 'Sharing…' : 'Share my location',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => EmergencyActions.maps(
                                  lat: origin.lat,
                                  lng: origin.lng,
                                  label: 'Me',
                                ),
                                icon: const Icon(Icons.my_location),
                                label: const Text('Open my map'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _PassportEmergencyCard(profile: profile),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Trusted contacts',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _editContact(),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                        if (contacts.isEmpty)
                          Text(
                            'Add someone, or complete emergency contact in your Passport.',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.textSecondary,
                            ),
                          )
                        else
                          for (final c in contacts)
                            Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.person_pin_circle_outlined,
                                  color: AppColors.sos,
                                ),
                                title: Text(
                                  c.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  '${c.isPrimary ? 'Primary · ' : ''}'
                                  '${c.relation.isEmpty ? 'Contact' : c.relation}'
                                  '${c.phone.isEmpty ? '' : ' · ${c.phone}'}',
                                ),
                                trailing: Wrap(
                                  spacing: 0,
                                  children: [
                                    if (c.phone.isNotEmpty)
                                      IconButton(
                                        tooltip: 'Call',
                                        icon: const Icon(Icons.phone_outlined),
                                        onPressed: () =>
                                            EmergencyActions.call(c.phone),
                                      ),
                                    if (c.phone.isNotEmpty)
                                      IconButton(
                                        tooltip: 'SMS',
                                        icon: const Icon(Icons.sms_outlined),
                                        onPressed: () => EmergencyActions.sms(
                                          phones: [c.phone],
                                          body:
                                              'SOS from ${profile.displayName}. I need help.',
                                        ),
                                      ),
                                    IconButton(
                                      tooltip: 'Edit',
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () =>
                                          _editContact(existing: c),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete',
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () =>
                                          _emergency.deleteContact(c.id),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            ),
                        const SizedBox(height: 16),
                        Text(
                          'Nearby emergency services',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          origin.fromDevice
                              ? 'Sorted by your GPS.'
                              : 'Using last known / default location — enable GPS for true nearby.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        StreamBuilder<List<EmergencyResource>>(
                          stream: _emergency.watchResources(),
                          builder: (context, snap) {
                            return StreamBuilder<List<AccessiblePlace>>(
                              stream: _places.watchPlaces(),
                              builder: (context, placeSnap) {
                                final resources = _emergency.nearbyResources(
                                  snap.data ?? seedEmergencyResources,
                                  profile: profile,
                                  lat: origin.lat,
                                  lng: origin.lng,
                                );
                                final visibleResources = _resourceKind == 'all'
                                    ? resources
                                    : resources
                                          .where((r) => r.kind == _resourceKind)
                                          .toList();
                                final hospitals =
                                    (placeSnap.data ?? const [])
                                        .where(
                                          (p) =>
                                              p.category == 'hospital' ||
                                              p.category == 'hôpital',
                                        )
                                        .toList()
                                      ..sort(
                                        (a, b) => a
                                            .distanceKm(origin.lat, origin.lng)
                                            .compareTo(
                                              b.distanceKm(
                                                origin.lat,
                                                origin.lng,
                                              ),
                                            ),
                                      );
                                return Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 36,
                                      child: ListView(
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          for (final f in const [
                                            ('all', 'All'),
                                            ('hospital', 'Hospital'),
                                            ('pharmacy', 'Pharmacy'),
                                            ('police', 'Police'),
                                            ('shelter', 'Shelter'),
                                            ('relay', 'Relay'),
                                          ])
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              child: ChoiceChip(
                                                label: Text(f.$2),
                                                selected: _resourceKind == f.$1,
                                                onSelected: (_) => setState(
                                                  () => _resourceKind = f.$1,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (visibleResources.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'No ${_resourceKind == 'all' ? '' : _resourceKind} resources nearby.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    for (final r in visibleResources)
                                      Card(
                                        child: ListTile(
                                          title: Text(
                                            r.name,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${r.kind} · ${r.distanceLabel(origin.lat, origin.lng)}\n${r.summary}'
                                            '${r.stepFree ? ' · Step-free' : ''}',
                                          ),
                                          isThreeLine: true,
                                          trailing: Wrap(
                                            children: [
                                              IconButton(
                                                tooltip: 'Call',
                                                icon: const Icon(
                                                  Icons.phone_outlined,
                                                ),
                                                onPressed: () =>
                                                    EmergencyActions.call(
                                                      r.phone,
                                                    ),
                                              ),
                                              IconButton(
                                                tooltip: 'Map',
                                                icon: const Icon(
                                                  Icons.map_outlined,
                                                ),
                                                onPressed: () =>
                                                    EmergencyActions.maps(
                                                      lat: r.lat,
                                                      lng: r.lng,
                                                      label: r.name,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    if (hospitals.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Hospitals on the map',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      for (final p in hospitals.take(5))
                                        Card(
                                          child: ListTile(
                                            title: Text(p.name),
                                            subtitle: Text(
                                              '${p.distanceLabel(origin.lat, origin.lng)} · ${p.address}',
                                            ),
                                            trailing: IconButton(
                                              tooltip: 'Open in Maps',
                                              icon: const Icon(
                                                Icons.map_outlined,
                                              ),
                                              onPressed: () =>
                                                  EmergencyActions.maps(
                                                    lat: p.lat,
                                                    lng: p.lng,
                                                    label: p.name,
                                                  ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Recent SOS',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        StreamBuilder<List<SosAlert>>(
                          stream: _emergency.watchMySos(),
                          builder: (context, snap) {
                            final list = snap.data ?? const <SosAlert>[];
                            if (list.isEmpty) {
                              return Text(
                                'No SOS events yet.',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.textSecondary,
                                ),
                              );
                            }
                            return Column(
                              children: [
                                for (final a in list.take(8))
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      a.status.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        color: a.status == 'open'
                                            ? AppColors.sos
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${a.createdAt.toLocal()}'
                                      '${a.contactNames.isEmpty ? '' : '\nAlerted: ${a.contactNames.join(', ')}'}',
                                    ),
                                    isThreeLine: a.contactNames.isNotEmpty,
                                    trailing: Wrap(
                                      children: [
                                        IconButton(
                                          tooltip: 'Open in Maps',
                                          icon: const Icon(Icons.map_outlined),
                                          onPressed: () =>
                                              EmergencyActions.maps(
                                                lat: a.lat,
                                                lng: a.lng,
                                              ),
                                        ),
                                        if (a.status == 'open')
                                          TextButton(
                                            onPressed: () =>
                                                _emergency.cancelSos(a.id),
                                            child: const Text('Cancel'),
                                          ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
        );
      },
    );
  }
}

class _PassportEmergencyCard extends StatelessWidget {
  const _PassportEmergencyCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final allergies =
        (profile.healthcare['allergies'] as String?)?.trim() ?? '';
    final meds = (profile.healthcare['medications'] as String?)?.trim() ?? '';
    final notes =
        (profile.healthcare['emergencyNotes'] as String?)?.trim() ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Passport packet (sent with SOS)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              [
                if (profile.accessibilityProfiles.isNotEmpty)
                  'Needs: ${profile.accessibilityProfiles.join(', ')}',
                if (profile.mobilityAid.isNotEmpty)
                  'Mobility: ${profile.mobilityAid}',
                if (profile.communicationSummary != 'Not set')
                  'Communication: ${profile.communicationSummary}',
                'Blood: ${profile.bloodGroup}',
                if (allergies.isNotEmpty) 'Allergies: $allergies',
                if (meds.isNotEmpty) 'Medications: $meds',
                if (notes.isNotEmpty) 'Notes: $notes',
              ].join('\n'),
              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
