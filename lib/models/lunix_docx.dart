import 'dart:convert';

class LunixDocx {
  bool vertical;
  String type;
  bool fillBreakfast;
  String? breakfastTranslation;
  String? lunchTranslation;
  String? dinnerTranslation;
  LunixDocxPlan? plan;

  LunixDocx({
    this.plan,
    this.vertical = false,
    this.type = 'color',
    this.fillBreakfast = false,
    this.breakfastTranslation,
    this.lunchTranslation,
    this.dinnerTranslation,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'vertical': vertical,
      'type': type,
      'fillBreakfast': fillBreakfast,
      'breakfastTranslation': breakfastTranslation,
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
  String? breakfast;
  String? lunch;
  String? dinner;

  LunixDocxPlanDay({
    this.dayName,
    this.breakfast,
    this.lunch,
    this.dinner,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'dayName': dayName,
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
    };
  }
}
