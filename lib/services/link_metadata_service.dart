import 'package:isar/isar.dart';
import 'package:logging/logging.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

import '../models/link_metadata.dart';
import 'storage_service.dart';

class LinkMetadataService {
  LinkMetadataService._();

  static final log = Logger('LinkMetadataService');

  static late Isar _isar;

  static Future initialize() async {
    _isar = await StorageService.getIsar();
    log.finer('initialized');
  }

  static Future<LinkMetadata?> get(String link) async {
    log.finer('Call getFromApi with $link');
    return isCached(link) ? getFromCache(link) : await getFromApi(link);
  }

  static Future<LinkMetadata?> getFromApi(String link) async {
    log.finer('Call getFromApi with $link');
    Metadata? data;
    try {
      data = await MetadataFetch.extract(link);
    } catch (e) {
      log.warning('Error while fetching metadata for $link', e);
      return null;
    }

    if (data == null) {
      return null;
    } else if (data.url == null || data.url!.isEmpty) {
      data.url = link;
    }

    final linkMetadata = _parseMetadata(data);
    await _cacheData(linkMetadata);
    return linkMetadata;
  }

  static LinkMetadata? getFromCache(String? link) {
    log.finer('Call getFromCache with $link');
    if (!isCached(link)) {
      throw Exception('Requested Link is not cached yet');
    }

    return _isar.linkMetadatas.filter().urlEqualTo(link).findFirstSync();
  }

  static bool isCached(String? link,
      [Duration cacheDuration = const Duration(days: 7)]) {
    log.finer('Call isCached with $link');
    final cachedData = _isar.linkMetadatas.filter().urlEqualTo(link).findFirstSync();
    final validCacheDate = DateTime.now().subtract(cacheDuration);
    return cachedData != null && cachedData.cachedAt!.isAfter(validCacheDate);
  }

  static Future<void> _cacheData(LinkMetadata data) async {
    log.finer('Call _cacheData with key ${data.url}');
    if (data.url == null) {
      return;
    }
    
    await _isar.writeTxn(() async {
      // Check if entry exists and update or insert
      final existing = await _isar.linkMetadatas.filter().urlEqualTo(data.url).findFirst();
      if (existing != null) {
        data.id = existing.id;
      }
      await _isar.linkMetadatas.put(data);
    }).catchError((dynamic err) {
      log.severe('ERR _cacheData with key ${data.url}');
      log.severe(err);
    });
  }

  static LinkMetadata _parseMetadata(Metadata data, [DateTime? cachedAt]) {
    cachedAt ??= DateTime.now();

    return LinkMetadata(
      url: data.url,
      image: data.image,
      title: data.title,
      description: data.description,
      cachedAt: cachedAt,
    );
  }
}
