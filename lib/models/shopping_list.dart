import 'package:foodly/models/grocery.dart';

class ShoppingList {
  String id;
  String planId;
  List<String> meals;
  List<Grocery> groceries;

  ShoppingList({
    this.id,
    this.planId,
    this.meals,
    this.groceries,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId ?? '',
      'meals': meals ?? [],
      'groceries': groceries?.map((x) => x?.toMap())?.toList() ?? [],
    };
  }

  factory ShoppingList.fromMap(String id, Map<String, dynamic> map) {
    if (map == null) return null;

    return ShoppingList(
      id: id,
      planId: map['planId'],
      meals: List<String>.from(map['meals'] ?? ''),
      groceries:
          List<Grocery>.from(map['groceries']?.map((x) => Grocery.fromMap(x))),
    );
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, planId: $planId, meals: $meals, groceries: $groceries)';
  }
}
