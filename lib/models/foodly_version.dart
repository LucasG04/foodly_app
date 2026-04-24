class FoodlyVersion {
  String version;
  List<FoodlyVersionNote> notes;
  String? emoji;

  FoodlyVersion({
    required this.version,
    required this.notes,
    this.emoji,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'version': version,
      'notes': notes.map((x) => x.toMap()).toList(),
      'emoji': emoji,
    };
  }

  factory FoodlyVersion.fromMap(Map<String, dynamic> map) {
    return FoodlyVersion(
      version: map['version'] as String? ?? '',
      notes: List<FoodlyVersionNote>.from(
        (map['notes'] as List<dynamic>? ?? <dynamic>[]).map<FoodlyVersionNote>(
          (dynamic x) => FoodlyVersionNote.fromMap(x as Map<String, dynamic>),
        ),
      ),
      emoji: map['emoji'] as String?,
    );
  }
}

class FoodlyVersionNote {
  String language;
  String title;
  String description;

  FoodlyVersionNote({
    required this.language,
    required this.title,
    required this.description,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'language': language,
      'title': title,
      'description': description,
    };
  }

  factory FoodlyVersionNote.fromMap(Map<String, dynamic> map) {
    return FoodlyVersionNote(
      language: map['language'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}
