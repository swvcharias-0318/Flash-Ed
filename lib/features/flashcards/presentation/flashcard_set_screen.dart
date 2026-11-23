import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../authentication/presentation/auth_providers.dart';
import 'flashcard_providers.dart';

class FlashcardSetScreen extends ConsumerWidget {
  const FlashcardSetScreen({required this.setId, super.key});

  final String setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authStateProvider).value?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final set = ref.watch(flashcardSetProvider((userId, setId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study set'),
        actions: [
          IconButton(
            tooltip: 'Edit set',
            onPressed: () async {
              await context.push('/flashcards/$setId/edit');
              ref.invalidate(flashcardSetProvider((userId, setId)));
              ref.invalidate(flashcardSetsProvider(userId));
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: set.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Could not load this study set.')),
        data: (value) {
          if (value == null) {
            return const Center(child: Text('This study set was not found.'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                value.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text('${value.subject}  ·  ${value.cards.length} cards'),
              if (value.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(value.description),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.push('/flashcards/$setId/study'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Study cards'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: value.cards.length < 2
                    ? null
                    : () => context.push('/flashcards/$setId/quiz'),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Take a quiz'),
              ),
              const SizedBox(height: 24),
              Text(
                'Cards in this set',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...value.cards.asMap().entries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Q${entry.key + 1}  ${entry.value.front}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.value.back,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
