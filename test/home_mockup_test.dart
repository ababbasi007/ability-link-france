import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ability_link/screens/home/widgets/home_header.dart';
import 'package:ability_link/screens/home/widgets/home_hero_sos_row.dart';
import 'package:ability_link/screens/home/widgets/home_promos.dart';
import 'package:ability_link/screens/home/widgets/home_quick_tiles.dart';
import 'package:ability_link/screens/home/widgets/service_grid.dart';
import 'package:ability_link/screens/home/widgets/upcoming_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('home mockup sections render', (tester) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              HomeHeader(
                onMenu: () {},
                onNotifications: () {},
                onProfile: () {},
              ),
              HomeSearchRow(onSearch: () {}),
              HomeHeroSosRow(
                userName: 'Ahmed',
                onAskAi: () {},
                onSos: () {},
              ),
              HomeQuickTiles(
                onPassport: () {},
                onBookings: () {},
                onMessages: () {},
                onSaved: () {},
              ),
              ServiceGrid(onTap: (_) {}),
              UpcomingSection(
                appointments: const [],
                onViewAll: () {},
                onItem: (_) {},
              ),
              HomeAiBanner(onChat: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ability Link'), findsOneWidget);
    expect(
      find.text('Connecting Abilities, Empowering Lives'),
      findsOneWidget,
    );
    expect(
      find.text('Search services, places, people...'),
      findsOneWidget,
    );
    expect(find.text('Hi Ahmed! 👋'), findsOneWidget);
    expect(find.text('Ask AI Assistant'), findsOneWidget);
    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.text('Tap to Alert >'), findsOneWidget);
    expect(find.text('Accessibility Passport'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Explore Services'), findsOneWidget);
    expect(find.text('Healthcare'), findsOneWidget);
    expect(find.text('Tele-Rehab'), findsOneWidget);
    expect(find.text('Rights & Legal'), findsOneWidget);
    expect(find.text('Upcoming'), findsWidgets);
    expect(find.text('Physiotherapy Session'), findsOneWidget);
    expect(find.text('Chat with AI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
