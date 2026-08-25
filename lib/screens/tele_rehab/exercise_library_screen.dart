import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/rehab.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';
import '../../services/rehab_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/decoded_network_image.dart';

class ExerciseLibraryScreen extends StatelessWidget {
  const ExerciseLibraryScreen({super.key, this.category = 'all'});

  final String category;

  static const cats = [
    ('all', 'All'),
    ('upper', 'Upper Body'),
    ('lower', 'Lower Body'),
    ('flexibility', 'Flexibility'),
    ('strength', 'Strength'),
    ('breathing', 'Breathing'),
    ('speech', 'Speech'),
  ];

  @override
  Widget build(BuildContext context) {
    final rehab = RehabService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Exercise library',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<RehabExercise>>(
        stream: rehab.watchExercises(),
        builder: (context, snap) {
          var list = snap.data ?? const <RehabExercise>[];
          if (category != 'all') {
            list = list.where((e) => e.category == category).toList();
          }
          return Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    for (final c in cats)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c.$2),
                          selected: category == c.$1,
                          onSelected: (_) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ExerciseLibraryScreen(category: c.$1),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Loading exercises…'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final e = list[i];
                          return ListTile(
                            tileColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: DecodedNetworkImage(
                                e.imageUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.fitness_center),
                              ),
                            ),
                            title: Text(
                              e.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text('${e.meta} · ${e.minutes} min'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ExerciseDetailScreen(exercise: e),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
    this.inSession = false,
  });

  final RehabExercise exercise;
  final bool inSession;

  @override
  Widget build(BuildContext context) {
    final rehab = RehabService();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          inSession ? 'Exercise demonstration' : exercise.title,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: DecodedNetworkImage(
              exercise.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 160,
                color: AppColors.primaryLight,
                child: const Icon(Icons.fitness_center, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            exercise.demoCue,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${exercise.sets} sets'
            '${exercise.reps > 0 ? ' · ${exercise.reps} reps' : ''} · ${exercise.minutes} min',
          ),
          const SizedBox(height: 16),
          Text(
            'Demonstration steps',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < exercise.steps.length; i++)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              title: Text(exercise.steps[i]),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              try {
                await rehab.markPlanStatus(
                  exerciseId: exercise.id,
                  status: 'done',
                  completedSets: exercise.sets,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Marked complete on today’s plan'),
                  ),
                );
                if (inSession) Navigator.pop(context, true);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$e')));
              }
            },
            child: const Text('Mark as done'),
          ),
        ],
      ),
    );
  }
}

class RehabProgramsScreen extends StatelessWidget {
  const RehabProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rehab = RehabService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Rehabilitation programs',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: StreamBuilder<List<RehabProgram>>(
        stream: rehab.watchPrograms(),
        builder: (context, snap) {
          final list = snap.data ?? const <RehabProgram>[];
          if (list.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = list[i];
              return ListTile(
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                title: Text(
                  p.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  '${p.discipline} · ${p.weeks} weeks\n${p.summary}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  try {
                    await rehab.assignProgram(p);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${p.title} is now your plan')),
                    );
                    Navigator.pop(context);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('$e')));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PersonalizedPlanScreen extends StatelessWidget {
  const PersonalizedPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rehab = RehabService();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Personalized exercise plan',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const RehabProgramsScreen(),
              ),
            ),
            child: const Text('Programs'),
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: AuthService().watchCurrentProfile(),
        builder: (context, profileSnap) {
          return StreamBuilder<List<RehabExercise>>(
            stream: rehab.watchExercises(),
            builder: (context, exSnap) {
              return StreamBuilder<Map<String, RehabPlanItem>>(
                stream: rehab.watchPlan(),
                builder: (context, planSnap) {
                  final all = exSnap.data ?? const <RehabExercise>[];
                  final plan = planSnap.data ?? {};
                  final suggested = rehab.personalized(all, profileSnap.data);
                  final today = all
                      .where((e) => plan.containsKey(e.id))
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(
                        'Today',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (today.isEmpty)
                        const Text(
                          'No plan yet — pick a program or a suggested exercise.',
                        ),
                      for (final e in today)
                        _PlanTile(
                          exercise: e,
                          item: plan[e.id]!,
                          onChanged: (status) => rehab.markPlanStatus(
                            exerciseId: e.id,
                            status: status,
                            completedSets: status == 'done' ? e.sets : 0,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Suggested for your Passport',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final e in suggested)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(e.title),
                          subtitle: Text(e.meta),
                          trailing: TextButton(
                            onPressed: () => rehab.markPlanStatus(
                              exerciseId: e.id,
                              status: 'pending',
                            ),
                            child: const Text('Add'),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ExerciseDetailScreen(exercise: e),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.exercise,
    required this.item,
    required this.onChanged,
  });

  final RehabExercise exercise;
  final RehabPlanItem item;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(exercise.title),
        subtitle: Text(item.status),
        trailing: PopupMenuButton<String>(
          onSelected: onChanged,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'pending', child: Text('Pending')),
            PopupMenuItem(value: 'inProgress', child: Text('In progress')),
            PopupMenuItem(value: 'done', child: Text('Done')),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => ExerciseDetailScreen(exercise: exercise),
          ),
        ),
      ),
    );
  }
}
