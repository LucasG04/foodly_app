// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'version_service.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

extension GetVersionDataCollection on Isar {
  IsarCollection<VersionData> get versionDatas => this.collection();
}

const VersionDataSchema = CollectionSchema(
  name: r'VersionData',
  id: 8277519442927502931,
  properties: {
    r'lastCheckedForUpdate': PropertySchema(id: 0, name: r'lastCheckedForUpdate', type: IsarType.dateTime),
    r'lastCheckedVersion': PropertySchema(id: 1, name: r'lastCheckedVersion', type: IsarType.string)
  },
  estimateSize: _versionDataEstimateSize,
  serialize: _versionDataSerialize,
  deserialize: _versionDataDeserialize,
  deserializeProp: _versionDataDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _versionDataGetId,
  getLinks: _versionDataGetLinks,
  attach: _versionDataAttach,
  version: '3.1.0+1',
);

int _versionDataEstimateSize(VersionData object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  {
    final value = object.lastCheckedVersion;
    if (value != null) { bytesCount += 3 + value.length * 3; }
  }
  return bytesCount;
}

void _versionDataSerialize(VersionData object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeDateTime(offsets[0], object.lastCheckedForUpdate);
  writer.writeString(offsets[1], object.lastCheckedVersion);
}

VersionData _versionDataDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = VersionData();
  object.id = id;
  object.lastCheckedForUpdate = reader.readDateTimeOrNull(offsets[0]);
  object.lastCheckedVersion = reader.readStringOrNull(offsets[1]);
  return object;
}

P _versionDataDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readDateTimeOrNull(offset)) as P;
    case 1: return (reader.readStringOrNull(offset)) as P;
    default: throw IsarError('Unknown property with id \$propertyId');
  }
}

Id _versionDataGetId(VersionData object) { return object.id; }
List<IsarLinkBase<dynamic>> _versionDataGetLinks(VersionData object) { return []; }
void _versionDataAttach(IsarCollection<dynamic> col, Id id, VersionData object) { object.id = id; }

extension VersionDataQueryWhereSort on QueryBuilder<VersionData, VersionData, QWhere> {
  QueryBuilder<VersionData, VersionData, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) { return query.addWhereClause(const IdWhereClause.any()); });
  }
}

extension VersionDataQueryWhere on QueryBuilder<VersionData, VersionData, QWhereClause> {
  QueryBuilder<VersionData, VersionData, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) { return query.addWhereClause(IdWhereClause.between(lower: id, upper: id)); });
  }
}

extension VersionDataQueryFilter on QueryBuilder<VersionData, VersionData, QFilterCondition> {}
extension VersionDataQueryObject on QueryBuilder<VersionData, VersionData, QFilterCondition> {}
extension VersionDataQueryLinks on QueryBuilder<VersionData, VersionData, QFilterCondition> {}
extension VersionDataQuerySortBy on QueryBuilder<VersionData, VersionData, QSortBy> {}
extension VersionDataQuerySortThenBy on QueryBuilder<VersionData, VersionData, QSortThenBy> {
  QueryBuilder<VersionData, VersionData, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) { return query.addSortBy(r'id', Sort.asc); });
  }
}
extension VersionDataQueryWhereDistinct on QueryBuilder<VersionData, VersionData, QDistinct> {}
extension VersionDataQueryProperty on QueryBuilder<VersionData, VersionData, QQueryProperty> {
  QueryBuilder<VersionData, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) { return query.addPropertyName(r'id'); });
  }
}
