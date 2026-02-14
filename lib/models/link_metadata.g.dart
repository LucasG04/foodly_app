// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'link_metadata.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLinkMetadataCollection on Isar {
  IsarCollection<LinkMetadata> get linkMetadatas => this.collection();
}

const LinkMetadataSchema = CollectionSchema(
  name: r'LinkMetadata',
  id: 6906965577551648337,
  properties: {
    r'cachedAt': PropertySchema(id: 0, name: r'cachedAt', type: IsarType.dateTime),
    r'description': PropertySchema(id: 1, name: r'description', type: IsarType.string),
    r'image': PropertySchema(id: 2, name: r'image', type: IsarType.string),
    r'title': PropertySchema(id: 3, name: r'title', type: IsarType.string),
    r'url': PropertySchema(id: 4, name: r'url', type: IsarType.string)
  },
  estimateSize: _linkMetadataEstimateSize,
  serialize: _linkMetadataSerialize,
  deserialize: _linkMetadataDeserialize,
  deserializeProp: _linkMetadataDeserializeProp,
  idName: r'id',
  indexes: {
    r'url': IndexSchema(
      id: 5894041028975437863,
      name: r'url',
      unique: true,
      replace: false,
      properties: [IndexPropertySchema(name: r'url', type: IndexType.hash, caseSensitive: true)],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _linkMetadataGetId,
  getLinks: _linkMetadataGetLinks,
  attach: _linkMetadataAttach,
  version: '3.1.0+1',
);

int _linkMetadataEstimateSize(LinkMetadata object, List<int> offsets, Map<Type, List<int>> allOffsets) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) { bytesCount += 3 + value.length * 3; }
  }
  {
    final value = object.image;
    if (value != null) { bytesCount += 3 + value.length * 3; }
  }
  {
    final value = object.title;
    if (value != null) { bytesCount += 3 + value.length * 3; }
  }
  {
    final value = object.url;
    if (value != null) { bytesCount += 3 + value.length * 3; }
  }
  return bytesCount;
}

void _linkMetadataSerialize(LinkMetadata object, IsarWriter writer, List<int> offsets, Map<Type, List<int>> allOffsets) {
  writer.writeDateTime(offsets[0], object.cachedAt);
  writer.writeString(offsets[1], object.description);
  writer.writeString(offsets[2], object.image);
  writer.writeString(offsets[3], object.title);
  writer.writeString(offsets[4], object.url);
}

LinkMetadata _linkMetadataDeserialize(Id id, IsarReader reader, List<int> offsets, Map<Type, List<int>> allOffsets) {
  final object = LinkMetadata(
    cachedAt: reader.readDateTimeOrNull(offsets[0]),
    description: reader.readStringOrNull(offsets[1]),
    image: reader.readStringOrNull(offsets[2]),
    title: reader.readStringOrNull(offsets[3]),
    url: reader.readStringOrNull(offsets[4]),
  );
  object.id = id;
  return object;
}

P _linkMetadataDeserializeProp<P>(IsarReader reader, int propertyId, int offset, Map<Type, List<int>> allOffsets) {
  switch (propertyId) {
    case 0: return (reader.readDateTimeOrNull(offset)) as P;
    case 1: return (reader.readStringOrNull(offset)) as P;
    case 2: return (reader.readStringOrNull(offset)) as P;
    case 3: return (reader.readStringOrNull(offset)) as P;
    case 4: return (reader.readStringOrNull(offset)) as P;
    default: throw IsarError('Unknown property with id $propertyId');
  }
}

Id _linkMetadataGetId(LinkMetadata object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _linkMetadataGetLinks(LinkMetadata object) {
  return [];
}

void _linkMetadataAttach(IsarCollection<dynamic> col, Id id, LinkMetadata object) {
  object.id = id;
}

extension LinkMetadataQueryWhereSort on QueryBuilder<LinkMetadata, LinkMetadata, QWhere> {
  QueryBuilder<LinkMetadata, LinkMetadata, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LinkMetadataQueryWhere on QueryBuilder<LinkMetadata, LinkMetadata, QWhereClause> {
  QueryBuilder<LinkMetadata, LinkMetadata, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterWhereClause> idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.greaterThan(lower: id, includeLower: include));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterWhereClause> idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.lessThan(upper: id, includeUpper: include));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterWhereClause> idBetween(Id lowerId, Id upperId, {bool includeLower = true, bool includeUpper = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: lowerId, includeLower: includeLower, upper: upperId, includeUpper: includeUpper));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterWhereClause> urlEqualTo(String? url) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(indexName: r'url', value: [url]));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterWhereClause> urlNotEqualTo(String? url) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'url', lower: [], upper: [url], includeUpper: false))
            .addWhereClause(IndexWhereClause.between(indexName: r'url', lower: [url], includeLower: false, upper: []));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(indexName: r'url', lower: [url], includeLower: false, upper: []))
            .addWhereClause(IndexWhereClause.between(indexName: r'url', lower: [], upper: [url], includeUpper: false));
      }
    });
  }
}

