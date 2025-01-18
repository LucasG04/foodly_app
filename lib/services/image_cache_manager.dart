import 'dart:collection';
import 'dart:convert'; // Für die Base64-Kodierung und -Dekodierung
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
    imageCache = await Hive.openBox('imageCache2');

    // delete old image box
    try {
      await Hive.deleteBoxFromDisk('imageCache');
    } catch (e) {
      _log.fine('Could not delete old imageCache box', e);
    }
  }

  static Uint8List? get(String url) {
    _evictExpiredItems(); // Evict expired items before returning the cached image
    if (imageCache.containsKey(url)) {
      accessTimeMap[url] = DateTime.now();
      final String base64String = imageCache.get(url);
      return base64Decode(base64String);
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

    final String base64String = base64Encode(imageBytes);
    imageCache.put(url, base64String);
    accessTimeMap[url] = DateTime.now();
    timeTrace.stop();
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
