import 'dart:collection';
import 'dart:typed_data';

import 'package:hive/hive.dart';

class ImageCacheManager {
  ImageCacheManager._();

  static const int maxCacheSize = 50;
  static const Duration cacheExpiration = Duration(days: 7);
  static late Box imageCache;
  static final LinkedHashMap<String, DateTime> accessTimeMap = LinkedHashMap();

  static Future<void> initialize() async {
    imageCache = await Hive.openBox('imageCache');
  }

  static Uint8List? get(String url) {
    _evictExpiredItems(); // Evict expired items before returning the cached image
    if (imageCache.containsKey(url)) {
      accessTimeMap[url] = DateTime.now();
      return imageCache.get(url);
    }
    return null;
  }

  static void put(String url, Uint8List imageBytes) {
    _evictExpiredItems(); // Evict expired items before adding a new one

    if (imageCache.length >= maxCacheSize) {
      _evictLRUItem(); // Evict LRU if cache is full
    }

    imageCache.put(url, imageBytes);
    accessTimeMap[url] = DateTime.now();
  }

  /// Evict the least recently used item
  static void _evictLRUItem() {
    final String lruKey = accessTimeMap.entries
        .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
        .key;

    imageCache.delete(lruKey);
    accessTimeMap.remove(lruKey);
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
