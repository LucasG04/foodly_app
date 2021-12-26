class ShoppingList {
  String? id;
  String? planId;
  List<String>? meals;

  ShoppingList({
    this.id,
    this.planId,
    this.meals,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'planId': planId ?? '',
      'meals': meals ?? [],
    };
  }

  factory ShoppingList.fromMap(String id, Map<String, dynamic> map) {
    return ShoppingList(
      id: id,
      planId: map['planId'] as String?,
      meals: List<String>.from((map['meals'] as List<dynamic>?) ?? <String>[]),
    );
  }

  @override
  String toString() {
    return 'ShoppingList(id: $id, planId: $planId, meals: $meals)';
  }
}
