class FoodlyUser {
  String? id;
  List<String?>? plans;
  bool? isPremium;
  bool? isPremiumGifted;
  DateTime? premiumGiftedAt;
  bool? premiumGiftedMessageShown;

  FoodlyUser({
    this.id,
    this.plans,
    this.isPremium,
    this.isPremiumGifted,
    this.premiumGiftedAt,
    this.premiumGiftedMessageShown,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'oldPlans': plans,
      'isPremium': isPremium,
      'isPremiumGifted': isPremiumGifted,
      'premiumGiftedAt': premiumGiftedAt?.millisecondsSinceEpoch,
      'premiumGiftedMessageShown': premiumGiftedMessageShown,
    };
  }

  factory FoodlyUser.fromMap(String id, Map<String, dynamic> map) {
    return FoodlyUser(
      id: id,
      plans: List<String>.from(map['oldPlans'] as List<dynamic>),
      isPremium: map['isPremium'] as bool?,
      isPremiumGifted: map['isPremiumGifted'] as bool?,
      premiumGiftedAt: map['premiumGiftedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['premiumGiftedAt'] as int)
          : null,
      premiumGiftedMessageShown: map['premiumGiftedMessageShown'] as bool?,
    );
  }
}
