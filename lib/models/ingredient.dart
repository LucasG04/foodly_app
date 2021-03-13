import 'package:flutter/foundation.dart';

class Ingredient {
  String name;
  double amount;
  String unit;
  String productGroup;

  Ingredient({
    this.name,
    this.amount,
    this.unit = '',
    this.productGroup = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'productGroup': productGroup,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      name: map['name'],
      amount: map['amount'],
      unit: map['unit'],
      productGroup: map['productGroup'],
    );
  }

  @override
  String toString() =>
      'Ingredient(name: $name, amount: $amount, unit: $unit, productGroup: $productGroup)';
}
