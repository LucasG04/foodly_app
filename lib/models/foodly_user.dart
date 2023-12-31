import 'foodly_user_role.dart';

class FoodlyUser {
  String? id;
  List<String?>? plans;
  bool? isPremium;
  bool? isPremiumGifted;
  DateTime? premiumGiftedAt;
  int? premiumGiftedMonths;
  bool? premiumGiftedMessageShown;
  FoodlyUserRole role;

  FoodlyUser({
    this.id,
    this.plans,
    this.isPremium,
    this.isPremiumGifted,
    this.premiumGiftedAt,
    this.premiumGiftedMonths,
    this.premiumGiftedMessageShown,
    this.role = FoodlyUserRole.user,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'oldPlans': plans,
      'isPremium': isPremium,
      'isPremiumGifted': isPremiumGifted,
      'premiumGiftedAt': premiumGiftedAt?.millisecondsSinceEpoch,
      'premiumGiftedMonths': premiumGiftedMonths,
      'premiumGiftedMessageShown': premiumGiftedMessageShown,
      'role': role.toString(),
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
      premiumGiftedMonths: map['premiumGiftedMonths'] as int?,
      role: FoodlyUserRole.values.firstWhere(
        (e) => e.toString() == map['role'],
        orElse: () => FoodlyUserRole.user,
      ),
    );
  }
}
