import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_performance/firebase_performance.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

class ImageCacheManager {
  ImageCacheManager._();

  static final _log = Logger('ImageCacheManager');
  static const int maxCacheSize = 50;
  static const Duration cacheExpiration = Duration(days: 7);
  static late Box imageCache;
  static final LinkedHashMap<String, DateTime> accessTimeMap = LinkedHashMap();

  static Future<void> initialize() async {
    try {
      imageCache = await Hive.openBox('imageCache');
    } catch (e) {
      await Hive.deleteBoxFromDisk('imageCache');
      _log.severe('Could not open imageCache box', e);
    } finally {
      imageCache = await Hive.openBox('imageCache');
    }

    // delete old image box
    Hive.deleteBoxFromDisk('imageCache2')
        .catchError((e) => _log.fine('Could not delete old imageCache box', e));
  }

  static Uint8List? get(String url) {
    final key = _toKey(url);
    _evictExpiredItems(); // Evict expired items before returning the cached image
    if (imageCache.containsKey(key)) {
      accessTimeMap[key] = DateTime.now();
      return imageCache.get(key);
    }
    return null;
  }

  static void put(String url, Uint8List imageBytes) {
    final timeTrace =
        FirebasePerformance.instance.newTrace('ImageCacheManager-put');
    timeTrace.start();
    _evictExpiredItems(); // Evict expired items before adding a new one

    if (imageCache.length >= maxCacheSize) {
      _evictLRUItem(); // Evict LRU if cache is full
    }

    final key = _toKey(url);
    imageCache.put(key, imageBytes);
    accessTimeMap[key] = DateTime.now();
    timeTrace.stop();
  }

  static String _toKey(String url) {
    return base64UrlEncode(utf8.encode(url));
  }

  /// Evict the least recently used item
  static void _evictLRUItem() {
    if (accessTimeMap.isNotEmpty) {
      final String lruKey = accessTimeMap.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;

      imageCache.delete(lruKey);
      accessTimeMap.remove(lruKey);
    }
  }

  /// Evict images that are older than 7 days
  static void _evictExpiredItems() {
    final now = DateTime.now();
    final expiredKeys = accessTimeMap.entries
        .where((entry) => now.difference(entry.value) > cacheExpiration)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      imageCache.delete(key);
      accessTimeMap.remove(key);
    }
  }
}
