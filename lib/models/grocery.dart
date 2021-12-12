class Grocery {
  String id;
  String name;
  double amount;
  String unit;
  String productGroup;
  bool bought;

  Grocery({
    this.id,
    this.name,
    this.amount = 0.0,
    this.unit = '',
    this.productGroup = '',
    this.bought,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'productGroup': productGroup,
      'bought': bought ?? false,
    };
  }

  factory Grocery.fromMap(String id, Map<String, dynamic> map) {
    if (map == null) return null;

    return Grocery(
      id: id,
      name: map['name'],
      amount: map['amount'],
      unit: map['unit'],
      productGroup: map['productGroup'],
      bought: map['bought'],
    );
  }

  @override
  String toString() =>
      'Grocery(id: $id, name: $name, amount: $amount, unit: $unit, bought: $bought)';
}
