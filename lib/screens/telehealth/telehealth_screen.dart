import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/care_appointment.dart';
import '../../models/service_provider.dart';
import '../../models/telehealth.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/background_task.dart';
import '../../services/healthcare_service.dart';
import '../../services/notification_service.dart';
import '../../services/providers_service.dart';
import '../../services/telehealth_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/live_upcoming_card.dart';
import '../emergency/emergency_screen.dart';
import '../healthcare/appointments_screen.dart';
import '../healthcare/session_room_screen.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../providers/provider_profile_screen.dart';
import '../providers/providers_directory_screen.dart';
import '../tele_rehab/rehab_tools_screens.dart';
import 'telehealth_records_screens.dart';

class TelehealthScreen extends StatefulWidget {
  const TelehealthScreen({super.key});

  @override
  State<TelehealthScreen> createState() => _TelehealthScreenState();
}

class _TelehealthScreenState extends State<TelehealthScreen> {
  final _providers = ProvidersService();
  final _care = HealthcareService();
  final _auth = AuthService();
  final _tele = TelehealthService();

  @override
  void initState() {
    super.initState();
    runInBackground(_providers.ensureSeeded(), 'seed providers');
    runInBackground(_care.ensureDemoAppointments(), 'seed appointments');
    runInBackground(
      _auth.getCurrentProfile().then(_tele.ensureUserSeed),
      'seed telehealth records',
    );
  }

