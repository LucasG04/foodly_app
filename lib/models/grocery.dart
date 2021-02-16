class Grocery {
  String id;
  String name;
  String amount;
  bool bought;

  Grocery({
    this.id,
    this.name,
    this.amount,
    this.bought,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount ?? '',
      'bought': bought ?? false,
    };
  }

  factory Grocery.fromMap(String id, Map<String, dynamic> map) {
    if (map == null) return null;

    return Grocery(
      id: id,
      name: map['name'],
      amount: map['amount'] ?? '',
      bought: map['bought'],
    );
  }

  @override
  String toString() =>
      'Grocery(id: $id, name: $name, amount: $amount, bought: $bought)';
}
