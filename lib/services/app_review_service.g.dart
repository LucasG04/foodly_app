// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_review_service.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

extension GetAppReviewDataCollection on Isar {
  IsarCollection<AppReviewData> get appReviewDatas => this.collection();
}

const AppReviewDataSchema = CollectionSchema(
  name: r'AppReviewData',
  id: 3358606744093682214,
  properties: {
    r'groceryBought': PropertySchema(id: 0, name: r'groceryBought', type: IsarType.long),
    r'hasRated': PropertySchema(id: 1, name: r'hasRated', type: IsarType.bool),
    r'lastRequest': PropertySchema(id: 2, name: r'lastRequest', type: IsarType.dateTime),
    r'mealCreated': PropertySchema(id: 3, name: r'mealCreated', type: IsarType.long),
    r'planMeal': PropertySchema(id: 4, name: r'planMeal', type: IsarType.long)
  },
  estimateSize: _appReviewDataEstimateSize,
  serialize: _appReviewDataSerialize,
  deserialize: _appReviewDataDeserialize,
  deserializeProp: _appReviewDataDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _appReviewDataGetId,
  getLinks: _appReviewDataGetLinks,
  attach: _appReviewDataAttach,
  version: '3.1.0+1',
);

int _appReviewDataEstimateSize(AppReviewData object, List<int> offsets, Map<Type, List<int>> allOffsets) { return offsets.last; }

void _appReviewDataSerialize(AppReviewData object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeLong(offsets[0], object.groceryBought);
  writer.writeBool(offsets[1], object.hasRated);
  writer.writeDateTime(offsets[2], object.lastRequest);
  writer.writeLong(offsets[3], object.mealCreated);
  writer.writeLong(offsets[4], object.planMeal);
}

AppReviewData _appReviewDataDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = AppReviewData();
  object.groceryBought = reader.readLongOrNull(offsets[0]);
  object.hasRated = reader.readBoolOrNull(offsets[1]);
  object.id = id;
  object.lastRequest = reader.readDateTimeOrNull(offsets[2]);
  object.mealCreated = reader.readLongOrNull(offsets[3]);
  object.planMeal = reader.readLongOrNull(offsets[4]);
  return object;
}

P _appReviewDataDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readLongOrNull(offset)) as P;
    case 1: return (reader.readBoolOrNull(offset)) as P;
    case 2: return (reader.readDateTimeOrNull(offset)) as P;
    case 3: return (reader.readLongOrNull(offset)) as P;
    case 4: return (reader.readLongOrNull(offset)) as P;
    default: throw IsarError('Unknown property with id \$propertyId');
  }
}

Id _appReviewDataGetId(AppReviewData object) { return object.id; }
List<IsarLinkBase<dynamic>> _appReviewDataGetLinks(AppReviewData object) { return []; }
void _appReviewDataAttach(IsarCollection<dynamic> col, Id id, AppReviewData object) { object.id = id; }

extension AppReviewDataQueryWhereSort on QueryBuilder<AppReviewData, AppReviewData, QWhere> {
  QueryBuilder<AppReviewData, AppReviewData, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) { return query.addWhereClause(const IdWhereClause.any()); });
  }
}

extension AppReviewDataQueryWhere on QueryBuilder<AppReviewData, AppReviewData, QWhereClause> {
  QueryBuilder<AppReviewData, AppReviewData, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) { return query.addWhereClause(IdWhereClause.between(lower: id, upper: id)); });
  }
}

extension AppReviewDataQueryFilter on QueryBuilder<AppReviewData, AppReviewData, QFilterCondition> {}
extension AppReviewDataQueryObject on QueryBuilder<AppReviewData, AppReviewData, QFilterCondition> {}
extension AppReviewDataQueryLinks on QueryBuilder<AppReviewData, AppReviewData, QFilterCondition> {}
extension AppReviewDataQuerySortBy on QueryBuilder<AppReviewData, AppReviewData, QSortBy> {}
extension AppReviewDataQuerySortThenBy on QueryBuilder<AppReviewData, AppReviewData, QSortThenBy> {
  QueryBuilder<AppReviewData, AppReviewData, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) { return query.addSortBy(r'id', Sort.asc); });
  }
}
extension AppReviewDataQueryWhereDistinct on QueryBuilder<AppReviewData, AppReviewData, QDistinct> {}
extension AppReviewDataQueryProperty on QueryBuilder<AppReviewData, AppReviewData, QQueryProperty> {
  QueryBuilder<AppReviewData, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) { return query.addPropertyName(r'id'); });
  }
}
