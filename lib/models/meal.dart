import 'package:flutter/foundation.dart';

class Meal {
  String id;
  String name;
  String source;
  String instruction;
  int duration;
  List<String> ingredients;
  List<String> tags;
  String imageUrl;

  Meal({
    this.id,
    this.name,
    this.source,
    this.instruction,
    this.duration,
    this.ingredients,
    this.tags,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'source': source,
      'instruction': instruction,
      'duration': duration,
      'ingredients': ingredients,
      'tags': tags,
      'imageUrl': imageUrl,
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
      ingredients: List<String>.from(map['ingredients']),
      tags: List<String>.from(map['tags']),
    );
  }

  @override
  String toString() {
    return 'Meal(id: $id, name: $name, source: $source, instruction: $instruction, duration: $duration, ingredients: $ingredients, tags: $tags)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Meal &&
        o.id == id &&
        o.name == name &&
        o.source == source &&
        o.instruction == instruction &&
        o.duration == duration &&
        o.imageUrl == imageUrl &&
        listEquals(o.ingredients, ingredients) &&
        listEquals(o.tags, tags);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        source.hashCode ^
        instruction.hashCode ^
        duration.hashCode ^
        imageUrl.hashCode ^
        ingredients.hashCode ^
        tags.hashCode;
  }
}
