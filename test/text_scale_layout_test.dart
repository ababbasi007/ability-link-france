import 'package:ability_link/models/inclusive_job.dart';
import 'package:ability_link/screens/jobs/job_detail_screen.dart';
import 'package:ability_link/screens/tele_rehab/tele_rehab_chrome.dart';
import 'package:ability_link/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _job = InclusiveJob(
  id: 'job-1',
  title: 'Accessibility engineer for inclusive design systems',
  employerId: 'emp-1',
  employerName: 'Inclusive Co',
  city: 'Lyon',
  workType: 'full-time',
  category: 'Engineering',
  summary: 'Build accessible interfaces.',
  description: 'Long description of the role.',
  accommodations: ['Flexible hours', 'Screen reader'],
  inclusiveFor: ['Visual'],
  salaryLabel: '€45k',
);

void main() {
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    required double scale,
    double width = 320,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = Size(width, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: MaterialApp(home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final scale in [1.0, 1.3, 1.7]) {
    testWidgets('nav bar at ${scale}x', (tester) async {
      await pumpAt(
        tester,
        Scaffold(
          body: const SizedBox.shrink(),
          bottomNavigationBar: AppBottomNavBar(index: 0, onTap: (_) {}),
        ),
        scale: scale,
      );
    });

    testWidgets('quick actions at ${scale}x', (tester) async {
      await pumpAt(
        tester,
        Scaffold(body: RehabQuickActions(onAction: (_) {})),
        scale: scale,
      );
    });

    testWidgets('exercise library at ${scale}x', (tester) async {
      await pumpAt(
        tester,
        Scaffold(
          body: RehabExerciseLibrary(onViewAll: () {}, onCategory: (_) {}),
        ),
        scale: scale,
      );
    });

    testWidgets('recovery tools at ${scale}x', (tester) async {
      await pumpAt(
        tester,
        Scaffold(body: RehabRecoveryTools(onTool: (_) {})),
        scale: scale,
      );
    });

    testWidgets('job detail at ${scale}x', (tester) async {
      await pumpAt(
        tester,
        const JobDetailScreen(job: _job, matchScore: 88),
        scale: scale,
      );
    });
  }
}
