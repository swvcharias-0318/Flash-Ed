import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/flashcard_models.dart';
import 'flashcard_providers.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({required this.setId, super.key});

  final String setId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<Flashcard>? _questions;
  final Map<String, String> _answers = {};
  String? _selected;
  int _index = 0;
  bool _complete = false;
  bool _saving = false;

  Future<void> _submit(List<Flashcard> questions) async {
    final selected = _selected;
    if (selected == null) return;
    final question = questions[_index];
    setState(() {
      _answers[question.id] = selected;
      _selected = null;
      if (_index == questions.length - 1) {
        _complete = true;
      } else {
        _index++;
      }
    });
    if (_complete) await _saveResult(questions);
  }

  Future<void> _saveResult(List<Flashcard> questions) async {
    if (_saving) return;
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    final correct = questions
        .where((question) => _answers[question.id] == question.back)
        .length;
    try {
      await ref
          .read(flashcardRepositoryProvider)
          .saveActivity(
            userId: userId,
            setId: widget.setId,
            kind: 'quiz',
            total: questions.length,
            correct: correct,
          );
      ref.invalidate(studyActivitiesProvider(userId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your quiz result.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _startQuiz(List<Flashcard> cards) {
    final questions = [...cards]..shuffle(Random());
    setState(() {
      _questions = questions;
      _answers.clear();
      _selected = null;
      _index = 0;
      _complete = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authStateProvider).value?.id;
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final setAsync = ref.watch(flashcardSetProvider((userId, widget.setId)));

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: setAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Could not load this study set.')),
        data: (set) {
          if (set == null || set.cards.length < 2) {
            return const Center(
              child: Text('A quiz needs at least two flashcards.'),
            );
          }
          if (_questions == null) return _intro(set.cards);
          final questions = _questions!;
          if (_complete) return _results(questions);
          return _question(questions);
        },
      ),
    );
  }

  Widget _intro(List<Flashcard> cards) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.quiz_rounded, size: 56, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'Ready to test yourself?',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text('${cards.length} randomized questions · multiple choice'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => _startQuiz(cards),
            child: const Text('Start quiz'),
          ),
        ],
      ),
    ),
  );

  Widget _question(List<Flashcard> questions) {
    final question = questions[_index];
    final options = questions.map((item) => item.back).toSet().toList()
      ..shuffle(Random(question.id.hashCode));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            LinearProgressIndicator(
              value: (_index + 1) / questions.length,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 10),
            Text('Question ${_index + 1} of ${questions.length}'),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Text(
                  question.front,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...options.map((option) {
              final selected = _selected == option;
              return Card(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selected = option),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selected ? AppColors.primary : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(option)),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _selected == null ? null : () => _submit(questions),
              child: Text(
                _index == questions.length - 1
                    ? 'Finish quiz'
                    : 'Next question',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _results(List<Flashcard> questions) {
    final correct = questions
        .where((question) => _answers[question.id] == question.back)
        .length;
    final percent = (correct * 100 / questions.length).round();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(
          Icons.emoji_events_rounded,
          size: 56,
          color: AppColors.warning,
        ),
        const SizedBox(height: 12),
        Text(
          'Quiz complete: $percent%',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          '$correct correct out of ${questions.length}'
          '${_saving ? ' · saving result…' : ''}',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ...questions.map((question) {
          final answer = _answers[question.id];
          final wasCorrect = answer == question.back;
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.front,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wasCorrect ? 'Correct' : 'Your answer: $answer',
                    style: TextStyle(
                      color: wasCorrect ? AppColors.success : AppColors.error,
                    ),
                  ),
                  if (!wasCorrect) Text('Correct answer: ${question.back}'),
                ],
              ),
            ),
          );
        }),
        OutlinedButton(
          onPressed: () => _startQuiz(questions),
          child: const Text('Retake quiz'),
        ),
      ],
    );
  }
}
