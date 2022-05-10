class FoodlyFeedback {
  String userId;
  String planId;
  String? title;
  String? email;
  String description;
  DateTime date;

  FoodlyFeedback({
    required this.userId,
    required this.planId,
    this.title,
    this.email,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userId': userId,
      'planId': planId,
      'title': title,
      'email': email,
      'description': description,
      'date': date.millisecondsSinceEpoch,
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
    );
  }

  @override
  String toString() {
    return 'FoodlyDeedback(userId: $userId, planId: $planId, title: $title, email: $email, description: $description, date: $date)';
  }
}
