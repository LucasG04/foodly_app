import 'dart:convert';

import 'package:flutter/foundation.dart';

class PlanMeal {
  DateTime date;
  String meal;
  MealType type;
  List<String> upvotes;
  List<String> downvotes;

  PlanMeal({
    this.date,
    this.meal,
    this.type,
    this.upvotes,
    this.downvotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date?.millisecondsSinceEpoch,
      'meal': meal,
      'type': type?.toString(),
      'upvotes': upvotes,
      'downvotes': downvotes,
    };
  }

  factory PlanMeal.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return PlanMeal(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      meal: map['meal'],
      type: MealType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MealType.LUNCH,
      ),
      upvotes: List<String>.from(map['upvotes']),
      downvotes: List<String>.from(map['downvotes']),
    );
  }

  String toJson() => json.encode(toMap());

  factory PlanMeal.fromJson(String source) =>
      PlanMeal.fromMap(json.decode(source));

  @override
  String toString() => 'PlanMeal(date: $date, meal: $meal, type: $type)';

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is PlanMeal &&
        o.date == date &&
        o.meal == meal &&
        o.type == type &&
        listEquals(o.upvotes, upvotes) &&
        listEquals(o.downvotes, downvotes);
  }

  @override
  int get hashCode =>
      date.hashCode ^
      meal.hashCode ^
      type.hashCode ^
      upvotes.hashCode ^
      downvotes.hashCode;
}

enum MealType { LUNCH, DINNER }
