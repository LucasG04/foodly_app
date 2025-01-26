import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../models/cached_image.dart';
import '../objectbox.g.dart';
import '../utils/basic_utils.dart';
import 'storage_service.dart';

class ImageCacheManager {
  ImageCacheManager._();

  static final _log = Logger('ImageCacheManager');
  static final Dio _dio = Dio();

  static const int maxCacheSize = 50;
  static const Duration cacheExpiration = Duration(days: 7);

  static late final Store _store;
  static late final Box<CachedImage> _imageBox;

  static const int _maxConcurrentRequests = 10;
  static int _currentRequests = 0;
  static final Queue<Completer<void>> _requestQueue = Queue<Completer<void>>();

  static Future<void> initialize() async {
    _store = await openStore();
    _imageBox = _store.box<CachedImage>();
    _evictExpiredItems();
  }

  /// Fetch an image from the network with concurrency limit,
  /// and store it in the cache. Returns the image bytes or `null` on error.
  static Future<Uint8List?> loadImage(String url) async {
    final cachedData = _get(url);
    if (cachedData != null) {
      return cachedData;
    }

    await _acquireRequestSlot();

    String imageUrl = url;
    if (BasicUtils.isStorageMealImage(url)) {
      final storageUrl = await StorageService.getMealImageUrl(url);
      if (storageUrl != null) {
        imageUrl = storageUrl;
      } else {
        _log.severe('Storage URL could not be retrieved for $url');
        _releaseRequestSlot();
        return null;
      }
    }

    try {
      final response = await _dio.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 &&
          response.data != null &&
          await _isValidImage(response.data)) {
        _put(imageUrl, response.data);
        return response.data;
      } else {
        _log.warning('Failed to load image: ${response.statusCode}');
        return null;
      }
    } catch (e, st) {
      _log.severe('Error fetching image: $e', st);
      return null;
    } finally {
      _releaseRequestSlot();
    }
  }

  static Uint8List? _get(String url) {
    _evictExpiredItems(); // Periodically cleanup expired entries.

    final query = _imageBox.query(CachedImage_.url.equals(url)).build();
    final cachedImage = query.findFirst();
    query.close();

    if (cachedImage != null) {
      cachedImage.lastAccessed = DateTime.now();
      _imageBox.put(cachedImage);
      return cachedImage.imageBytes;
    }
    return null;
  }

  static void _put(String url, Uint8List imageBytes) {
    _evictExpiredItems();

    // If cache is at max capacity, evict least recently used.
    if (_imageBox.count() >= maxCacheSize) {
      _evictLRUItem();
    }

    final query = _imageBox.query(CachedImage_.url.equals(url)).build();
    var cachedImage = query.findFirst();
    query.close();

    if (cachedImage == null) {
      cachedImage = CachedImage(
        url: url,
        imageBytes: imageBytes,
        lastAccessed: DateTime.now(),
      );
    } else {
      cachedImage.imageBytes = imageBytes;
      cachedImage.lastAccessed = DateTime.now();
    }

    _imageBox.put(cachedImage);
  }

  /// Checks if the given image data is a valid image by attempting to decode it
  static Future<bool> _isValidImage(Uint8List? image) async {
    if (image == null) {
      return false;
    }

    try {
      final codec = await instantiateImageCodec(image, targetWidth: 32);
      final frameInfo = await codec.getNextFrame();
      return frameInfo.image.width > 0;
    } catch (e) {
      return false;
    }
  }

  /// Evict the least recently used item (the one with the oldest lastAccessed).
  static void _evictLRUItem() {
    final allImages = _imageBox.getAll();
    if (allImages.isNotEmpty) {
      allImages.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));
      final lru = allImages.first;
      _imageBox.remove(lru.id);
      _log.info('Evicted LRU item: ${lru.url}');
    }
  }

  /// Evict images that are older than [cacheExpiration].
  static void _evictExpiredItems() {
    final now = DateTime.now();
    final cutoff = now.subtract(cacheExpiration);

    final query = _imageBox
        .query(
            CachedImage_.lastAccessed.lessThan(cutoff.millisecondsSinceEpoch))
        .build();

    final expiredItems = query.find();
    query.close();

    for (final item in expiredItems) {
      _imageBox.remove(item.id);
    }
    if (expiredItems.isNotEmpty) {
      _log.info('Evicted ${expiredItems.length} expired items from cache.');
    }
  }

  /// Acquire a slot to perform a network request. Wait if the limit (10) is reached.
  static Future<void> _acquireRequestSlot() async {
    if (_currentRequests < _maxConcurrentRequests) {
      _currentRequests++;
    } else {
      final completer = Completer<void>();
      _requestQueue.add(completer);
      await completer.future;
    }
  }

  /// Release a slot after a network request finishes,
  /// so that the next waiting request can proceed.
  static void _releaseRequestSlot() {
    if (_requestQueue.isNotEmpty) {
      final completer = _requestQueue.removeFirst();
      completer.complete();
    } else {
      _currentRequests--;
    }
  }
}
