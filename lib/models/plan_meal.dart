class PlanMeal {
  String id;
  DateTime date;
  String meal;
  MealType type;
  List<String> upvotes;
  List<String> downvotes;

  PlanMeal({
    this.id,
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

  factory PlanMeal.fromMap(String id, Map<String, dynamic> map) {
    if (map == null) return null;

    return PlanMeal(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      meal: map['meal'],
      type: MealType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MealType.LUNCH,
      ),
      upvotes: List<String>.from(map['upvotes'] ?? []),
      downvotes: List<String>.from(map['downvotes'] ?? []),
    );
  }

  @override
  String toString() => 'PlanMeal(date: $date, meal: $meal, type: $type)';
}

enum MealType { LUNCH, DINNER }
