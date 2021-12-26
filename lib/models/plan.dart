import 'plan_meal.dart';

class Plan {
  String? id;
  String? name;
  String? code;
  List<PlanMeal>? meals;
  List<String>? users;
  int? hourDiffToUtc;
  bool? adFree;

  Plan({
    this.id,
    this.name,
    this.code,
    this.meals,
    this.users,
    this.hourDiffToUtc,
    this.adFree,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'users': users,
      'hourDiffToUtc': hourDiffToUtc,
      'adFree': adFree ?? false,
    };
  }

  factory Plan.fromMap(String? id, Map<String, dynamic> map) {
    return Plan(
      id: id,
      name: map['name'] as String?,
      code: map['code'] as String?,
      users: List<String>.from((map['users'] as List<dynamic>?) ?? <String>[]),
      hourDiffToUtc: map['hourDiffToUtc'] as int? ?? 0,
      adFree: (map['adFree'] as bool?) ?? false,
    );
  }

  @override
  String toString() {
    return 'Plan(id: $id, name: $name, meals: $meals, users: $users, adFree: $adFree)';
  }
}
