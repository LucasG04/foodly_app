class GroceryGroup {
  String id;
  String name;

  GroceryGroup({
    required this.id,
    required this.name,
  });

  GroceryGroup copyWith({
    String? id,
    String? name,
  }) {
    return GroceryGroup(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
    };
  }

  factory GroceryGroup.fromMap(Map<String, dynamic> map) {
    return GroceryGroup(
      id: map['id'].toString(),
      name: map['name'] as String? ?? '',
    );
  }

  factory GroceryGroup.fromApi(Map<String, dynamic> map) {
    return GroceryGroup(
      id: map['groupId'].toString(),
      name: map['group'] as String? ?? '',
    );
  }

  @override
  String toString() => 'GroceryGroup(id: $id, name: $name)';
}
