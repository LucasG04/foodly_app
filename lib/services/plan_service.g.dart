// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_service.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

extension GetPlanDataCollection on Isar {
  IsarCollection<PlanData> get planDatas => this.collection();
}

const PlanDataSchema = CollectionSchema(
  name: r'PlanData',
  id: 4406894842846663653,
  properties: {
    r'lastLockedCheck': PropertySchema(id: 0, name: r'lastLockedCheck', type: IsarType.long)
  },
  estimateSize: _planDataEstimateSize,
  serialize: _planDataSerialize,
  deserialize: _planDataDeserialize,
  deserializeProp: _planDataDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _planDataGetId,
  getLinks: _planDataGetLinks,
  attach: _planDataAttach,
  version: '3.1.0+1',
);

int _planDataEstimateSize(PlanData object, List<int> offsets, Map<Type, List<int>> allOffsets) { return offsets.last; }

void _planDataSerialize(PlanData object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeLong(offsets[0], object.lastLockedCheck);
}

PlanData _planDataDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = PlanData();
  object.id = id;
  object.lastLockedCheck = reader.readLongOrNull(offsets[0]);
  return object;
}

P _planDataDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readLongOrNull(offset)) as P;
    default: throw IsarError('Unknown property with id \$propertyId');
  }
}

Id _planDataGetId(PlanData object) { return object.id; }
List<IsarLinkBase<dynamic>> _planDataGetLinks(PlanData object) { return []; }
void _planDataAttach(IsarCollection<dynamic> col, Id id, PlanData object) { object.id = id; }

extension PlanDataQueryWhereSort on QueryBuilder<PlanData, PlanData, QWhere> {
  QueryBuilder<PlanData, PlanData, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) { return query.addWhereClause(const IdWhereClause.any()); });
  }
}

extension PlanDataQueryWhere on QueryBuilder<PlanData, PlanData, QWhereClause> {
  QueryBuilder<PlanData, PlanData, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) { return query.addWhereClause(IdWhereClause.between(lower: id, upper: id)); });
  }
}

extension PlanDataQueryFilter on QueryBuilder<PlanData, PlanData, QFilterCondition> {}
extension PlanDataQueryObject on QueryBuilder<PlanData, PlanData, QFilterCondition> {}
extension PlanDataQueryLinks on QueryBuilder<PlanData, PlanData, QFilterCondition> {}
extension PlanDataQuerySortBy on QueryBuilder<PlanData, PlanData, QSortBy> {}
extension PlanDataQuerySortThenBy on QueryBuilder<PlanData, PlanData, QSortThenBy> {
  QueryBuilder<PlanData, PlanData, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) { return query.addSortBy(r'id', Sort.asc); });
  }
}
extension PlanDataQueryWhereDistinct on QueryBuilder<PlanData, PlanData, QDistinct> {}
extension PlanDataQueryProperty on QueryBuilder<PlanData, PlanData, QQueryProperty> {
  QueryBuilder<PlanData, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) { return query.addPropertyName(r'id'); });
  }
}
