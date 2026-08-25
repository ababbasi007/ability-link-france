import 'package:flutter/material.dart';

import '../../models/care_appointment.dart';
import '../../models/rehab.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/healthcare_service.dart';
import '../../services/notification_service.dart';
import '../../services/providers_service.dart';
import '../../services/rehab_service.dart';
import '../ai/ai_assistant_screen.dart';
import '../healthcare/appointments_screen.dart';
import '../healthcare/session_room_screen.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../providers/providers_directory_screen.dart';
import 'exercise_library_screen.dart';
import 'rehab_tools_screens.dart';
import 'tele_rehab_hub.dart';

class TeleRehabScreen extends StatefulWidget {
  const TeleRehabScreen({super.key});

  @override
  State<TeleRehabScreen> createState() => _TeleRehabScreenState();
}

class _TeleRehabScreenState extends State<TeleRehabScreen> {
  final _care = HealthcareService();
  final _rehab = RehabService();
  final _auth = AuthService();

  // Held as a field so a rebuild reuses the listener instead of opening a
  // second one against the same collection.
  late final Stream<int> _unread = NotificationService().watchUnreadCount();

  static const _hubPlan = [
    RehabHubPlanItem(
      title: 'Lower Back Stretch',
      minutes: 10,
      done: true,
      image: 'assets/images/rehab/ex_seated_row.png',
    ),
    RehabHubPlanItem(
      title: 'Core Strengthening',
      minutes: 15,
      done: true,
      image: 'assets/images/rehab/ex_seated_row.png',
    ),
    RehabHubPlanItem(
      title: 'Balance Training',
      minutes: 10,
      done: true,
      image: 'assets/images/rehab/ex_leg_extensions.png',
    ),
    RehabHubPlanItem(
      title: 'Leg Mobility Exercise',
      minutes: 10,
      done: true,
      image: 'assets/images/rehab/ex_leg_extensions.png',
    ),
    RehabHubPlanItem(
      title: 'Breathing Exercise',
      minutes: 5,
      done: false,
      image: 'assets/images/rehab/ex_breathing.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    runInBackground(_care.ensureDemoAppointments(), 'seed appointments');
    runInBackground(
      _auth.getCurrentProfile().then(_rehab.ensureUserSeed),
      'seed rehab plan',
    );
    runInBackground(ProvidersService().ensureSeeded(), 'seed providers');
  }

  void _openTherapists({String title = 'Rehab therapists'}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProvidersDirectoryScreen(
          initialCategory: 'Rehabilitation',
          title: title,
        ),
      ),
    );
  }

  void _openChat(CareAppointment? a) {
    // Threads are per patient — a shared 'rehab-inbox' put every user's messages
    // to their therapist in one conversation.
    final me = AuthService().currentUser?.uid ?? '';
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TherapistChatScreen(
          threadId: a == null
              ? 'rehab-inbox-$me'
              : 'provider-${a.providerId}-$me',
          title: a?.providerName ?? 'Therapist',
        ),
      ),
    );
  }

  void _openSessions() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AppointmentsScreen(kind: 'rehab'),
      ),
    );
  }

  void _join(CareAppointment? a) {
    if (a == null) {
      _openTherapists();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionRoomScreen(appointment: a),
      ),
    );
  }

  void _push(Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<int>(
          stream: _unread,
          builder: (context, unreadSnap) {
            return StreamBuilder<UserProfile?>(
              stream: _auth.watchCurrentProfile(),
              builder: (context, profileSnap) {
                return StreamBuilder<List<CareAppointment>>(
                  stream: _care.watchAppointments(kind: 'rehab'),
                  builder: (context, snap) {
                    final upcoming = (snap.data ?? const <CareAppointment>[])
                        .where((a) => a.isUpcoming)
                        .toList();
                    final next = upcoming.isEmpty ? null : upcoming.first;
                    return StreamBuilder<List<RehabExercise>>(
                      stream: _rehab.watchExercises(),
                      builder: (context, exSnap) {
                        final exercises = exSnap.data ?? const <RehabExercise>[];
                        final unread = unreadSnap.data ?? 0;
                        final name = (profileSnap.data?.firstName.trim().isNotEmpty ??
                                false)
                            ? profileSnap.data!.firstName
                            : 'Alex';
                        return RehabHubView(
                          name: name,
                          unreadBadge: unread > 0
                              ? (unread > 9 ? '9+' : '$unread')
                              : '3',
                          therapistName:
                              next?.providerName ?? 'Dr. Sarah Johnson',
                          whenLabel: next?.whenLabel ?? 'Today, 10:00 AM',
                          durationMin: next?.durationMin ?? 30,
                          photoAsset: 'assets/images/rehab/therapist_sarah.png',
                          plan: _hubPlan,
                          onBack: () => Navigator.of(context).maybePop(),
                          onBell: () =>
                              _push(const NotificationsInboxScreen()),
                          onCalendar: _openSessions,
                          onVideo: () => _join(next),
                          onPlans: () =>
                              _push(const PersonalizedPlanScreen()),
                          onProgress: () =>
                              _push(const RehabProgressScreen()),
                          onHealth: () => _push(const RehabHealthScreen()),
                          onMessages: () => _openChat(next),
                          onLibrary: () =>
                              _push(const ExerciseLibraryScreen()),
                          onJoin: () => _join(next),
                          onReschedule: _openTherapists,
                          onMore: _openSessions,
                          onPlanItem: (i) {
                            final title = _hubPlan[i].title;
                            RehabExercise? match;
                            for (final e in exercises) {
                              if (e.title == title) {
                                match = e;
                                break;
                              }
                            }
                            if (match != null) {
                              _push(ExerciseDetailScreen(exercise: match));
                            } else {
                              _push(const PersonalizedPlanScreen());
                            }
                          },
                          onAskAi: () => _push(const AiAssistantScreen()),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
