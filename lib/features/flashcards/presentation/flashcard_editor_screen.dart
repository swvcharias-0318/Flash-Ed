import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../authentication/presentation/auth_providers.dart';
import '../domain/flashcard_models.dart';
import 'flashcard_providers.dart';

class FlashcardEditorScreen extends ConsumerStatefulWidget {
  const FlashcardEditorScreen({this.setId, super.key});

  final String? setId;

  @override
  ConsumerState<FlashcardEditorScreen> createState() =>
      _FlashcardEditorScreenState();
}

class _FlashcardEditorScreenState extends ConsumerState<FlashcardEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subject = TextEditingController();
  final _description = TextEditingController();
  final List<_CardControllers> _cards = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.setId == null) {
      _cards.add(_CardControllers());
    } else {
      _loadSet();
    }
  }

  Future<void> _loadSet() async {
    final userId = ref.read(authStateProvider).value?.id;
    if (userId == null) return;
    setState(() => _isLoading = true);
    try {
      final set = await ref
          .read(flashcardRepositoryProvider)
          .getSet(userId, widget.setId!);
      if (set == null) {
        setState(() => _loadError = 'This study set no longer exists.');
        return;
      }
      _title.text = set.title;
      _subject.text = set.subject;
      _description.text = set.description;
      _cards.addAll(set.cards.map(_CardControllers.fromCard));
      setState(() {});
    } catch (error) {
      setState(() => _loadError = 'Could not load this study set.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _subject.dispose();
    _description.dispose();
    for (final card in _cards) {
      card.dispose();
    }
    super.dispose();
  }

  void _addCard() => setState(() => _cards.add(_CardControllers()));

  void _removeCard(int index) {
    if (_cards.length == 1) return;
    setState(() {
      _cards.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(flashcardRepositoryProvider)
          .saveSet(
            userId: user.id,
            setId: widget.setId,
            title: _title.text,
            subject: _subject.text,
            description: _description.text,
            cards: _cards
                .map(
                  (controllers) => Flashcard(
                    id: controllers.id ?? const Uuid().v4(),
                    front: controllers.front.text.trim(),
                    back: controllers.back.text.trim(),
                  ),
                )
                .toList(),
          );
      ref.invalidate(flashcardSetsProvider(user.id));
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save this set. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit flashcards')),
        body: Center(child: Text(_loadError!)),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setId == null ? 'Create a set' : 'Edit set'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            TextFormField(
              key: const Key('set-title'),
              controller: _title,
              decoration: const InputDecoration(labelText: 'Set title'),
              textCapitalization: TextCapitalization.sentences,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('set-subject'),
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Subject'),
              textCapitalization: TextCapitalization.words,
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Text(
              'Cards',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ..._cards.asMap().entries.map((entry) {
              final index = entry.key;
              final card = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Card ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove card ${index + 1}',
                            onPressed: _cards.length == 1
                                ? null
                                : () => _removeCard(index),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                      TextFormField(
                        key: Key('card-front-$index'),
                        controller: card.front,
                        decoration: const InputDecoration(
                          labelText: 'Question or term',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: _required,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        key: Key('card-back-$index'),
                        controller: card.back,
                        decoration: const InputDecoration(
                          labelText: 'Answer or definition',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        validator: _required,
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: _addCard,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add another card'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: const Text('Save study set'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty)
      ? 'This field is required.'
      : null;
}

class _CardControllers {
  _CardControllers()
    : id = null,
      front = TextEditingController(),
      back = TextEditingController();

  _CardControllers.fromCard(Flashcard card)
    : id = card.id,
      front = TextEditingController(text: card.front),
      back = TextEditingController(text: card.back);

  final String? id;
  final TextEditingController front;
  final TextEditingController back;

  void dispose() {
    front.dispose();
    back.dispose();
  }
}
