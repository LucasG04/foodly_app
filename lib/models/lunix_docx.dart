class LunixDocx {
  bool? vertical;
  bool? colorful;
  LunixDocxPlan? plan;

  LunixDocx({this.vertical, this.colorful, this.plan});
}

class LunixDocxPlan {
  String? name;
  List<LunixDocxPlanDay>? meals;

  LunixDocxPlan({this.name, this.meals});
}

class LunixDocxPlanDay {
  String? dayName;
  String? lunch;
  String? dinner;

  LunixDocxPlanDay({
    this.dayName,
    this.lunch,
    this.dinner,
  });
}
