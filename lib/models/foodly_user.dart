class FoodlyUser {
  String? id;
  List<String?>? oldPlans;

  FoodlyUser({
    this.id,
    this.oldPlans,
  });

  Map<String, dynamic> toMap() {
    return {
      'oldPlans': oldPlans,
    };
  }

  factory FoodlyUser.fromMap(String id, Map<String, dynamic> map) {
    return FoodlyUser(
      id: id,
      oldPlans: List<String>.from(map['oldPlans']),
    );
  }
}
