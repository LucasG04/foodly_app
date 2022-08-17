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
    return <String, dynamic>{
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

  factory Meal.fromMap(String? id, Map<String, dynamic> map) {
    return Meal(
      id: id,
      name: map['name'] as String,
      source: map['source'] as String?,
      instructions: map['instructions'] as String?,
      imageUrl: (map['imageUrl'] as String?) ?? '',
      duration: int.tryParse(map['duration'].toString()) ?? 0,
      ingredients: List<Ingredient>.from(
        (map['ingredients'] as List<dynamic>).map<dynamic>(
            (dynamic x) => Ingredient.fromMap(x as Map<String, dynamic>)),
      ),
      tags: List<String>.from((map['tags'] as List<dynamic>?) ?? <String>[]),
      planId: map['planId'] as String?,
      createdBy: map['createdBy'] as String?,
      isPublic: (map['isPublic'] as bool?) ?? false,
    );
  }

  @override
  String toString() {
    return 'Meal(id: $id, name: $name, source: $source, instruction: $instructions, duration: $duration, ingredients: $ingredients, tags: $tags)';
  }
}
