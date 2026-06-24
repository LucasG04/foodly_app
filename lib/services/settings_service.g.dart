// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_service.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSettingsDataCollection on Isar {
  IsarCollection<SettingsData> get settingsDatas => this.collection();
}

const SettingsDataSchema = CollectionSchema(
  name: r'SettingsData',
  id: 1905832199440658508,
  properties: {
    r'activeMealTypes': PropertySchema(id: 0, name: r'activeMealTypes', type: IsarType.longList),
    r'firstUsage': PropertySchema(id: 1, name: r'firstUsage', type: IsarType.bool),
    r'multipleMealsPerTime': PropertySchema(id: 2, name: r'multipleMealsPerTime', type: IsarType.bool),
    r'primaryColor': PropertySchema(id: 3, name: r'primaryColor', type: IsarType.long),
    r'productGroupOrder': PropertySchema(id: 4, name: r'productGroupOrder', type: IsarType.stringList),
    r'removeBoughtImmediately': PropertySchema(id: 5, name: r'removeBoughtImmediately', type: IsarType.bool),
    r'shoppingListSort': PropertySchema(id: 6, name: r'shoppingListSort', type: IsarType.long),
    r'showSuggestions': PropertySchema(id: 7, name: r'showSuggestions', type: IsarType.bool),
    r'useDevApi': PropertySchema(id: 8, name: r'useDevApi', type: IsarType.bool)
  },
  estimateSize: _settingsDataEstimateSize,
  serialize: _settingsDataSerialize,
  deserialize: _settingsDataDeserialize,
  deserializeProp: _settingsDataDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _settingsDataGetId,
  getLinks: _settingsDataGetLinks,
  attach: _settingsDataAttach,
  version: '3.1.0+1',
);

int _settingsDataEstimateSize(SettingsData object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  {
    final value = object.activeMealTypes;
    if (value != null) { bytesCount += 3 + value.length * 8; }
  }
  {
    final value = object.productGroupOrder;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
      for (var i = 0; i < value.length; i++) {
        final String element = value[i];
        bytesCount += element.length * 3;
      }
    }
  }
  return bytesCount;
}

void _settingsDataSerialize(SettingsData object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeLongList(offsets[0], object.activeMealTypes);
  writer.writeBool(offsets[1], object.firstUsage);
  writer.writeBool(offsets[2], object.multipleMealsPerTime);
  writer.writeLong(offsets[3], object.primaryColor);
  writer.writeStringList(offsets[4], object.productGroupOrder);
  writer.writeBool(offsets[5], object.removeBoughtImmediately);
  writer.writeLong(offsets[6], object.shoppingListSort);
  writer.writeBool(offsets[7], object.showSuggestions);
  writer.writeBool(offsets[8], object.useDevApi);
}

SettingsData _settingsDataDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = SettingsData();
  object.activeMealTypes = reader.readLongList(offsets[0]);
  object.firstUsage = reader.readBoolOrNull(offsets[1]);
  object.id = id;
  object.multipleMealsPerTime = reader.readBoolOrNull(offsets[2]);
  object.primaryColor = reader.readLongOrNull(offsets[3]);
  object.productGroupOrder = reader.readStringList(offsets[4]);
  object.removeBoughtImmediately = reader.readBoolOrNull(offsets[5]);
  object.shoppingListSort = reader.readLongOrNull(offsets[6]);
  object.showSuggestions = reader.readBoolOrNull(offsets[7]);
  object.useDevApi = reader.readBoolOrNull(offsets[8]);
  return object;
}

P _settingsDataDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readLongList(offset)) as P;
    case 1: return (reader.readBoolOrNull(offset)) as P;
    case 2: return (reader.readBoolOrNull(offset)) as P;
    case 3: return (reader.readLongOrNull(offset)) as P;
    case 4: return (reader.readStringList(offset)) as P;
    case 5: return (reader.readBoolOrNull(offset)) as P;
    case 6: return (reader.readLongOrNull(offset)) as P;
    case 7: return (reader.readBoolOrNull(offset)) as P;
    case 8: return (reader.readBoolOrNull(offset)) as P;
    default: throw IsarError('Unknown property with id \$propertyId');
  }
}

Id _settingsDataGetId(SettingsData object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _settingsDataGetLinks(SettingsData object) {
  return [];
}

void _settingsDataAttach(IsarCollection<dynamic> col, Id id, SettingsData object) {
  object.id = id;
}

extension SettingsDataQueryWhereSort on QueryBuilder<SettingsData, SettingsData, QWhere> {
  QueryBuilder<SettingsData, SettingsData, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SettingsDataQueryWhere on QueryBuilder<SettingsData, SettingsData, QWhereClause> {
  QueryBuilder<SettingsData, SettingsData, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SettingsData, SettingsData, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IdWhereClause.lessThan(upper: id, includeUpper: false))
            .addWhereClause(IdWhereClause.greaterThan(lower: id, includeLower: false));
      } else {
        return query
            .addWhereClause(IdWhereClause.greaterThan(lower: id, includeLower: false))
            .addWhereClause(IdWhereClause.lessThan(upper: id, includeUpper: false));
      }
    });
  }

  QueryBuilder<SettingsData, SettingsData, QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.greaterThan(lower: id, includeLower: include));
    });
  }

  QueryBuilder<SettingsData, SettingsData, QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.lessThan(upper: id, includeUpper: include));
    });
  }

  QueryBuilder<SettingsData, SettingsData, QAfterWhereClause> idBetween(Id lowerId, Id upperId, {bool includeLower = true, bool includeUpper = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: lowerId, includeLower: includeLower, upper: upperId, includeUpper: includeUpper));
    });
  }
}

extension SettingsDataQueryFilter on QueryBuilder<SettingsData, SettingsData, QFilterCondition> {}

extension SettingsDataQueryObject on QueryBuilder<SettingsData, SettingsData, QFilterCondition> {}

extension SettingsDataQueryLinks on QueryBuilder<SettingsData, SettingsData, QFilterCondition> {}

extension SettingsDataQuerySortBy on QueryBuilder<SettingsData, SettingsData, QSortBy> {}

extension SettingsDataQuerySortThenBy on QueryBuilder<SettingsData, SettingsData, QSortThenBy> {
  QueryBuilder<SettingsData, SettingsData, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SettingsData, SettingsData, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }
}

extension SettingsDataQueryWhereDistinct on QueryBuilder<SettingsData, SettingsData, QDistinct> {}

extension SettingsDataQueryProperty on QueryBuilder<SettingsData, SettingsData, QQueryProperty> {
  QueryBuilder<SettingsData, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }
}
