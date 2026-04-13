class Ingredient {
  String? name;
  double? amount;
  String? unit;
  String? productGroup;
  String? group;

  Ingredient({
    this.name,
    this.amount,
    this.unit = '',
    this.productGroup = '',
    this.group,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'amount': amount,
      'unit': unit,
      'productGroup': productGroup,
      if (group != null) 'group': group,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    map['amount'] = double.tryParse(map['amount'].toString());
    return Ingredient(
      name: map['name'] as String?,
      amount: map['amount'] as double?,
      unit: map['unit'] as String?,
      productGroup: map['productGroup'] as String?,
      group: map['group'] as String?,
    );
  }

  /// Returns the unique groups from [ingredients] in first-appearance order,
  /// with null (ungrouped) always first.
  static List<String?> orderedGroups(List<Ingredient> ingredients) {
    final seen = <String?>{null};
    final groups = <String?>[null];
    for (final ingredient in ingredients) {
      if (!seen.contains(ingredient.group)) {
        seen.add(ingredient.group);
        groups.add(ingredient.group);
      }
    }
    return groups;
  }

  @override
  String toString() =>
      'Ingredient(name: $name, amount: $amount, unit: $unit, productGroup: $productGroup, group: $group)';
}
