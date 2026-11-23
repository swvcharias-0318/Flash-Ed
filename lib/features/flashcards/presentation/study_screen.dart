import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../authentication/presentation/auth_providers.dart';
import '../domain/flashcard_models.dart';
import 'flashcard_providers.dart';

class StudyScreen extends ConsumerStatefulWidget {
  const StudyScreen({required this.setId, super.key});

  final String setId;

  @override
  ConsumerState<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<StudyScreen> {
  int _index = 0;
  bool _showAnswer = false;
  bool _complete = false;
  bool _saving = false;
  final Set<String> _known = {};
  final Set<String> _needsReview = {};
  List<Flashcard>? _reviewCards;

  Future<void> _mark(bool known, List<Flashcard> cards) async {
    final card = cards[_index];
    setState(() {
      if (known) {
        _known.add(card.id);
        _needsReview.remove(card.id);
      } else {
        _needsReview.add(card.id);
        _known.remove(card.id);
      }
      _showAnswer = false;
      if (_index < cards.length - 1) {
        _index++;
      } else {
        _complete = true;
      }
    });
    if (_complete) await _saveResult(cards.length);
  }

  Future<void> _saveResult(int total) async {
    if (_saving) return;
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(flashcardRepositoryProvider)
          .saveActivity(
            userId: userId,
            setId: widget.setId,
            kind: 'study',
            total: total,
            correct: _known.length,
          );
      ref.invalidate(studyActivitiesProvider(userId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your study session.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reviewMissed() {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;
    ref.read(flashcardSetProvider((userId, widget.setId)).future).then((set) {
      if (!mounted || set == null) return;
      setState(() {
        _reviewCards = set.cards
            .where((card) => _needsReview.contains(card.id))
            .toList();
        _index = 0;
        _complete = false;
        _showAnswer = false;
        _known.clear();
        _needsReview.clear();
      });
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
      appBar: AppBar(title: const Text('Study mode')),
      body: setAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) =>
            const Center(child: Text('Could not load this set.')),
        data: (set) {
          if (set == null || set.cards.isEmpty) {
            return const Center(child: Text('This set has no cards to study.'));
          }
          final cards = _reviewCards ?? set.cards;
          if (_complete) return _resultView(cards.length);
          final card = cards[_index];
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final answerTextColor = isDark
              ? const Color(0xFFF1F5F9)
              : AppColors.primaryText;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: (_index + 1) / cards.length,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(height: 10),
                    Text('Card ${_index + 1} of ${cards.length}'),
                    const SizedBox(height: 22),
                    Expanded(
                      child: GestureDetector(
                        key: const Key('study-card'),
                        onTap: () => setState(() => _showAnswer = !_showAnswer),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Container(
                            key: ValueKey(_showAnswer),
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: _showAnswer
                                  ? (isDark
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFFEEF2FF))
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 320,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showAnswer ? 'ANSWER' : 'QUESTION',
                                      style: TextStyle(
                                        color: _showAnswer
                                            ? AppColors.secondary
                                            : AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      _showAnswer ? card.back : card.front,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            color: answerTextColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Tap card to flip',
                                      style: TextStyle(
                                        color: _showAnswer
                                            ? answerTextColor
                                            : AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _index == 0
                              ? null
                              : () => setState(() {
                                  _index--;
                                  _showAnswer = false;
                                }),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Previous'),
                        ),
                        const Spacer(),
                        if (!_showAnswer)
                          FilledButton(
                            onPressed: () => setState(() => _showAnswer = true),
                            child: const Text('Show answer'),
                          )
                        else ...[
                          OutlinedButton(
                            onPressed: () => _mark(false, cards),
                            child: const Text('Review again'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _mark(true, cards),
                            child: const Text('I knew it'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _resultView(int total) {
    final missed = _needsReview.length;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.celebration_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 18),
            Text(
              'Session complete',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Cards reviewed: $total'),
            Text('Known: ${_known.length}'),
            Text('Needs review: $missed'),
            const SizedBox(height: 20),
            if (missed > 0)
              FilledButton(
                onPressed: _reviewMissed,
                child: const Text('Review missed cards'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}
