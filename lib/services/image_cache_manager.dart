import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import '../models/cached_image.dart';

class ImageCacheManager {
  ImageCacheManager._();

  static final _log = Logger('ImageCacheManager');
  static const int maxCacheSize = 50;
  static const Duration cacheExpiration = Duration(days: 7);
  static late Box<CachedImage> imageCache;

  static Future<void> initialize() async {
    try {
      imageCache = await Hive.openBox<CachedImage>('imageCache3');
    } catch (e) {
      _log.severe('Could not open imageCache box', e);
    } finally {
      imageCache = await Hive.openBox<CachedImage>('imageCache3');
    }
  }

  static Uint8List? get(String url) {
    final key = _toKey(url);
    _evictExpiredItems();

    if (imageCache.containsKey(key)) {
      final cachedImage = imageCache.get(key);
      if (cachedImage != null) {
        imageCache.put(
          key,
          CachedImage(
            imageBytes: cachedImage.imageBytes,
            lastAccessed: DateTime.now(),
          ),
        );
        return cachedImage.imageBytes;
      }
    }
    return null;
  }

  static void put(String url, Uint8List imageBytes) {
    final timeTrace =
        FirebasePerformance.instance.newTrace('ImageCacheManager-put');
    timeTrace.start();
    _evictExpiredItems();

    if (imageCache.length >= maxCacheSize) {
      _evictLRUItem();
    }

    final key = _toKey(url);
    imageCache.put(
      key,
      CachedImage(
        imageBytes: imageBytes,
        lastAccessed: DateTime.now(),
      ),
    );
    timeTrace.stop();
  }

  static String _toKey(String url) {
    return base64UrlEncode(utf8.encode(url));
  }

  /// Evict the least recently used item
  static void _evictLRUItem() {
    if (imageCache.isNotEmpty) {
      final lruKey = imageCache.keys.cast<String>().reduce((a, b) {
        final aLastAccessed = imageCache.get(a)?.lastAccessed ?? DateTime.now();
        final bLastAccessed = imageCache.get(b)?.lastAccessed ?? DateTime.now();
        return aLastAccessed.isBefore(bLastAccessed) ? a : b;
      });

      imageCache.delete(lruKey);
    }
  }

  /// Evict images that are older than 7 days
  static void _evictExpiredItems() {
    final now = DateTime.now();
    final expiredKeys = imageCache.keys.cast<String>().where((key) {
      final cachedImage = imageCache.get(key);
      return cachedImage != null &&
          now.difference(cachedImage.lastAccessed) > cacheExpiration;
    }).toList();
    expiredKeys.forEach(imageCache.delete);
  }
}
