class Grocery {
  String name;
  bool bought;

  Grocery({
    this.name,
    this.bought,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bought': bought ?? false,
    };
  }

  factory Grocery.fromMap(Map<String, dynamic> map) {
    if (map == null) return null;

    return Grocery(
      name: map['name'],
      bought: map['bought'],
    );
  }

  @override
  String toString() => 'Grocery(name: $name, bought: $bought)';
}