  void _openDirectory({String category = 'All', String specialty = ''}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProvidersDirectoryScreen(
          initialCategory: category,
          initialSpecialty: specialty,
          title: specialty.isNotEmpty
              ? specialty
              : category == 'All'
              ? 'Find Providers'
              : category,
        ),
      ),
    );
  }

  void _openAppointments() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AppointmentsScreen()));
  }

  void _join(CareAppointment a) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SessionRoomScreen(appointment: a),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const _Header(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  _HeroCard(
                    onBook: () => _openDirectory(category: 'Healthcare'),
                  ),
                  const SizedBox(height: 18),
                  _ServiceCategories(
                    onTap: (label) {
                      switch (label) {
                        case 'Instant Consult':
                          InstantConsultSheet.show(context);
                        case 'Book Appointment':
                          _openDirectory(category: 'Healthcare');
                        case 'Find Specialists':
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const TelehealthSpecialtiesScreen(),
                            ),
                          );
                        case 'Health Records':
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const MedicalHistoryScreen(),
                            ),
                          );
                        case 'Health Check':
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const HealthDataScreen(),
                            ),
                          );
                        default:
                          _openDirectory();
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<List<CareAppointment>>(
                    stream: _care.watchAppointments(),
                    builder: (context, snap) {
                      final upcoming = (snap.data ?? const <CareAppointment>[])
                          .where((a) => a.isUpcoming && a.kind != 'rehab')
                          .toList();
                      if (upcoming.isEmpty) {
                        return LiveUpcomingCard(
                          appointment: CareAppointment(
                            id: '',
                            uid: '',
                            providerId: 'dr-sara-ahmed',
                            providerName: 'Book a doctor',
                            specialty: 'Tap View All to schedule',
                            kind: 'telehealth',
                            mode: 'video',
                            startAt: DateTime.now().add(
                              const Duration(days: 1),
                            ),
                            durationMin: 30,
                            status: 'booked',
                          ),
                          onJoin: _openAppointments,
                          onViewAll: _openAppointments,
                        );
                      }
                      return LiveUpcomingCard(
                        appointment: upcoming.first,
                        onJoin: () => _join(upcoming.first),
                        onViewAll: _openAppointments,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _LiveRecommendedDoctors(
                    onViewAll: () => _openDirectory(category: 'Healthcare'),
                  ),
                  const SizedBox(height: 16),
                  const _SupportBanner(),
                  const SizedBox(height: 20),
                  const _LiveHealthSummary(),
                  const SizedBox(height: 20),
                  _QuickActions(onBrowse: () => _openDirectory()),
                  const SizedBox(height: 16),
                  _EmergencyBanner(
                    onOpen: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EmergencyScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1E1B4B),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'Telehealth',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2E2A5E),
                  ),
                ),
                Text(
                  'Consult. Care. Connect.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<int>(
            stream: NotificationService().watchUnreadCount(),
            builder: (context, snap) {
              final n = snap.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    tooltip: 'Notifications',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsInboxScreen(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  if (n > 0)
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 15,
                        height: 15,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.badge,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          n > 9 ? '9+' : '$n',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            tooltip: 'Chat with doctor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => TherapistChatScreen(
                    threadId:
                        'telehealth-inbox-${AuthService().currentUser?.uid ?? ''}',
                    title: 'Doctor chat',
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroCard extends StatefulWidget {
  const _HeroCard({required this.onBook});

  final VoidCallback onBook;

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard> {
  // The card takes a callback so it can't be const, meaning every parent
  // rebuild produced a fresh profile listener. The state object outlives those
  // rebuilds; the stream now does too.
  late final Stream<UserProfile?> _profile = AuthService()
      .watchCurrentProfile();

  String _greeting(String name) {
    final h = DateTime.now().hour;
    final part = h < 12
        ? 'Good Morning'
        : h < 17
        ? 'Good Afternoon'
        : 'Good Evening';
    return '$part, $name';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _profile,
      builder: (context, snap) {
        final name = snap.data?.firstName ?? 'there';
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6C63FF), Color(0xFF5B52E8), Color(0xFF4F46C8)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting(name)} 👋',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your health, our priority.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        onTap: widget.onBook,
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.calendar_month_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Book Appointment',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  Positioned(
                    right: -4,
                    bottom: -6,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => InstantConsultSheet.show(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 110,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Talk to a Doctor',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E1B4B),
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  children: const [
                                    TextSpan(text: 'Consult online in '),
                                    TextSpan(
                                      text: '5 min',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1E1B4B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Available',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF22C55E),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Service categories (5 visible) ──────────────────────────────────────────

class _ServiceCategories extends StatelessWidget {
  const _ServiceCategories({required this.onTap});

  final ValueChanged<String> onTap;

  static const _items = [
    (
      Icons.videocam_rounded,
      'Instant Consult',
      'Talk to a doctor now',
      Color(0xFF6C63FF),
      Color(0xFFEEF0FF),
    ),
    (
      Icons.calendar_month_rounded,
      'Book Appointment',
      'Schedule with doctors',
      Color(0xFF22C55E),
      Color(0xFFE8F8EF),
    ),
    (
      Icons.medical_services_rounded,
      'Find Specialists',
      'Browse by specialty',
      Color(0xFF3B82F6),
      Color(0xFFE8F1FF),
    ),
    (
      Icons.folder_shared_rounded,
      'Health Records',
      'View your medical history',
      Color(0xFFF97316),
      Color(0xFFFFF1E8),
    ),
    (
      Icons.favorite_rounded,
      'Health Check',
      'Assess your symptoms',
      Color(0xFFEC4899),
      Color(0xFFFCE7F3),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: InkWell(
                onTap: () => onTap(_items[i].$2),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _items[i].$5,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_items[i].$1, color: _items[i].$4, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _items[i].$2,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E1B4B),
                        height: 1.15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _items[i].$3,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8,
                        color: const Color(0xFF6B7280),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Recommended doctors (live) ──────────────────────────────────────────────

class _LiveRecommendedDoctors extends StatelessWidget {
  const _LiveRecommendedDoctors({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final service = ProvidersService();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recommended for You',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View All',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 210,
          child: StreamBuilder<List<ServiceProvider>>(
            stream: service.watchProviders(),
            builder: (context, snap) {
              final all = snap.data ?? const <ServiceProvider>[];
              final doctors = service
                  .filter(all, category: 'Healthcare')
                  .take(6)
                  .toList();
              if (doctors.isEmpty) {
                return Center(
                  child: Text(
                    snap.connectionState == ConnectionState.waiting
                        ? 'Loading providers…'
                        : 'No providers yet',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: doctors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final d = doctors[i];
                  return SizedBox(
                    width: 140,
                    child: _LiveDoctorCard(
                      provider: d,
                      onBook: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ProviderProfileScreen(
                              providerId: d.id,
                              provider: d,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LiveDoctorCard extends StatelessWidget {
  const _LiveDoctorCard({required this.provider, required this.onBook});

  final ServiceProvider provider;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEEF0FF),
            backgroundImage: provider.photoUrl.isEmpty
                ? null
                : NetworkImage(provider.photoUrl),
            onBackgroundImageError: provider.photoUrl.isEmpty
                ? null
                : (_, _) {},
            child: provider.photoUrl.isEmpty
                ? const Icon(Icons.person, color: AppColors.primary, size: 26)
                : null,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  provider.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (provider.verified) ...[
                const SizedBox(width: 2),
                const Icon(
                  Icons.verified_rounded,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
          Text(
            provider.specialty,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 12,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 2),
              Text(
                provider.rating.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
            ],
          ),
          Text(
            '${provider.priceLabel} / Consult',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: const Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onBook,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Book Now',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 24/7 Support ────────────────────────────────────────────────────────────

class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF0FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.health_and_safety,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '24/7 Health Support',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1B4B),
                  ),
                ),
                Text(
                  'Our doctors are available round the clock for your urgent health concerns.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => InstantConsultSheet.show(context),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.headset_mic_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Get Help Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Health summary (4 visible) ──────────────────────────────────────────────

class _LiveHealthSummary extends StatelessWidget {
  const _LiveHealthSummary();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HealthVital>>(
      stream: TelehealthService().watchVitals(),
      builder: (context, snap) {
        final v = (snap.data ?? const <HealthVital>[]).isEmpty
            ? null
            : snap.data!.first;
        final stats = [
          (
            Icons.favorite_rounded,
            'Heart Rate',
            v?.hrLabel ?? '—',
            v?.hrStatus ?? 'Log',
            const Color(0xFFEC4899),
            const Color(0xFFFCE7F3),
          ),
          (
            Icons.monitor_heart_outlined,
            'Blood Pressure',
            v?.bpLabel ?? '—',
            v?.bpStatus ?? 'Log',
            const Color(0xFF3B82F6),
            const Color(0xFFE8F1FF),
          ),
          (
            Icons.monitor_weight_outlined,
            'Weight',
            v?.weightLabel ?? '—',
            v?.weightStatus ?? 'Log',
            const Color(0xFF22C55E),
            const Color(0xFFE8F8EF),
          ),
          (
            Icons.bedtime_rounded,
            'Sleep',
            v?.sleepLabel ?? '—',
            v?.sleepStatus ?? 'Log',
            const Color(0xFF6C63FF),
            const Color(0xFFEEF0FF),
          ),
        ];
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your Health Summary',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const HealthDataScreen(),
                    ),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const HealthDataScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: stats[i].$6,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  stats[i].$1,
                                  color: stats[i].$5,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                stats[i].$2,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  color: const Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                stats[i].$3,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E1B4B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                stats[i].$4,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: stats[i].$5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Quick Actions (5 visible) ───────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onBrowse});

  final VoidCallback onBrowse;

  static const _actions = [
    (
      Icons.people_alt_rounded,
      'Browse\nProviders',
      Color(0xFF6C63FF),
      Color(0xFFEEF0FF),
    ),
    (
      Icons.medication_rounded,
      'Prescriptions',
      Color(0xFF3B82F6),
      Color(0xFFE8F1FF),
    ),
    (Icons.science_rounded, 'Lab Tests', Color(0xFF14B8A6), Color(0xFFE6FAF7)),
    (
      Icons.alarm_rounded,
      'Medicines\nReminder',
      Color(0xFFF97316),
      Color(0xFFFFF1E8),
    ),
    (
      Icons.verified_user_rounded,
      'Insurance\nDetails',
      Color(0xFF22C55E),
      Color(0xFFE8F8EF),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      switch (i) {
                        case 0:
                          onBrowse();
                        case 1:
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const PrescriptionsScreen(),
                            ),
                          );
                        case 2:
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const MedicalDocumentsScreen(kind: 'lab'),
                            ),
                          );
                        case 3:
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const MedRemindersScreen(),
                            ),
                          );
                        case 4:
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const InsuranceDetailsScreen(),
                            ),
                          );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _actions[i].$4,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              _actions[i].$1,
                              color: _actions[i].$3,
                              size: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _actions[i].$2,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1B4B),
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Emergency ───────────────────────────────────────────────────────────────

class _EmergencyBanner extends StatelessWidget {
  const _EmergencyBanner({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD6DE)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              'SOS',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical Emergency?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFE11D48),
                  ),
                ),
                Text(
                  'Tap to call your emergency contacts.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone, size: 14, color: Color(0xFFE11D48)),
                    const SizedBox(width: 4),
                    Text(
                      'Call Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
