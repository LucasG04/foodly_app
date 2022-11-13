class FoodlyUser {
  String? id;
  List<String?>? oldPlans;
  bool? isPremium;
  DateTime? premiumExpiresAt;

  FoodlyUser({
    this.id,
    this.oldPlans,
    this.isPremium,
    this.premiumExpiresAt,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'oldPlans': oldPlans,
      'isPremium': isPremium,
      'premiumExpiresAt': premiumExpiresAt?.millisecondsSinceEpoch,
    };
  }

  factory FoodlyUser.fromMap(String id, Map<String, dynamic> map) {
    return FoodlyUser(
      id: id,
      oldPlans: List<String>.from(map['oldPlans'] as List<dynamic>),
      isPremium: map['isPremium'] as bool?,
      premiumExpiresAt: map['premiumExpiresAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['premiumExpiresAt'] as int),
    );
  }
}
