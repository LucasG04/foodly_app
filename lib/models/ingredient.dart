class Ingredient {
  String? name;
  double? amount;
  String? unit;
  String? productGroup;

  Ingredient({
    this.name,
    this.amount,
    this.unit = '',
    this.productGroup = '',
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'amount': amount,
      'unit': unit,
      'productGroup': productGroup,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    map['amount'] = double.parse(map['amount'].toString());
    return Ingredient(
      name: map['name'] as String?,
      amount: map['amount'] as double?,
      unit: map['unit'] as String?,
      productGroup: map['productGroup'] as String?,
    );
  }

  @override
  String toString() =>
      'Ingredient(name: $name, amount: $amount, unit: $unit, productGroup: $productGroup)';
}
