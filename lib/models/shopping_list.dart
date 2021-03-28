class ShoppingList {
  String id;
  String planId;
  List<String> meals;

  ShoppingList({
    this.id,
    this.planId,
    this.meals,
  });

  Map<String, dynamic> toMap() {
    return {
      'planId': planId ?? '',
      'meals': meals ?? [],
    };
  }

  factory ShoppingList.fromMap(String id, Map<String, dynamic> map) {
    if (map == null) return null;

    return ShoppingList(
      id: id,
      planId: map['planId'],
      meals: List<String>.from(map['meals'] ?? ''),
    );
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, planId: $planId, meals: $meals)';
  }
}
