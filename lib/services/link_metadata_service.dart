import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

import '../models/link_metadata.dart';

class LinkMetadataService {
  LinkMetadataService._();

  static final log = Logger('LinkMetadataService');

  static late Box<LinkMetadata> _dataBox;
  static bool _isReady = false;

  static Future initialize() async {
    _dataBox = await Hive.openBox('linkmetadata');
    _isReady = true;
    log.finer('initialized');
  }

  static bool get isReady => _isReady;

  static Future<LinkMetadata?> get(String link) async {
    log.finer('Call getFromApi with $link');
    return isCached(link) ? getFromCache(link) : await getFromApi(link);
  }

  static Future<LinkMetadata?> getFromApi(String link) async {
    log.finer('Call getFromApi with $link');
    final data = await MetadataFetch.extract(link);

    if (data == null) {
      throw Exception('Metadata is not available');
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

    return _dataBox.get(link);
  }

  static bool isCached(String? link,
      [Duration cacheDuration = const Duration(days: 7)]) {
    log.finer('Call isCached with $link');
    final cachedData = _dataBox.get(link);
    final validCacheDate = DateTime.now().subtract(cacheDuration);
    return cachedData != null && cachedData.cachedAt!.isAfter(validCacheDate);
  }

  static Future<void> _cacheData(LinkMetadata data) async {
    log.finer('Call _cacheData with key ${data.url}');
    await _dataBox.put(data.url, data).catchError((dynamic err) {
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
