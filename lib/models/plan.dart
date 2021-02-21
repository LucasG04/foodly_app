import 'plan_meal.dart';

class Plan {
  String id;
  String name;
  String code;
  List<PlanMeal> meals;
  List<String> users;
  int hourDiffToUtc;

  Plan({
    this.id,
    this.name,
    this.code,
    this.meals,
    this.users,
    this.hourDiffToUtc,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'meals': meals?.map((x) => x?.toMap())?.toList(),
      'users': users,
      'hourDiffToUtc': hourDiffToUtc,
    };
  }

  factory Plan.fromMap(String id, Map<String, dynamic> map) {
    if (map == null) return null;

    return Plan(
      id: id,
      name: map['name'],
      code: map['code'],
      meals: List<PlanMeal>.from(
          (map['meals'] ?? []).map((x) => PlanMeal.fromMap(x))),
      users: List<String>.from(map['users'] ?? []),
      hourDiffToUtc: map['hourDiffToUtc'],
    );
  }

  @override
  String toString() {
    return 'Plan(id: $id, name: $name, meals: $meals, users: $users)';
  }
}
