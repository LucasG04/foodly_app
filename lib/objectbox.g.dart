// GENERATED CODE - DO NOT MODIFY BY HAND
// This code was generated by ObjectBox. To update it run the generator again
// with `dart run build_runner build`.
// See also https://docs.objectbox.io/getting-started#generate-objectbox-code

// ignore_for_file: camel_case_types, depend_on_referenced_packages
// coverage:ignore-file

import 'dart:typed_data';

import 'package:flat_buffers/flat_buffers.dart' as fb;
import 'package:objectbox/internal.dart'
    as obx_int; // generated code can access "internal" functionality
import 'package:objectbox/objectbox.dart' as obx;
import 'package:objectbox_flutter_libs/objectbox_flutter_libs.dart';

import 'models/cached_image.dart';

export 'package:objectbox/objectbox.dart'; // so that callers only have to import this file

final _entities = <obx_int.ModelEntity>[
  obx_int.ModelEntity(
      id: const obx_int.IdUid(1, 1136354454956549761),
      name: 'CachedImage',
      lastPropertyId: const obx_int.IdUid(4, 9187837461954906512),
      flags: 0,
      properties: <obx_int.ModelProperty>[
        obx_int.ModelProperty(
            id: const obx_int.IdUid(1, 2019063739796046261),
            name: 'id',
            type: 6,
            flags: 1),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(2, 3198055306128636876),
            name: 'url',
            type: 9,
            flags: 34848,
            indexId: const obx_int.IdUid(1, 468106563215755159)),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(3, 2895976490973181273),
            name: 'imageBytes',
            type: 23,
            flags: 0),
        obx_int.ModelProperty(
            id: const obx_int.IdUid(4, 9187837461954906512),
            name: 'lastAccessed',
            type: 10,
            flags: 0)
      ],
      relations: <obx_int.ModelRelation>[],
      backlinks: <obx_int.ModelBacklink>[])
];

/// Shortcut for [obx.Store.new] that passes [getObjectBoxModel] and for Flutter
/// apps by default a [directory] using `defaultStoreDirectory()` from the
/// ObjectBox Flutter library.
///
/// Note: for desktop apps it is recommended to specify a unique [directory].
///
/// See [obx.Store.new] for an explanation of all parameters.
///
/// For Flutter apps, also calls `loadObjectBoxLibraryAndroidCompat()` from
/// the ObjectBox Flutter library to fix loading the native ObjectBox library
/// on Android 6 and older.
Future<obx.Store> openStore(
    {String? directory,
    int? maxDBSizeInKB,
    int? maxDataSizeInKB,
    int? fileMode,
    int? maxReaders,
    bool queriesCaseSensitiveDefault = true,
    String? macosApplicationGroup}) async {
  await loadObjectBoxLibraryAndroidCompat();
  return obx.Store(getObjectBoxModel(),
      directory: directory ?? (await defaultStoreDirectory()).path,
      maxDBSizeInKB: maxDBSizeInKB,
      maxDataSizeInKB: maxDataSizeInKB,
      fileMode: fileMode,
      maxReaders: maxReaders,
      queriesCaseSensitiveDefault: queriesCaseSensitiveDefault,
      macosApplicationGroup: macosApplicationGroup);
}

/// Returns the ObjectBox model definition for this project for use with
/// [obx.Store.new].
obx_int.ModelDefinition getObjectBoxModel() {
  final model = obx_int.ModelInfo(
      entities: _entities,
      lastEntityId: const obx_int.IdUid(1, 1136354454956549761),
      lastIndexId: const obx_int.IdUid(1, 468106563215755159),
      lastRelationId: const obx_int.IdUid(0, 0),
      lastSequenceId: const obx_int.IdUid(0, 0),
      retiredEntityUids: const [],
      retiredIndexUids: const [],
      retiredPropertyUids: const [],
      retiredRelationUids: const [],
      modelVersion: 5,
      modelVersionParserMinimum: 5,
      version: 1);

  final bindings = <Type, obx_int.EntityDefinition>{
    CachedImage: obx_int.EntityDefinition<CachedImage>(
        model: _entities[0],
        toOneRelations: (CachedImage object) => [],
        toManyRelations: (CachedImage object) => {},
        getId: (CachedImage object) => object.id,
        setId: (CachedImage object, int id) {
          object.id = id;
        },
        objectToFB: (CachedImage object, fb.Builder fbb) {
          final urlOffset = fbb.writeString(object.url);
          final imageBytesOffset = fbb.writeListInt8(object.imageBytes);
          fbb.startTable(5);
          fbb.addInt64(0, object.id);
          fbb.addOffset(1, urlOffset);
          fbb.addOffset(2, imageBytesOffset);
          fbb.addInt64(3, object.lastAccessed.millisecondsSinceEpoch);
          fbb.finish(fbb.endTable());
          return object.id;
        },
        objectFromFB: (obx.Store store, ByteData fbData) {
          final buffer = fb.BufferContext(fbData);
          final rootOffset = buffer.derefObject(0);
          final idParam =
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 4, 0);
          final urlParam = const fb.StringReader(asciiOptimization: true)
              .vTableGet(buffer, rootOffset, 6, '');
          final imageBytesParam = const fb.Uint8ListReader(lazy: false)
              .vTableGet(buffer, rootOffset, 8, Uint8List(0)) as Uint8List;
          final lastAccessedParam = DateTime.fromMillisecondsSinceEpoch(
              const fb.Int64Reader().vTableGet(buffer, rootOffset, 10, 0));
          final object = CachedImage(
              id: idParam,
              url: urlParam,
              imageBytes: imageBytesParam,
              lastAccessed: lastAccessedParam);

          return object;
        })
  };

  return obx_int.ModelDefinition(model, bindings);
}

/// [CachedImage] entity fields to define ObjectBox queries.
class CachedImage_ {
  /// See [CachedImage.id].
  static final id =
      obx.QueryIntegerProperty<CachedImage>(_entities[0].properties[0]);

  /// See [CachedImage.url].
  static final url =
      obx.QueryStringProperty<CachedImage>(_entities[0].properties[1]);

  /// See [CachedImage.imageBytes].
  static final imageBytes =
      obx.QueryByteVectorProperty<CachedImage>(_entities[0].properties[2]);

  /// See [CachedImage.lastAccessed].
  static final lastAccessed =
      obx.QueryDateProperty<CachedImage>(_entities[0].properties[3]);
}
