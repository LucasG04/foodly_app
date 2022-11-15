class FoodlyUser {
  String? id;
  List<String?>? oldPlans;
  bool? isPremium;

  FoodlyUser({
    this.id,
    this.oldPlans,
    this.isPremium,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'oldPlans': oldPlans,
      'isPremium': isPremium,
    };
  }

  factory FoodlyUser.fromMap(String id, Map<String, dynamic> map) {
    return FoodlyUser(
      id: id,
      oldPlans: List<String>.from(map['oldPlans'] as List<dynamic>),
      isPremium: map['isPremium'] as bool?,
    );
  }
}
