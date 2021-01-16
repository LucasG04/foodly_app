import 'package:flutter/foundation.dart';

import 'plan_meal.dart';

class Plan {
  String id;
  String name;
  List<PlanMeal> meals;
  List<String> users;
  List<String> shoppingList;
  int hourDiffToUtc;

  Plan({
    this.id,
    this.name,
    this.meals,
    this.users,
    this.shoppingList,
    this.hourDiffToUtc,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'meals': meals?.map((x) => x?.toMap())?.toList(),
      'users': users,
      'shoppingList': shoppingList,
      'hourDiffToUtc': hourDiffToUtc,
    };
  }

  factory Plan.fromMap(String id, Map<String, dynamic> map) {
    if (map == null) return null;

    return Plan(
      id: id,
      name: map['name'],
      meals: List<PlanMeal>.from(map['meals']?.map((x) => PlanMeal.fromMap(x))),
      users: List<String>.from(map['users']),
      shoppingList: List<String>.from(map['shoppingList']),
      hourDiffToUtc: map['hourDiffToUtc'],
    );
  }

  @override
  String toString() {
    return 'Plan(id: $id, name: $name, meals: $meals, users: $users, shoppingList: $shoppingList)';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is Plan &&
        o.id == id &&
        o.name == name &&
        o.hourDiffToUtc == hourDiffToUtc &&
        listEquals(o.meals, meals) &&
        listEquals(o.users, users) &&
        listEquals(o.shoppingList, shoppingList);
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        meals.hashCode ^
        users.hashCode ^
        hourDiffToUtc.hashCode ^
        shoppingList.hashCode;
  }
}
