import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_notification.dart';
import '../../services/background_task.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';

class NotificationsInboxScreen extends StatefulWidget {
  const NotificationsInboxScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<NotificationsInboxScreen> createState() =>
      _NotificationsInboxScreenState();
}

class _NotificationsInboxScreenState extends State<NotificationsInboxScreen> {
  final _notes = NotificationService();

  @override
  void initState() {
    super.initState();
    runInBackground(_notes.ensureWelcome(), 'welcome notification');
    runInBackground(_notes.syncDueReminders(), 'reminder sync');
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab.clamp(0, 1),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            'Notifications',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Inbox'),
              Tab(text: 'Preferences'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InboxTab(notes: _notes),
            _PrefsTab(notes: _notes),
          ],
        ),
      ),
    );
  }
}

class _InboxTab extends StatefulWidget {
  const _InboxTab({required this.notes});

  final NotificationService notes;

  @override
  State<_InboxTab> createState() => _InboxTabState();
}

class _InboxTabState extends State<_InboxTab> {
  String _filter = 'all';

  static const _filters = <(String, String)>[
    ('all', 'All'),
    ('booking', 'Bookings'),
    ('payment', 'Payments'),
    ('caregiver', 'Caregiver'),
    ('telehealth', 'Telehealth'),
    ('rehab', 'Rehab'),
    ('exercise', 'Exercise'),
    ('benefit_reminder', 'Benefits'),
    ('nearby', 'Nearby'),
    ('message', 'Messages'),
    ('sos', 'Emergency'),
  ];

  bool _matches(AppNotification n) {
    return switch (_filter) {
      'all' => true,
      'booking' => n.type == 'booking' || n.type == 'appointment',
      'telehealth' =>
        n.type == 'telehealth' ||
            n.type == 'prescription' ||
            n.type == 'reminder',
      _ => n.type == _filter,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: widget.notes.watchMine(),
      builder: (context, snap) {
        final all = snap.data ?? const <AppNotification>[];
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = all.where(_matches).toList();
        return Column(
          children: [
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                children: [
                  for (final f in _filters)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.$2),
                        selected: _filter == f.$1,
                        onSelected: (_) => setState(() => _filter = f.$1),
                      ),
                    ),
                ],
              ),
            ),
            if (list.any((n) => !n.read))
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => widget.notes.markAllRead(list),
                  child: const Text('Mark all read'),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => widget.notes.syncDueReminders(),
                child: list.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 56),
                          Image.asset(
                            'assets/images/empty_states/empty_notifications.png',
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No alerts yet. Book a visit, pay an invoice, or pull to refresh due reminders.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final n = list[i];
                          return Card(
                            color: n.read
                                ? Colors.white
                                : AppColors.primaryLight,
                            child: ListTile(
                              onTap: () => widget.notes.markRead(n.id),
                              title: Text(
                                n.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${n.typeLabel} · ${n.body}\n${n.channels.join(' · ')}',
                              ),
                              isThreeLine: true,
                              trailing: n.read
                                  ? null
                                  : const Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: AppColors.primary,
                                    ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PrefsTab extends StatelessWidget {
  const _PrefsTab({required this.notes});

  final NotificationService notes;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<NotificationPrefs>(
      stream: notes.watchPrefs(),
      builder: (context, prefSnap) {
        final prefs = prefSnap.data ?? const NotificationPrefs();
        return StreamBuilder<List<SavedSearch>>(
          stream: notes.watchSavedSearches(),
          builder: (context, searchSnap) {
            final searches = searchSnap.data ?? const <SavedSearch>[];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Text(
                  'Channels',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'In-app and push are live. Turning push on asks the system for permission and registers this device. Email and SMS prefs are stored for later gateways.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                SwitchListTile(
                  title: const Text('In-app'),
                  value: prefs.inApp,
                  onChanged: (v) => notes.savePrefs(prefs.copyWith(inApp: v)),
                ),
                SwitchListTile(
                  title: const Text('Push'),
                  value: prefs.push,
                  onChanged: (v) => notes.savePrefs(prefs.copyWith(push: v)),
                ),
                SwitchListTile(
                  title: const Text('Email'),
                  value: prefs.email,
                  onChanged: (v) => notes.savePrefs(prefs.copyWith(email: v)),
                ),
                SwitchListTile(
                  title: const Text('SMS'),
                  value: prefs.sms,
                  onChanged: (v) => notes.savePrefs(prefs.copyWith(sms: v)),
                ),
                const Divider(),
                Text(
                  'Alert types',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SwitchListTile(
                  title: const Text('Booking & appointment reminders'),
                  value: prefs.bookings,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(bookings: v)),
                ),
                SwitchListTile(
                  title: const Text('Payment notifications'),
                  value: prefs.payments,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(payments: v)),
                ),
                SwitchListTile(
                  title: const Text('Caregiver alerts'),
                  value: prefs.caregiver,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(caregiver: v)),
                ),
                SwitchListTile(
                  title: const Text('Telehealth & medication reminders'),
                  value: prefs.telehealth,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(telehealth: v)),
                ),
                SwitchListTile(
                  title: const Text('Rehab reminders'),
                  value: prefs.rehab,
                  onChanged: (v) => notes.savePrefs(prefs.copyWith(rehab: v)),
                ),
                SwitchListTile(
                  title: const Text('Exercise reminders'),
                  value: prefs.exercise,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(exercise: v)),
                ),
                SwitchListTile(
                  title: const Text('Benefit updates'),
                  value: prefs.benefits,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(benefits: v)),
                ),
                SwitchListTile(
                  title: const Text('Nearby accessible places'),
                  value: prefs.nearby,
                  onChanged: (v) => notes.savePrefs(prefs.copyWith(nearby: v)),
                ),
                SwitchListTile(
                  title: const Text('Messages'),
                  value: prefs.messages,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(messages: v)),
                ),
                SwitchListTile(
                  title: const Text('Emergency / SOS'),
                  value: prefs.emergency,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(emergency: v)),
                ),
                SwitchListTile(
                  title: const Text('Barrier alerts'),
                  value: prefs.barriers,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(barriers: v)),
                ),
                SwitchListTile(
                  title: const Text('Saved-search alerts'),
                  value: prefs.savedSearch,
                  onChanged: (v) =>
                      notes.savePrefs(prefs.copyWith(savedSearch: v)),
                ),
                const Divider(),
                Text(
                  'Saved searches',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (searches.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Save a search from Search to get match alerts.',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  for (final s in searches)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.label),
                      trailing: IconButton(
                        tooltip: 'Delete saved search',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => notes.deleteSavedSearch(s.id),
                      ),
                    ),
              ],
            );
          },
        );
      },
    );
  }
}
