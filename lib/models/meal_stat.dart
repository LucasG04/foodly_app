class MealStat {
  String? id;
  String mealId;
  DateTime? lastTimePlanned;
  int? plannedCount;

  MealStat({
    this.id,
    required this.mealId,
    this.lastTimePlanned,
    this.plannedCount,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'mealId': mealId,
      'lastTimePlanned': lastTimePlanned!.millisecondsSinceEpoch,
      'plannedCount': plannedCount,
    };
  }

  factory MealStat.fromMap(String id, Map<String, dynamic> map) {
    return MealStat(
      id: id,
      mealId: map['mealId'] as String,
      lastTimePlanned:
          DateTime.fromMillisecondsSinceEpoch(map['lastTimePlanned'] as int),
      plannedCount: map['plannedCount'] as int?,
    );
  }

  @override
  String toString() {
    return 'MealStat(id: $id, mealId: $mealId, lastTimePlanned: $lastTimePlanned, plannedCount: $plannedCount)';
  }
}
