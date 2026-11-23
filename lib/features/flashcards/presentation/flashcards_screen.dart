import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../authentication/presentation/auth_providers.dart';
import 'flashcard_providers.dart';

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final sets = ref.watch(flashcardSetsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('My flashcards')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/flashcards/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New set'),
      ),
      body: sets.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _LoadError(
          onRetry: () => ref.invalidate(flashcardSetsProvider(user.id)),
        ),
        data: (items) => items.isEmpty
            ? _EmptySets(onCreate: () => context.push('/flashcards/create'))
            : RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(flashcardSetsProvider(user.id)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final set = items[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: const Icon(
                            Icons.style_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          set.title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${set.subject.isEmpty ? 'No subject' : set.subject}'
                            '  ·  ${set.cards.length} cards',
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) async {
                            if (action == 'edit') {
                              await context.push('/flashcards/${set.id}/edit');
                            } else if (action == 'delete' &&
                                await _confirmDelete(context, set.title)) {
                              await ref
                                  .read(flashcardRepositoryProvider)
                                  .deleteSet(user.id, set.id);
                            }
                            ref.invalidate(flashcardSetsProvider(user.id));
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit set'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete set'),
                            ),
                          ],
                        ),
                        onTap: () => context.push('/flashcards/${set.id}'),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete this set?'),
            content: Text('"$title" and its cards will be removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class _EmptySets extends StatelessWidget {
  const _EmptySets({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.style_outlined, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Your first study set starts here',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Add questions and answers, then study or quiz yourself.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create a set'),
          ),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Could not load your flashcard sets.'),
        const SizedBox(height: 8),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
