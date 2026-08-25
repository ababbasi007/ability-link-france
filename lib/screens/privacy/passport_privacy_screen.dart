import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/passport_share.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/passport_share_service.dart';
import '../../theme/app_colors.dart';
import 'passport_view_screen.dart';

class PassportPrivacyScreen extends StatefulWidget {
  const PassportPrivacyScreen({super.key});

  @override
  State<PassportPrivacyScreen> createState() => _PassportPrivacyScreenState();
}

class _PassportPrivacyScreenState extends State<PassportPrivacyScreen> {
  final _auth = AuthService();
  final _shares = PassportShareService();
  final _selected = <String>{'identity', 'accessibility', 'communication'};
  bool _consent = false;
  int _days = 7;
  bool _busy = false;

  Future<void> _create(UserProfile profile) async {
    setState(() => _busy = true);
    try {
      final share = await _shares.createShare(
        profile: profile,
        fields: _selected,
        consent: _consent,
        lifetime: Duration(days: _days),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Share link ready'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: share.shareLink,
                size: 180,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 8),
              SelectableText(
                share.shareCode,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              Text(
                'Valid $_days day(s). Anyone with the code can see only the fields you chose.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: share.shareCode));
                Navigator.pop(ctx);
              },
              child: const Text('Copy code'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(UserProfile profile) async {
    final json = _shares.exportJson(profile);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Passport export copied as JSON.')),
    );
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account & Passport?'),
        content: const Text(
          'This records a deletion request and tries to remove your login. '
          'Recent sign-in may be required. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _shares.requestAccountDeletion();
    } catch (e) {
      if (!mounted) return;
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
          'Passport sharing & privacy',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const PassportViewScreen(),
                ),
              );
            },
            child: const Text('Open a code'),
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _auth.watchCurrentProfile(),
        builder: (context, snap) {
          final profile = snap.data;
          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                'Share only the fields you consent to. You can revoke a link at any time. Views are logged.',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Fields',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              for (final f in PassportShareService.fieldOptions)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _selected.contains(f.$1),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(f.$1);
                      } else {
                        _selected.remove(f.$1);
                      }
                    });
                  },
                  title: Text(
                    f.$2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                'Link lifetime',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              Wrap(
                spacing: 8,
                children: [
                  for (final d in [1, 7, 30])
                    ChoiceChip(
                      label: Text('$d day${d == 1 ? '' : 's'}'),
                      selected: _days == d,
                      onSelected: (_) => setState(() => _days = d),
                    ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                onChanged: (v) => setState(() => _consent = v),
                title: Text(
                  'I consent to share the selected fields',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
              ElevatedButton(
                onPressed: _busy ? null : () => _create(profile),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Create QR & share code'),
              ),
              const SizedBox(height: 20),
              Text(
                'Active & past links',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              StreamBuilder<List<PassportShare>>(
                stream: _shares.watchMyShares(),
                builder: (context, shareSnap) {
                  final list = shareSnap.data ?? const <PassportShare>[];
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No share links yet.',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final s in list)
                        Card(
                          child: ListTile(
                            title: Text(
                              s.shareCode,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${s.status}${s.isActive ? '' : ' (inactive)'} · '
                              '${s.fields.join(', ')} · ${s.accessCount} view(s)',
                            ),
                            trailing: s.status == 'active'
                                ? TextButton(
                                    onPressed: () => _shares.revoke(s.id),
                                    child: const Text('Revoke'),
                                  )
                                : null,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Access history',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
              ),
              StreamBuilder<List<PassportAccessEvent>>(
                stream: _shares.watchMyAccessLog(),
                builder: (context, logSnap) {
                  final logs = logSnap.data ?? const <PassportAccessEvent>[];
                  if (logs.isEmpty) {
                    return Text(
                      'No access events yet.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final e in logs.take(20))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            '${e.action} · ${e.shareId.toUpperCase()}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${e.viewerName} · ${e.createdAt.toLocal()}',
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _export(profile),
                child: const Text('Export my Passport (JSON)'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _delete,
                child: Text(
                  'Delete account & Passport data',
                  style: GoogleFonts.plusJakartaSans(color: AppColors.sos),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
