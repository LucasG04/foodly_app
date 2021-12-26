class Grocery {
  String? id;
  String? name;
  double? amount;
  String? unit;
  String? productGroup;
  bool? bought;

  Grocery({
    this.id,
    this.name,
    this.amount = 0.0,
    this.unit = '',
    this.productGroup = '',
    this.bought,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'amount': amount,
      'unit': unit,
      'productGroup': productGroup,
      'bought': bought ?? false,
    };
  }

  factory Grocery.fromMap(String id, Map<String, dynamic> map) {
    return Grocery(
      id: id,
      name: map['name'] as String?,
      amount: map['amount'] as double?,
      unit: map['unit'] as String?,
      productGroup: map['productGroup'] as String?,
      bought: map['bought'] as bool?,
    );
  }

  @override
  String toString() =>
      'Grocery(id: $id, name: $name, amount: $amount, unit: $unit, bought: $bought)';
}