extension LinkMetadataQueryFilter on QueryBuilder<LinkMetadata, LinkMetadata, QFilterCondition> {
  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> cachedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'cachedAt'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> cachedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'cachedAt'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> cachedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'cachedAt', value: value));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> cachedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'cachedAt', value: value));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> cachedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'cachedAt', value: value));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> cachedAtBetween(DateTime? lower, DateTime? upper, {bool includeLower = true, bool includeUpper = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(property: r'cachedAt', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'description'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'description'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'description', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionGreaterThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'description', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionLessThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'description', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionBetween(String? lower, String? upper, {bool includeLower = true, bool includeUpper = true, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(property: r'description', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'description', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'description', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'description', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'description', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'description', value: ''));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'description', value: ''));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'id', value: value));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'id', value: value));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'id', value: value));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> idBetween(Id lower, Id upper, {bool includeLower = true, bool includeUpper = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(property: r'id', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'image'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'image'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'image', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageGreaterThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'image', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageLessThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'image', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageBetween(String? lower, String? upper, {bool includeLower = true, bool includeUpper = true, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(property: r'image', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'image', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'image', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'image', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'image', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'image', value: ''));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> imageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'image', value: ''));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'title'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'title'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'title', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleGreaterThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'title', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleLessThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'title', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleBetween(String? lower, String? upper, {bool includeLower = true, bool includeUpper = true, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(property: r'title', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'title', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'title', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'title', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'title', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'title', value: ''));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'title', value: ''));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(property: r'url'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(property: r'url'));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'url', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlGreaterThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(include: include, property: r'url', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlLessThan(String? value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(include: include, property: r'url', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlBetween(String? lower, String? upper, {bool includeLower = true, bool includeUpper = true, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(property: r'url', lower: lower, includeLower: includeLower, upper: upper, includeUpper: includeUpper, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(property: r'url', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(property: r'url', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(property: r'url', value: value, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(property: r'url', wildcard: pattern, caseSensitive: caseSensitive));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(property: r'url', value: ''));
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterFilterCondition> urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(property: r'url', value: ''));
    });
  }
}

extension LinkMetadataQueryObject on QueryBuilder<LinkMetadata, LinkMetadata, QFilterCondition> {}

extension LinkMetadataQueryLinks on QueryBuilder<LinkMetadata, LinkMetadata, QFilterCondition> {}

extension LinkMetadataQuerySortBy on QueryBuilder<LinkMetadata, LinkMetadata, QSortBy> {
  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension LinkMetadataQuerySortThenBy on QueryBuilder<LinkMetadata, LinkMetadata, QSortThenBy> {
  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByCachedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cachedAt', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByImage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByImageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'image', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }
}

extension LinkMetadataQueryWhereDistinct on QueryBuilder<LinkMetadata, LinkMetadata, QDistinct> {
  QueryBuilder<LinkMetadata, LinkMetadata, QDistinct> distinctByCachedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cachedAt');
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QDistinct> distinctByDescription({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QDistinct> distinctByImage({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'image', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QDistinct> distinctByTitle({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LinkMetadata, LinkMetadata, QDistinct> distinctByUrl({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }
}

extension LinkMetadataQueryProperty on QueryBuilder<LinkMetadata, LinkMetadata, QQueryProperty> {
  QueryBuilder<LinkMetadata, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LinkMetadata, DateTime?, QQueryOperations> cachedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cachedAt');
    });
  }

  QueryBuilder<LinkMetadata, String?, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<LinkMetadata, String?, QQueryOperations> imageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'image');
    });
  }

  QueryBuilder<LinkMetadata, String?, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<LinkMetadata, String?, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }
}
