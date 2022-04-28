import 'dart:convert';

class LunixDocx {
  bool? vertical;
  bool? colorful;
  LunixDocxPlan? plan;

  LunixDocx({this.vertical, this.colorful, this.plan});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'vertical': vertical,
      'colorful': colorful,
      'plan': plan?.toMap(),
    };
  }

  String toJson() => json.encode(toMap());
}

class LunixDocxPlan {
  String? name;
  List<LunixDocxPlanDay>? meals;

  LunixDocxPlan({this.name, this.meals});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'meals': meals?.map((x) => x.toMap()).toList(),
    };
  }
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dayName': dayName,
      'lunch': lunch,
      'dinner': dinner,
    };
  }
}
