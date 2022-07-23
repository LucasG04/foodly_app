class PlanMeal {
  String? id;
  DateTime date;
  String meal;
  MealType type;
  List<String>? upvotes;
  List<String>? downvotes;

  PlanMeal({
    this.id,
    required this.date,
    required this.meal,
    required this.type,
    this.upvotes,
    this.downvotes,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date.millisecondsSinceEpoch,
      'meal': meal,
      'type': type.toString(),
      'upvotes': upvotes,
      'downvotes': downvotes,
    };
  }

  factory PlanMeal.fromMap(String id, Map<String, dynamic> map) {
    return PlanMeal(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      meal: map['meal'] as String,
      type: MealType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => MealType.LUNCH,
      ),
      upvotes:
          List<String>.from((map['upvotes'] as List<dynamic>?) ?? <String>[]),
      downvotes:
          List<String>.from((map['downvotes'] as List<dynamic>?) ?? <String>[]),
    );
  }

  @override
  String toString() => 'PlanMeal(date: $date, meal: $meal, type: $type)';
}

// ignore: constant_identifier_names
enum MealType { BREAKFAST, LUNCH, DINNER }
