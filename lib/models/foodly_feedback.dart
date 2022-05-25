class FoodlyFeedback {
  String userId;
  String planId;
  String? title;
  String? email;
  String description;
  DateTime date;
  String? version;

  FoodlyFeedback({
    required this.userId,
    required this.planId,
    required this.description,
    required this.date,
    this.title,
    this.email,
    this.version,
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
    );
  }

  @override
  String toString() {
    return 'FoodlyDeedback(userId: $userId, planId: $planId, title: $title, email: $email, description: $description, date: $date, version: $version)';
  }
}
