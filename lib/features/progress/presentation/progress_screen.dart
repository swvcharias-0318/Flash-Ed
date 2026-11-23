import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../flashcards/presentation/flashcard_providers.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sets = ref.watch(flashcardSetsProvider(userId));
    final activities = ref.watch(studyActivitiesProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('Learning progress')),
      body: sets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Could not load your progress.')),
        data: (allSets) => activities.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              const Center(child: Text('Could not load your progress.')),
          data: (allActivities) {
            final sessions = allActivities
                .where((item) => item.kind == 'study')
                .toList();
            final quizzes = allActivities
                .where((item) => item.kind == 'quiz')
                .toList();
            final average = quizzes.isEmpty
                ? 0
                : (quizzes.fold<int>(0, (sum, item) {
                            if (item.total == 0) return sum;
                            return sum + (item.correct * 100 ~/ item.total);
                          }) /
                          quizzes.length)
                      .round();
            final totalCards = allSets.fold<int>(
              0,
              (sum, set) => sum + set.cards.length,
            );

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(label: 'Sets', value: '${allSets.length}'),
                    _StatCard(label: 'Cards', value: '$totalCards'),
                    _StatCard(
                      label: 'Study sessions',
                      value: '${sessions.length}',
                    ),
                    _StatCard(label: 'Quizzes', value: '${quizzes.length}'),
                    _StatCard(
                      label: 'Average quiz score',
                      value: quizzes.isEmpty ? '—' : '$average%',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent quiz scores',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 20),
                        if (quizzes.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 30),
                            child: Center(
                              child: Text(
                                'Complete a quiz to see your scores.',
                              ),
                            ),
                          )
                        else
                          SizedBox(
                            height: 190,
                            child: BarChart(
                              BarChartData(
                                minY: 0,
                                maxY: 100,
                                barGroups: quizzes
                                    .take(7)
                                    .toList()
                                    .reversed
                                    .toList()
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                      final item = entry.value;
                                      final score = item.total == 0
                                          ? 0.0
                                          : item.correct * 100 / item.total;
                                      return BarChartGroupData(
                                        x: entry.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: score,
                                            color: AppColors.primary,
                                            width: 18,
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                        ],
                                      );
                                    })
                                    .toList(),
                                titlesData: const FlTitlesData(
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: const FlGridData(
                                  drawVerticalLine: false,
                                ),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...allActivities.take(10).map((activity) {
                  final percent = activity.total == 0
                      ? 0
                      : activity.correct * 100 ~/ activity.total;
                  return ListTile(
                    leading: Icon(
                      activity.kind == 'quiz'
                          ? Icons.quiz_outlined
                          : Icons.style_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      activity.kind == 'quiz'
                          ? 'Quiz completed'
                          : 'Study session completed',
                    ),
                    subtitle: Text(
                      '${activity.correct}/${activity.total}'
                      '${activity.kind == 'quiz' ? ' correct · $percent%' : ' known'}'
                      '  ·  ${_formatDate(activity.completedAt)}',
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => '${date.month}/${date.day}/${date.year}';
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
