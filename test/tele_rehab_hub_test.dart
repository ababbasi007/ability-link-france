import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ability_link/screens/tele_rehab/tele_rehab_hub.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tele-rehab hub matches the mockup sections', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RehabHubView(
            name: 'Alex',
            unreadBadge: '3',
            therapistName: 'Dr. Sarah Johnson',
            whenLabel: 'Today, 10:00 AM',
            durationMin: 30,
            photoAsset: 'assets/images/rehab/therapist_sarah.png',
            plan: const [
              RehabHubPlanItem(
                title: 'Lower Back Stretch',
                minutes: 10,
                done: true,
                image: 'assets/images/rehab/ex_seated_row.png',
              ),
            ],
            onBack: () {},
            onBell: () {},
            onCalendar: () {},
            onVideo: () {},
            onPlans: () {},
            onProgress: () {},
            onHealth: () {},
            onMessages: () {},
            onLibrary: () {},
            onJoin: () {},
            onReschedule: () {},
            onMore: () {},
            onPlanItem: (_) {},
            onAskAi: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tele'), findsOneWidget);
    expect(find.text('Rehabilitation'), findsOneWidget);
    expect(
      find.text('Rehab care, anywhere you are'),
      findsOneWidget,
    );
    expect(find.text('Start\nSession'), findsOneWidget);
    expect(find.text('Book\nAppointment'), findsOneWidget);
    expect(find.text('Upcoming Session'), findsOneWidget);
    expect(find.text('Join Session'), findsOneWidget);
    expect(find.text('Today’s Progress'), findsOneWidget);
    expect(find.text('Great job! You’re making progress.'), findsOneWidget);
    expect(find.text('Today’s Exercises'), findsOneWidget);
    expect(find.text('Dr. Sarah Johnson'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
