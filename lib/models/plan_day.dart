class PlanDay {
  DateTime date;
  List<String> lunch;
  String dinner;

  PlanDay({
    this.date,
    this.lunch,
    this.dinner,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date?.millisecondsSinceEpoch,
      'lunch': lunch,
      'dinner': dinner,
    };
  }

  factory PlanDay.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return PlanDay(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      lunch: map['lunch'],
      dinner: map['dinner'],
    );
  }

  @override
  String toString() => 'PlanDay(date: $date, lunch: $lunch, dinner: $dinner)';
}
