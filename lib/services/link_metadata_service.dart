import '../models/link_metadata.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

class LinkMetadataService {
  LinkMetadataService._();

  static final log = Logger('LinkMetadataService');

  static Box<LinkMetadata> _dataBox;
  static bool _isReady = false;

  static Future initialize() async {
    _dataBox = await Hive.openBox('linkmetadata');
    _isReady = true;
    log.finer('initialized');
  }

  static bool get isReady => _isReady;

  static Future<LinkMetadata> getFromApi(String link) async {
    log.finer('Call getFromApi with $link');
    final data = await MetadataFetch.extract(link);

    if (data == null) {
      throw Exception('Metadata is not available');
    }

    final linkMetadata = _parseMetadata(data);
    await _cacheData(linkMetadata);
    return null;
    return linkMetadata;
  }

  static LinkMetadata getFromCache(String link) {
    log.finer('Call getFromCache with $link');
    if (!isCached(link)) {
      throw Exception('Requested Link is not cached yet');
    }

    return _dataBox.get(link);
  }

  static bool isCached(String link,
      [Duration cacheDuration = const Duration(days: 7)]) {
    log.finer('Call isCached with $link');
    final cachedData = _dataBox.get(link);
    final validCacheDate = DateTime.now().subtract(cacheDuration);
    return cachedData != null && cachedData.cachedAt.isAfter(validCacheDate);
  }

  static Future<void> _cacheData(LinkMetadata data) async {
    log.finer('Call _cacheData with key ${data.url}');
    await _dataBox.put(data.url, data).catchError((err) {
      log.severe('ERR _cacheData with key ${data.url}');
      log.severe(err);
    });
  }

  static _parseMetadata(Metadata data, [DateTime cachedAt]) {
    if (data == null) {
      return null;
    }
    if (cachedAt == null) {
      cachedAt = DateTime.now();
    }

    return new LinkMetadata(
      url: data.url,
      image: data.image,
      title: data.title,
      description: data.description,
      cachedAt: cachedAt,
    );
  }
}
