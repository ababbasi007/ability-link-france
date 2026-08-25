import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_circle.dart';
import '../../services/care_circle_service.dart';
import '../../theme/app_colors.dart';
import '../privacy/passport_privacy_screen.dart';
import 'care_live_location_share_screen.dart';
import 'care_shared_places_screen.dart';
import 'care_shared_routes_screen.dart';

class CareCircleScreen extends StatefulWidget {
  const CareCircleScreen({super.key});

  @override
  State<CareCircleScreen> createState() => _CareCircleScreenState();
}

class _CareCircleScreenState extends State<CareCircleScreen> {
  final _care = CareCircleService();

  static const _permLabels = {
    'viewPassport': 'View shared Passport',
    'viewLocation': 'Live location',
    'manageTasks': 'Manage tasks',
    'meds': 'Medication reminders',
  };

  Future<void> _add() async {
    final name = TextEditingController();
    final relation = TextEditingController();
    final phone = TextEditingController();
    final bio = TextEditingController();
    var role = 'family';
    final perms = <String>{'viewPassport'};
    try {
      final ok = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModal) {
              return Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.viewInsetsOf(ctx).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Add to care circle',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
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
                        controller: relation,
                        decoration: const InputDecoration(
                          labelText: 'Relation / title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'family',
                            child: Text('Family / friend'),
                          ),
                          DropdownMenuItem(
                            value: 'professional',
                            child: Text('Professional caregiver'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setModal(() => role = v);
                        },
                      ),
                      if (role == 'professional') ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: bio,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Short profile / skills',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      for (final e in _permLabels.entries)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: perms.contains(e.key),
                          title: Text(
                            e.value,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onChanged: (v) {
                            setModal(() {
                              if (v == true) {
                                perms.add(e.key);
                              } else {
                                perms.remove(e.key);
                              }
                            });
                          },
                        ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
      if (ok != true || name.text.trim().isEmpty) return;
      await _care.addMember(
        name: name.text,
        relation: relation.text,
        permissions: perms.toList(),
        phone: phone.text,
        role: role,
        bio: bio.text,
        verified: role == 'professional',
        availableNow: role == 'professional',
      );
    } finally {
      name.dispose();
      relation.dispose();
      phone.dispose();
      bio.dispose();
    }
  }

  Future<void> _editPerms(CareMember member) async {
    final perms = {...member.permissions};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return AlertDialog(
              title: Text(member.name),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final e in _permLabels.entries)
                    CheckboxListTile(
                      value: perms.contains(e.key),
                      title: Text(e.value),
                      onChanged: (v) {
                        setModal(() {
                          if (v == true) {
                            perms.add(e.key);
                          } else {
                            perms.remove(e.key);
                          }
                        });
                      },
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok == true) {
      await _care.updatePermissions(member.id, perms.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Care circle',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Add care circle member',
            onPressed: _add,
            icon: const Icon(Icons.person_add_alt),
          ),
        ],
      ),
      body: StreamBuilder<List<CareMember>>(
        stream: _care.watchMembers(),
        builder: (context, snap) {
          final members = snap.data ?? const <CareMember>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Permissions control Passport, location, tasks, and meds for each person.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (members.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                for (final m in members)
                  Card(
                    child: ListTile(
                      onTap: () => _editPerms(m),
                      leading: CircleAvatar(
                        backgroundColor: Color(m.colorValue),
                        child: Text(
                          m.initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              m.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (m.verified) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        [
                          m.relation,
                          if (m.isProfessional) 'Professional caregiver',
                          if (m.phone.isNotEmpty) m.phone,
                          if (m.availableNow) 'Available now',
                          if (m.bio.isNotEmpty) m.bio,
                          m.permissions
                              .map((p) => _permLabels[p] ?? p)
                              .join(' · '),
                        ].join('\n'),
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.tune),
                    ),
                  ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PassportPrivacyScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Share Passport with circle'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CareSharedPlacesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.place_rounded),
                label: const Text('Shared saved places'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CareSharedRoutesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.route_rounded),
                label: const Text('Shared routes'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CareLiveLocationShareScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.share_location),
                label: const Text('Share live location'),
              ),
            ],
          );
        },
      ),
    );
  }
}
