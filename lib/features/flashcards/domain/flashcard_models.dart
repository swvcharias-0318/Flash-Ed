class Flashcard {
  const Flashcard({required this.id, required this.front, required this.back});

  final String id;
  final String front;
  final String back;

  Map<String, Object?> toJson() => {'id': id, 'front': front, 'back': back};

  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(
    id: json['id'] as String,
    front: json['front'] as String,
    back: json['back'] as String,
  );
}

class FlashcardSet {
  const FlashcardSet({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.cards,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String subject;
  final String description;
  final List<Flashcard> cards;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'subject': subject,
    'description': description,
    'cards': cards.map((card) => card.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory FlashcardSet.fromJson(Map<String, dynamic> json) => FlashcardSet(
    id: json['id'] as String,
    title: json['title'] as String,
    subject: json['subject'] as String? ?? '',
    description: json['description'] as String? ?? '',
    cards: (json['cards'] as List<dynamic>)
        .map(
          (card) => Flashcard.fromJson(Map<String, dynamic>.from(card as Map)),
        )
        .toList(),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

class StudyActivity {
  const StudyActivity({
    required this.id,
    required this.setId,
    required this.kind,
    required this.total,
    required this.correct,
    required this.completedAt,
  });

  final String id;
  final String setId;
  final String kind;
  final int total;
  final int correct;
  final DateTime completedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'setId': setId,
    'kind': kind,
    'total': total,
    'correct': correct,
    'completedAt': completedAt.toIso8601String(),
  };

  factory StudyActivity.fromJson(Map<String, dynamic> json) => StudyActivity(
    id: json['id'] as String,
    setId: json['setId'] as String,
    kind: json['kind'] as String,
    total: json['total'] as int,
    correct: json['correct'] as int,
    completedAt: DateTime.parse(json['completedAt'] as String),
  );
}
