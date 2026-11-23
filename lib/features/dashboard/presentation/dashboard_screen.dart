import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../../flashcards/presentation/flashcard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 700;
    final user = ref.watch(authStateProvider).value;
    final sets = user == null
        ? null
        : ref.watch(flashcardSetsProvider(user.id)).value;
    final activities = user == null
        ? null
        : ref.watch(studyActivitiesProvider(user.id)).value;
    final cardCount =
        sets?.fold<int>(0, (total, set) => total + set.cards.length) ?? 0;
    final quizCount =
        activities?.where((item) => item.kind == 'quiz').length ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FLASH-ED',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hi${user?.displayName?.isNotEmpty ?? false ? ', ${user!.displayName!.split(' ').first}' : ''}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.10,
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _WelcomeCard(onCreateTap: () => context.go('/flashcards')),
                  const SizedBox(height: 28),
                  Text(
                    'Jump back in',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    crossAxisCount: isWide ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: isWide ? 1.55 : 1.3,
                    children: [
                      _ActionCard(
                        icon: Icons.menu_book_rounded,
                        label: 'Browse materials',
                        color: AppColors.primary,
                        onTap: () => context.go('/materials'),
                      ),
                      _ActionCard(
                        icon: Icons.add_card_rounded,
                        label: 'Create flashcards',
                        color: AppColors.accent,
                        onTap: () => context.go('/flashcards'),
                      ),
                      _ActionCard(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Study flashcards',
                        color: const Color(0xFF0891B2),
                        onTap: () => context.go('/flashcards'),
                      ),
                      _ActionCard(
                        icon: Icons.insights_rounded,
                        label: 'View progress',
                        color: AppColors.success,
                        onTap: () => context.go('/progress'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Your learning at a glance',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _DashboardStat(
                        label: 'Flashcards',
                        value: sets == null ? '—' : '$cardCount',
                      ),
                      _DashboardStat(
                        label: 'Study sessions',
                        value: activities == null
                            ? '—'
                            : '${activities.where((item) => item.kind == 'study').length}',
                      ),
                      _DashboardStat(
                        label: 'Quizzes',
                        value: activities == null ? '—' : '$quizCount',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardStat extends StatelessWidget {
  const _DashboardStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 145,
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

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.waving_hand_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 16),
          Text(
            'Learn at your pace.',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Learn. Create. Review. Master.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Start a study set'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
