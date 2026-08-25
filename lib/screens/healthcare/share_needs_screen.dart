import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/health_org.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/health_org_service.dart';
import '../../theme/app_colors.dart';

class ShareNeedsScreen extends StatefulWidget {
  const ShareNeedsScreen({super.key});

  @override
  State<ShareNeedsScreen> createState() => _ShareNeedsScreenState();
}

class _ShareNeedsScreenState extends State<ShareNeedsScreen> {
  final _orgs = HealthOrgService();
  final _auth = AuthService();
  HealthOrg? _picked;
  String? _pickedId;
  bool _busy = false;

  Future<void> _share(UserProfile profile) async {
    final org = _picked;
    if (org == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose a clinic')));
      return;
    }
    setState(() => _busy = true);
    try {
      await _orgs.shareNeeds(org: org, profile: profile);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Shared with ${org.name}')));
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Share needs with a clinic',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<UserProfile?>(
        stream: _auth.watchCurrentProfile(),
        builder: (context, profileSnap) {
          final profile = profileSnap.data;
          return StreamBuilder<List<HealthOrg>>(
            stream: _orgs.watchOrgs(),
            builder: (context, orgSnap) {
              final orgs = orgSnap.data ?? const <HealthOrg>[];
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Only accessibility tags from your Passport are shared — not your full profile.',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile == null || profile.accessibilityProfiles.isEmpty
                        ? 'No Passport needs tagged yet.'
                        : 'Sharing: ${profile.accessibilityProfiles.join(', ')}',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (orgs.isEmpty)
                    Text(
                      'No clinics registered yet. A clinic can open Clinic dashboard to sign up.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    for (final o in orgs)
                      RadioListTile<String>(
                        value: o.id,
                        groupValue: _pickedId,
                        onChanged: (v) {
                          setState(() {
                            _pickedId = v;
                            _picked = o;
                          });
                        },
                        title: Text(o.name),
                        subtitle: Text('${o.kindLabel} · ${o.city}'),
                      ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _busy || profile == null
                        ? null
                        : () => _share(profile),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(_busy ? 'Sharing…' : 'I consent to share'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
