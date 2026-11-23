import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/flashcard_models.dart';

abstract interface class FlashcardPreferences {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);
}

class SharedFlashcardPreferences implements FlashcardPreferences {
  SharedFlashcardPreferences(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}

class FlashcardRepository {
  FlashcardRepository(this._preferences);

  final FlashcardPreferences _preferences;
  final Uuid _uuid = const Uuid();

  Future<List<FlashcardSet>> getSets(String userId) async {
    final json = await _preferences.getString(_setsKey(userId));
    if (json == null) return [];
    final values = jsonDecode(json) as List<dynamic>;
    return values
        .map(
          (value) =>
              FlashcardSet.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
  }

  Future<FlashcardSet?> getSet(String userId, String setId) async {
    for (final set in await getSets(userId)) {
      if (set.id == setId) return set;
    }
    return null;
  }

  Future<FlashcardSet> saveSet({
    required String userId,
    required String? setId,
    required String title,
    required String subject,
    required String description,
    required List<Flashcard> cards,
  }) async {
    final sets = await getSets(userId);
    final set = FlashcardSet(
      id: setId ?? _uuid.v4(),
      title: title.trim(),
      subject: subject.trim(),
      description: description.trim(),
      cards: cards,
      updatedAt: DateTime.now(),
    );
    final index = sets.indexWhere((candidate) => candidate.id == set.id);
    if (index == -1) {
      sets.insert(0, set);
    } else {
      sets[index] = set;
    }
    await _preferences.setString(
      _setsKey(userId),
      jsonEncode(sets.map((item) => item.toJson()).toList()),
    );
    return set;
  }

  Future<void> deleteSet(String userId, String setId) async {
    final sets = await getSets(userId)
      ..removeWhere((set) => set.id == setId);
    await _preferences.setString(
      _setsKey(userId),
      jsonEncode(sets.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> saveActivity({
    required String userId,
    required String setId,
    required String kind,
    required int total,
    required int correct,
  }) async {
    final activities = await getActivities(userId);
    activities.insert(
      0,
      StudyActivity(
        id: _uuid.v4(),
        setId: setId,
        kind: kind,
        total: total,
        correct: correct,
        completedAt: DateTime.now(),
      ),
    );
    await _preferences.setString(
      _activitiesKey(userId),
      jsonEncode(activities.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<StudyActivity>> getActivities(String userId) async {
    final json = await _preferences.getString(_activitiesKey(userId));
    if (json == null) return [];
    final values = jsonDecode(json) as List<dynamic>;
    return values
        .map(
          (value) =>
              StudyActivity.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
  }

  String _setsKey(String userId) => 'flash_ed_sets_$userId';
  String _activitiesKey(String userId) => 'flash_ed_activities_$userId';
}
