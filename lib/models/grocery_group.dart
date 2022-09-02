class GroceryGroup {
  int id;
  String name;

  GroceryGroup({
    required this.id,
    required this.name,
  });

  GroceryGroup copyWith({
    int? id,
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
    final id = int.tryParse(map['id'].toString()) ?? -1;
    return GroceryGroup(
      id: id,
      name: map['name'] as String? ?? '',
    );
  }

  @override
  String toString() => 'GroceryGroup(id: $id, name: $name)';
}
