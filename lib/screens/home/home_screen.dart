import '../../services/background_task.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/home_header.dart';
import 'widgets/home_hero.dart';
import 'widgets/home_primary_actions.dart';
import 'widgets/home_passport_banner.dart';
import 'widgets/recommended_for_you.dart';
import 'widgets/service_grid.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/healthcare_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/ux_scope.dart';
import '../../theme/app_colors.dart';
import '../providers/provider_portal_screen.dart';
import '../healthcare/health_org_dashboard_screen.dart';
import '../accessibility/accessibility_ux_screen.dart';
import '../analytics/impact_hub_screen.dart';
import '../integrations/integrations_hub_screen.dart';
import '../expansion/expansion_hub_screen.dart';
import '../trust/trust_hub_screen.dart';
import '../audit/audit_hub_screen.dart';
import '../admin/admin_console_screen.dart';
import '../billing/billing_screen.dart';
import '../main_shell.dart';
import '../assistance/assistance_marketplace_screen.dart';
import '../map/accessibility_map_screen.dart';
import '../indoor/indoor_map_screen.dart';
import '../tele_rehab/tele_rehab_screen.dart';
import '../ai/ai_assistant_screen.dart';
import '../caregiver/caregiver_hub_screen.dart';
import '../emergency/emergency_screen.dart';
import '../education/education_hub_screen.dart';
import '../healthcare/healthcare_hub_screen.dart';
import '../benefits/benefits_hub_screen.dart';
import '../jobs/jobs_board_screen.dart';
import '../jobs/employer_portal_screen.dart';
import '../notifications/notifications_inbox_screen.dart';
import '../providers/providers_directory_screen.dart';
import '../profile/profile_screen.dart';
import '../privacy/passport_privacy_screen.dart';
import '../search/search_screen.dart';
import '../transport/transport_hub_screen.dart';
import '../travel/travel_hub_screen.dart';
import '../community/community_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _auth = AuthService();
  final _care = HealthcareService();
  final _notes = NotificationService();

  @override
  void initState() {
    super.initState();
    runInBackground(_care.ensureDemoAppointments(), 'seed appointments');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSearch({String query = ''}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchScreen(initialQuery: query),
      ),
    );
  }

  void _openProfile() {
    final shell = context.findAncestorStateOfType<MainShellState>();
    if (shell != null) {
      shell.openProfileTab();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProfileScreen(showBack: true),
      ),
    );
  }

  void _openAccessibilityMap() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AccessibilityMapScreen()),
    );
  }

  void _openTeleRehab() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const TeleRehabScreen()),
    );
  }

  void _openAiAssistant([String? prompt]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AiAssistantScreen(initialPrompt: prompt),
      ),
    );
  }

  void _openCaregiverHub() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CaregiverHubScreen()),
    );
  }

  Future<void> _openEmergency() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const EmergencyScreen()),
    );
  }

  void _openMessages() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CommunityHubScreen()),
    );
  }

  void _onServiceTap(String label) {
    switch (label) {
      case 'Ability Map':
      case 'Accessibility Map':
        _openAccessibilityMap();
        return;
      case 'Indoor':
      case 'Indoor Navigation':
      case 'Indoor Map':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const IndoorMapScreen()),
        );
        return;
      case 'Tele Rehab':
      case 'Tele-Rehab':
      case 'Tele-Rehabilitation':
        _openTeleRehab();
        return;
      case 'Tele Health':
      case 'Telehealth':
      case 'Healthcare':
      case 'Healthcare & Rehab':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HealthcareHubScreen()),
        );
        return;
      case 'Clinic dashboard':
      case 'Healthcare org':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const HealthOrgDashboardScreen(),
          ),
        );
        return;
      case 'Admin':
      case 'Admin console':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AdminConsoleScreen()),
        );
        return;
      case 'Impact':
      case 'Impact & analytics':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ImpactHubScreen()),
        );
        return;
      case 'Integrations':
      case 'Integrations & APIs':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const IntegrationsHubScreen(),
          ),
        );
        return;
      case 'Global':
      case 'Global expansion':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ExpansionHubScreen()),
        );
        return;
      case 'Trust':
      case 'Trust & safety':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TrustHubScreen()),
        );
        return;
      case 'Accessibility Audit':
      case 'Audit':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AuditHubScreen()),
        );
        return;
      case 'Billing':
      case 'Billing & plans':
      case 'Payments':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BillingScreen()),
        );
        return;
      case 'Providers':
      case 'Find Providers':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const ProvidersDirectoryScreen(),
          ),
        );
        return;
      case 'Provider portal':
      case 'Provider Portal':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProviderPortalScreen()),
        );
        return;
      case 'AI Assistant':
      case 'AI Accessibility Assistant':
        _openAiAssistant();
        return;
      case 'Caregiver':
      case 'Caregiver Hub':
        _openCaregiverHub();
        return;
      case 'Get Assistance':
      case 'Services':
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const AssistanceMarketplaceScreen(),
          ),
        );
        return;
      case 'Assistive Tech':
      case 'Assistive Technology':
      case 'Rights & Legal':
      case 'Rights and Legal':
      case 'Rights':
      case 'Government Benefits':
      case 'Benefits':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const BenefitsHubScreen()),
        );
        return;
      case 'More':
        _scaffoldKey.currentState?.openDrawer();
        return;
      case 'Inclusive Jobs':
      case 'Jobs':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const JobsBoardScreen()),
        );
        return;
      case 'Employer platform':
      case 'Employer portal':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EmployerPortalScreen()),
        );
        return;
      case 'Accessible Education':
      case 'Education':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EducationHubScreen()),
        );
        return;
      case 'Transport':
      case 'Transport & mobility':
      case 'Accessible Transport':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TransportHubScreen()),
        );
        return;
      case 'Accessible Tourism':
      case 'Tourism':
      case 'Travel':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const TravelHubScreen()),
        );
        return;
      case 'Community':
        _openMessages();
        return;
      case 'Emergency SOS':
      case 'SOS':
        _openEmergency();
        return;
      default:
        _toast('$label — coming soon');
    }
  }

  void _openPassport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PassportPrivacyScreen()),
    );
  }

  void _openSupport() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AssistanceMarketplaceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserProfile?>(
      stream: _auth.watchCurrentProfile(),
      builder: (context, profileSnap) {
        final city = profileSnap.data?.city;
        final locationLabel = (city != null &&
                city.isNotEmpty &&
                city != 'Location not set')
            ? city
            : 'Abbottabad, Pakistan';
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Ability Link',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connecting Abilities, Empowering Lives',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Divider(height: 32),
                  ListTile(
                    leading: const Icon(
                      Icons.map_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Accessibility Map'),
                    onTap: () {
                      Navigator.pop(context);
                      _openAccessibilityMap();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.layers_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Indoor Navigation'),
                    subtitle: const Text('Multi-floor maps & room routes'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const IndoorMapScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.groups_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Caregiver Hub'),
                    onTap: () {
                      Navigator.pop(context);
                      _openCaregiverHub();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.medical_services_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Find Providers'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProvidersDirectoryScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.storefront_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Provider portal'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProviderPortalScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.local_hospital_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Healthcare & Rehab'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HealthcareHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.domain_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Clinic dashboard'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const HealthOrgDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.work_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Inclusive Jobs'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const JobsBoardScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.business_center_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Employer platform'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EmployerPortalScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Accessible Education'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EducationHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.directions_subway_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Transport & mobility'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TransportHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.flight_takeoff_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text('Accessible Tourism'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TravelHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.forum_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Community'),
                    onTap: () {
                      Navigator.pop(context);
                      _openMessages();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.sos_rounded, color: AppColors.sos),
                    title: const Text('Emergency SOS'),
                    onTap: () {
                      Navigator.pop(context);
                      _openEmergency();
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Admin console'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdminConsoleScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.insights_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Impact & analytics'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ImpactHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.hub_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Integrations & APIs'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const IntegrationsHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.public_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Global expansion'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ExpansionHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.shield_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Trust & safety'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TrustHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.fact_check_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Accessibility Audit'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AuditHubScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.payments_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Billing & plans'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BillingScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text('Notifications'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsInboxScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.accessibility_new_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(UxScope.copy(context, 'accessSettings')),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AccessibilityUxScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline_rounded),
                    title: const Text('Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      _openProfile();
                    },
                  ),
                ],
              ),
            ),
          ),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: StreamBuilder<int>(
                    stream: _notes.watchUnreadCount(),
                    builder: (context, unreadSnap) {
                      return HomeHeader(
                        onMenu: () =>
                            _scaffoldKey.currentState?.openDrawer(),
                        unreadCount: unreadSnap.data ?? 0,
                        photoUrl: profileSnap.data?.photoUrl,
                        onNotifications: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const NotificationsInboxScreen(),
                            ),
                          );
                        },
                        onProfile: _openProfile,
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: HomeSearchRow(
                      onSearch: _openSearch,
                      locationLabel: locationLabel,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: HomeHero(onExplore: _openAccessibilityMap),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 0),
                    child: HomePrimaryActions(
                      onSos: _openEmergency,
                      onMap: _openAccessibilityMap,
                      onPassport: _openPassport,
                      onAi: _openAiAssistant,
                      onSupport: _openSupport,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: ServiceGrid(
                      onTap: _onServiceTap,
                      onViewAll: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: RecommendedForYou(
                      onSeeAll: _openAccessibilityMap,
                      onTap: (title) {
                        if (title.contains('Job') ||
                            title.contains('Marketing')) {
                          _onServiceTap('Jobs');
                        } else if (title.contains('Care')) {
                          _onServiceTap('Services');
                        } else {
                          _openAccessibilityMap();
                        }
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: HomePassportBanner(onTap: _openPassport),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        );
      },
    );
  }
}
