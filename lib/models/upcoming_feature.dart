import 'dart:convert';

class UpcomingFeature {
  String id;
  String title;
  String body;
  bool inProgress;
  bool isPremium;
  List<String> votes;

  UpcomingFeature({
    required this.id,
    required this.title,
    required this.body,
    required this.inProgress,
    required this.isPremium,
    required this.votes,
  });

  UpcomingFeature copyWith({
    String? id,
    String? title,
    String? body,
    bool? inProgress,
    bool? isPremium,
    List<String>? votes,
  }) {
    return UpcomingFeature(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      inProgress: inProgress ?? this.inProgress,
      isPremium: isPremium ?? this.isPremium,
      votes: votes ?? this.votes,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'body': body,
      'inProgress': inProgress,
      'isPremium': isPremium,
      'votes': votes,
    };
  }

  factory UpcomingFeature.fromMap(Map<String, dynamic> map) {
    return UpcomingFeature(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      inProgress: map['inProgress'] as bool? ?? false,
      isPremium: map['isPremium'] as bool? ?? false,
      votes: List<String>.from(map['votes'] as List<dynamic>? ?? <String>[]),
    );
  }

  String toJson() => json.encode(toMap());

  factory UpcomingFeature.fromJson(String source) =>
      UpcomingFeature.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'UpcomingFeature(id: $id, title: $title, body: $body, inProgress: $inProgress, isPremium: $isPremium, votes: $votes)';
  }
}
