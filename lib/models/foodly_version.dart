class FoodlyVersion {
  String version;
  String title;
  List<FoodlyVersionNote> notes;

  FoodlyVersion({
    required this.version,
    required this.title,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'version': version,
      'title': title,
      'notes': notes.map((x) => x.toMap()).toList(),
    };
  }

  factory FoodlyVersion.fromMap(Map<String, dynamic> map) {
    return FoodlyVersion(
      version: map['version'] as String? ?? '',
      title: map['title'] as String? ?? '',
      notes: List<FoodlyVersionNote>.from(
        (map['notes'] as List<dynamic>? ?? <dynamic>[]).map<FoodlyVersionNote>(
          (dynamic x) => FoodlyVersionNote.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}

class FoodlyVersionNote {
  String language;
  String title;
  String description;
  String emoji;

  FoodlyVersionNote({
    required this.language,
    required this.title,
    required this.description,
    this.emoji = '•',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'language': language,
      'title': title,
      'description': description,
      'emoji': emoji,
    };
  }

  factory FoodlyVersionNote.fromMap(Map<String, dynamic> map) {
    return FoodlyVersionNote(
      language: map['language'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      emoji: map['emoji'] as String? ?? '',
    );
  }
}
