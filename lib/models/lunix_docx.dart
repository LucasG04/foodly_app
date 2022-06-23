import 'dart:convert';

class LunixDocx {
  bool vertical;
  String type;
  String? lunchTranslation;
  String? dinnerTranslation;
  LunixDocxPlan? plan;

  LunixDocx({
    this.plan,
    this.vertical = false,
    this.type = 'color',
    this.lunchTranslation,
    this.dinnerTranslation,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'vertical': vertical,
      'type': type,
      'lunchTranslation': lunchTranslation,
      'dinnerTranslation': dinnerTranslation,
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
