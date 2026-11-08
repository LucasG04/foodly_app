/// An AI app connected to the user's account via OAuth.
class McpConnection {
  final String id;
  final String clientName;
  final DateTime createdAt;
  final DateTime lastUsedAt;

  const McpConnection({
    required this.id,
    required this.clientName,
    required this.createdAt,
    required this.lastUsedAt,
  });

  factory McpConnection.fromMap(Map<String, dynamic> map) {
    DateTime ms(String key) =>
        DateTime.fromMillisecondsSinceEpoch((map[key] as num).toInt());
    return McpConnection(
      id: map['id'] as String,
      clientName: map['clientName'] as String,
      createdAt: ms('createdAt'),
      lastUsedAt: ms('lastUsedAt'),
    );
  }
}
