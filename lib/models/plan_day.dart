class PlanDay {
  DateTime? date;
  List<String>? lunch;
  List<String>? dinner;

  PlanDay({
    this.date,
    this.lunch,
    this.dinner,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'date': date?.millisecondsSinceEpoch,
      'lunch': lunch,
      'dinner': dinner,
    };
  }

  factory PlanDay.fromMap(Map<String, dynamic> map) {
    return PlanDay(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      lunch: map['lunch'] as List<String>?,
      dinner: map['dinner'] as List<String>?,
    );
  }

  @override
  String toString() => 'PlanDay(date: $date, lunch: $lunch, dinner: $dinner)';
}
