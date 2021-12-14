import 'ingredient.dart';

class Meal {
  String? id;
  String name;
  String? source;
  String? instructions;
  int? duration;
  List<Ingredient>? ingredients;
  List<String>? tags;
  String? imageUrl;
  String? planId;
  String? createdBy;
  bool? isPublic;

  Meal({
    this.id,
    required this.name,
    this.source,
    this.instructions,
    this.duration,
    this.ingredients,
    this.tags,
    this.imageUrl,
    this.planId,
    this.createdBy,
    this.isPublic,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'source': source,
      'instructions': instructions,
      'duration': duration,
      'ingredients': ingredients?.map((x) => x.toMap()).toList(),
      'tags': tags,
      'imageUrl': imageUrl ?? '',
      'planId': planId,
      'createdBy': createdBy,
      'isPublic': isPublic ?? false,
    };
  }

  factory Meal.fromMap(String id, Map<String, dynamic> map) {
    return Meal(
      id: id,
      name: map['name'],
      source: map['source'],
      instructions: map['instructions'],
      imageUrl: map['imageUrl'] ?? '',
      duration: int.tryParse(map['duration'].toString()) ?? 0,
      ingredients: List<Ingredient>.from(
          map['ingredients']?.map((x) => Ingredient.fromMap(x))),
      tags: List<String>.from(map['tags'] ?? []),
      planId: map['planId'],
      createdBy: map['createdBy'],
      isPublic: map['isPublic'] ?? false,
    );
  }

  @override
  String toString() {
    return 'Meal(id: $id, name: $name, source: $source, instruction: $instructions, duration: $duration, ingredients: $ingredients, tags: $tags)';
  }
}
