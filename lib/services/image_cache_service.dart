import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  ImageCacheService._();
  static final _log = Logger('ImageCacheService');
  static late HiveCacheStore _hiveCacheStore;
  static bool _isReady = false;

  static Future initialize() async {
    _log.fine('Initializing');
    final tempDir = await getTemporaryDirectory();
    _hiveCacheStore = HiveCacheStore(tempDir.path);
    _isReady = true;
  }

  static bool get isReady => _isReady;

  static HiveCacheStore get hiveCacheStore => _hiveCacheStore;
}
