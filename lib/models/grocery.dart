import 'dart:convert';

import 'ingredient.dart';

class Grocery {
  String? id;
  String? name;
  double? amount;
  String? unit;
  String? group;
  bool bought;
  DateTime lastBoughtEdited;

  Grocery({
    this.id,
    this.name,
    this.amount = 0.0,
    this.unit = '',
    this.group,
    this.bought = false,
    required this.lastBoughtEdited,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'amount': amount,
      'unit': unit,
      'group': group,
      'bought': bought,
      'lastBoughtEdited': lastBoughtEdited.millisecondsSinceEpoch,
    };
  }

  String toJson() => json.encode(toMap());

  Ingredient toIngredient() {
    return Ingredient(
      name: name,
      amount: amount,
      unit: unit,
      productGroup: group,
    );
  }

  factory Grocery.fromMap(String id, Map<String, dynamic> map) {
    return Grocery(
      id: id,
      name: map['name'] as String?,
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : map['amount'] as double?,
      unit: map['unit'] as String?,
      group: map['group'] as String?,
      bought: map['bought'] as bool? ?? false,
      lastBoughtEdited: map['lastBoughtEdited'] == null
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(map['lastBoughtEdited'] as int),
    );
  }

  factory Grocery.fromApiSuggestion(Map<String, dynamic> map) {
    return Grocery(
      name: map['name'] as String?,
      group: map['group']?.toString(),
      amount: map['amount'] is int
          ? (map['amount'] as int).toDouble()
          : map['amount'] as double?,
      unit: map['unit'] as String?,
      lastBoughtEdited: DateTime.now(),
    );
  }

  factory Grocery.fromIngredient(Ingredient ingredient) {
    return Grocery(
      name: ingredient.name,
      group: ingredient.productGroup,
      amount: ingredient.amount,
      unit: ingredient.unit,
      lastBoughtEdited: DateTime.now(),
    );
  }

  @override
  String toString() =>
      'Grocery(id: $id, name: $name, amount: $amount, unit: $unit, bought: $bought, group: $group, lastEdited: ${lastBoughtEdited.toIso8601String()})';
}
