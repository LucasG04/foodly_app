class FoodlyFeedback {
  String userId;
  String planId;
  String? title;
  String? email;
  String description;
  DateTime date;
  String? version;
  bool? isSubscribedToPremium;

  FoodlyFeedback({
    required this.userId,
    required this.planId,
    required this.description,
    required this.date,
    this.title,
    this.email,
    this.version,
    this.isSubscribedToPremium,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'planId': planId,
      'title': title,
      'email': email,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'version': version,
      'isSubscribedToPremium': isSubscribedToPremium,
    };
  }

  factory FoodlyFeedback.fromMap(Map<String, dynamic> map) {
    return FoodlyFeedback(
      userId: map['userId'] as String? ?? '',
      planId: map['planId'] as String? ?? '',
      title: map['title'] as String?,
      email: map['email'] as String?,
      description: map['description'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      version: map['version'] as String? ?? '',
      isSubscribedToPremium: map['isSubscribedToPremium'] as bool?,
    );
  }

  @override
  String toString() {
    return 'FoodlyDeedback(userId: $userId, planId: $planId, title: $title, email: $email, description: $description, date: $date, version: $version, isSubscribedToPremium: $isSubscribedToPremium)';
  }
}
