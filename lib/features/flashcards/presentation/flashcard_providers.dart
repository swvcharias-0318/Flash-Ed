import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/flashcard_repository.dart';
import '../domain/flashcard_models.dart';

final flashcardRepositoryProvider = Provider<FlashcardRepository>(
  (ref) =>
      FlashcardRepository(SharedFlashcardPreferences(SharedPreferencesAsync())),
);

final flashcardSetsProvider = FutureProvider.family<List<FlashcardSet>, String>(
  (ref, userId) {
    return ref.watch(flashcardRepositoryProvider).getSets(userId);
  },
);

final flashcardSetProvider =
    FutureProvider.family<FlashcardSet?, (String, String)>((ref, args) {
      return ref.watch(flashcardRepositoryProvider).getSet(args.$1, args.$2);
    });

final studyActivitiesProvider =
    FutureProvider.family<List<StudyActivity>, String>((ref, userId) {
      return ref.watch(flashcardRepositoryProvider).getActivities(userId);
    });
