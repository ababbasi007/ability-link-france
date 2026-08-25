import 'package:ability_link/models/inclusive_job.dart';
import 'package:ability_link/screens/jobs/job_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _job = InclusiveJob(
  id: 'job-1',
  title: 'Accessibility engineer',
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
  testWidgets('detail screens do not add a second bottom bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: JobDetailScreen(job: _job, matchScore: 88)),
    );

    // The app-wide navigation lives below every route, so a screen-level
    // bottomNavigationBar would stack a second bar on top of it.
    final scaffolds = tester.widgetList<Scaffold>(find.byType(Scaffold));
    expect(scaffolds, isNotEmpty);
    for (final scaffold in scaffolds) {
      expect(scaffold.bottomNavigationBar, isNull);
    }
  });

  testWidgets('the primary action stays reachable in the content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: JobDetailScreen(job: _job, matchScore: 88)),
    );

    expect(find.text('Apply with accommodations'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ListView),
        matching: find.text('Apply with accommodations'),
      ),
      findsOneWidget,
    );
  });
}
