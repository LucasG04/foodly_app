import 'dart:convert';

class FoodlyNotification {
  final String title;
  final String body;
  final DateTime date;
  final String? icon;
  final String? version;

  FoodlyNotification({
    required this.title,
    required this.body,
    required this.date,
    this.icon,
    this.version,
  });

  FoodlyNotification copyWith({
    String? title,
    String? body,
    DateTime? date,
    String? icon,
    String? version,
  }) {
    return FoodlyNotification(
      title: title ?? this.title,
      body: body ?? this.body,
      date: date ?? this.date,
      icon: icon ?? this.icon,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'date': date.millisecondsSinceEpoch,
      'icon': icon,
      'version': version,
    };
  }

  factory FoodlyNotification.fromMap(Map<String, dynamic> map) {
    return FoodlyNotification(
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      icon: map['icon'],
      version: map['version'],
    );
  }

  String toJson() => json.encode(toMap());

  factory FoodlyNotification.fromJson(String source) =>
      FoodlyNotification.fromMap(json.decode(source));

  @override
  String toString() {
    return 'FoodlyNotification(title: $title, body: $body, date: $date, icon: $icon, version: $version)';
  }
}
