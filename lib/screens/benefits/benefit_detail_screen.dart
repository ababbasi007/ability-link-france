import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/benefit_scheme.dart';
import '../../services/benefits_service.dart';
import '../../theme/app_colors.dart';

class BenefitDetailScreen extends StatefulWidget {
  const BenefitDetailScreen({
    super.key,
    required this.scheme,
    this.matchScore = 0,
  });

  final BenefitScheme scheme;
  final int matchScore;

  @override
  State<BenefitDetailScreen> createState() => _BenefitDetailScreenState();
}

class _BenefitDetailScreenState extends State<BenefitDetailScreen> {
  final _benefits = BenefitsService();
  bool _busy = false;

  BenefitScheme get s => widget.scheme;

  Future<void> _startApp() async {
    setState(() => _busy = true);
    try {
      await _benefits.startApplication(scheme: s, setReminder: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Application saved as draft. Reminder scheduled in Notifications.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _dial(String phone) async {
    final cleaned = phone.replaceAll(' ', '');
    await launchUrl(Uri.parse('tel:$cleaned'));
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
          s.categoryLabel,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            s.name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${s.country} · ${s.agency}',
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.matchScore > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Passport match ${widget.matchScore}%',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(s.summary, style: GoogleFonts.plusJakartaSans(height: 1.4)),
          const SizedBox(height: 10),
          Text(
            'Who for: ${s.whoFor}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (s.deadlineLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.event_outlined,
              title: 'Deadline / renewal',
              body: s.deadlineLabel,
            ),
          ],
          if (s.eligibilityHints.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Eligibility notes',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final h in s.eligibilityHints)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $h',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            'Application steps',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < s.steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${i + 1}. ${s.steps[i]}',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
            ),
          if (s.documents.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Required documents',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            for (final d in s.documents)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $d',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
          ],
          const SizedBox(height: 16),
          Text(
            'Contacts',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (s.phone.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_outlined),
              title: Text(s.phone),
              subtitle: const Text('Phone'),
              onTap: () => _dial(s.phone),
            ),
          if (s.email.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined),
              title: Text(s.email),
              subtitle: const Text('Email'),
              onTap: () => _mail(s.email),
            ),
          if (s.officeHint.isNotEmpty)
            _InfoTile(
              icon: Icons.location_city_outlined,
              title: 'Where to go',
              body: s.officeHint,
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _busy ? null : _startApp,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check),
            label: const Text('Track application + set reminder'),
          ),
          if (s.url.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _launch(s.url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Official page'),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Always confirm eligibility and deadlines on the official government site.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  body,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
