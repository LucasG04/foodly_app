class Meal {
  String id;
  String name;
  String source;
  String instruction;
  int duration;
  List<String> ingredients;
  List<String> tags;
  String imageUrl;
  String planId;
  bool isPublic;

  Meal({
    this.id,
    this.name,
    this.source,
    this.instruction,
    this.duration,
    this.ingredients,
    this.tags,
    this.imageUrl,
    this.planId,
    this.isPublic,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source': source,
      'instruction': instruction,
      'duration': duration,
      'ingredients': ingredients,
      'tags': tags,
      'imageUrl': imageUrl,
      'planId': planId,
      'isPublic': isPublic ?? false,
    };
  }

  factory Meal.fromMap(String id, Map<String, dynamic> map) {
    if (map == null) return null;

    return Meal(
      id: id,
      name: map['name'],
      source: map['source'],
      instruction: map['instruction'],
      imageUrl: map['imageUrl'],
      duration: int.tryParse(map['duration'].toString()) ?? 0,
      ingredients: List<String>.from(map['ingredients'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      planId: map['planId'],
      isPublic: map['isPublic'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Meal(id: $id, name: $name, source: $source, instruction: $instruction, duration: $duration, ingredients: $ingredients, tags: $tags)';
  }
}
