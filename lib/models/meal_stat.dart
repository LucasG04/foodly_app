class MealStat {
  String id;
  String mealId;
  DateTime lastTimePlanned;
  int plannedCount;

  MealStat({
    this.id,
    this.mealId,
    this.lastTimePlanned,
    this.plannedCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'mealId': mealId,
      'lastTimePlanned': lastTimePlanned.millisecondsSinceEpoch,
      'plannedCount': plannedCount,
    };
  }

  factory MealStat.fromMap(String id, Map<String, dynamic> map) {
    return MealStat(
      id: id,
      mealId: map['mealId'],
      lastTimePlanned:
          DateTime.fromMillisecondsSinceEpoch(map['lastTimePlanned']),
      plannedCount: map['plannedCount'],
    );
  }

  @override
  String toString() {
    return 'MealStat(id: $id, mealId: $mealId, lastTimePlanned: $lastTimePlanned, plannedCount: $plannedCount)';
  }
}
