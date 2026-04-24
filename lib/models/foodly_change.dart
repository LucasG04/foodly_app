class ChangeTranslation {
  final String language;
  final String title;
  final String description;

  const ChangeTranslation({
    required this.language,
    required this.title,
    required this.description,
  });

  factory ChangeTranslation.fromMap(Map<String, dynamic> map) {
    return ChangeTranslation(
      language: map['language'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
    );
  }
}

class FoodlyChange {
  final String id;
  final String version;
  final String? emoji;
  final List<ChangeTranslation> translations;

  const FoodlyChange({
    required this.id,
    required this.version,
    this.emoji,
    required this.translations,
  });

  factory FoodlyChange.fromMap(Map<String, dynamic> map) {
    return FoodlyChange(
      id: map['id'] as String? ?? '',
      version: map['version'] as String? ?? '',
      emoji: map['emoji'] as String?,
      translations: List<ChangeTranslation>.from(
        (map['translations'] as List<dynamic>? ?? <dynamic>[])
            .map<ChangeTranslation>(
          (dynamic x) => ChangeTranslation.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }
}
