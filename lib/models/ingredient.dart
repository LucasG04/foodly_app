class Ingredient {
  String? name;
  double? amount;
  String? unit;
  String? productGroup;
  String? group;
  int? sortKey;

  Ingredient({
    this.name,
    this.amount,
    this.unit = '',
    this.productGroup = '',
    this.group,
    this.sortKey,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'amount': amount,
      'unit': unit,
      'productGroup': productGroup,
      if (group != null) 'group': group,
      if (sortKey != null) 'sortKey': sortKey,
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
      sortKey: (map['sortKey'] as num?)?.toInt(),
    );
  }

  static const Object _absent = Object();

  Ingredient copyWith({
    Object? name = _absent,
    Object? amount = _absent,
    Object? unit = _absent,
    Object? productGroup = _absent,
    Object? group = _absent,
    Object? sortKey = _absent,
  }) {
    return Ingredient(
      name: identical(name, _absent) ? this.name : name as String?,
      amount: identical(amount, _absent) ? this.amount : amount as double?,
      unit: identical(unit, _absent) ? this.unit : unit as String?,
      productGroup: identical(productGroup, _absent) ? this.productGroup : productGroup as String?,
      group: identical(group, _absent) ? this.group : group as String?,
      sortKey: identical(sortKey, _absent) ? this.sortKey : sortKey as int?,
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

  /// Returns unique groups from [ingredients] ordered by [groupOrder],
  /// with null (ungrouped) always first, and any groups not present in
  /// [groupOrder] appended in first-appearance order.
  /// Groups that appear in [groupOrder] but have no matching ingredient
  /// are omitted.
  static List<String?> orderedGroupsSorted(
    List<Ingredient> ingredients,
    List<String>? groupOrder,
  ) {
    // Collect groups that actually have at least one ingredient
    final presentGroups = <String?>{};
    for (final i in ingredients) {
      presentGroups.add(i.group);
    }

    final result = <String?>[null];
    final appended = <String?>{null};

    // First: groups that are in groupOrder (and present)
    for (final g in (groupOrder ?? [])) {
      if (presentGroups.contains(g) && !appended.contains(g)) {
        result.add(g);
        appended.add(g);
      }
    }

    // Then: any remaining present groups in first-appearance order
    for (final ingredient in ingredients) {
      final g = ingredient.group;
      if (!appended.contains(g)) {
        result.add(g);
        appended.add(g);
      }
    }

    return result;
  }

  @override
  String toString() =>
      'Ingredient(name: $name, amount: $amount, unit: $unit, '
      'productGroup: $productGroup, group: $group, sortKey: $sortKey)';
}
