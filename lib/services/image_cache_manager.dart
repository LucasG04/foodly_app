import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:logging/logging.dart';

import '../models/cached_image.dart';

class ImageCacheManager {
  ImageCacheManager._();

  static final _log = Logger('ImageCacheManager');
  static const int maxCacheSize = 50;
  static const Duration cacheExpiration = Duration(days: 7);
  static final Map<String, CachedImage> _imageCache = {};

  static Future<void> initialize() async {
    try {
      Hive.deleteBoxFromDisk('imageCache');
      Hive.deleteBoxFromDisk('imageCache2');
      Hive.deleteBoxFromDisk('imageCache3');
    } catch (e) {
      _log.warning('Failed to delete image cache boxes', e);
    }
  }

  static Uint8List? get(String url) {
    final key = _toKey(url);
    _evictExpiredItems();

    if (_imageCache.containsKey(key)) {
      final cachedImage = _imageCache[key];
      if (cachedImage != null) {
        _imageCache[key] = CachedImage(
          imageBytes: cachedImage.imageBytes,
          lastAccessed: DateTime.now(),
        );
        return cachedImage.imageBytes;
      }
    }
    return null;
  }

  static void put(String url, Uint8List imageBytes) {
    _evictExpiredItems();

    if (_imageCache.length >= maxCacheSize) {
      _evictLRUItem();
    }

    final key = _toKey(url);
    _imageCache[key] = CachedImage(
      imageBytes: imageBytes,
      lastAccessed: DateTime.now(),
    );
  }

  static String _toKey(String url) {
    return base64UrlEncode(utf8.encode(url));
  }

  /// Evict the least recently used item
  static void _evictLRUItem() {
    if (_imageCache.isNotEmpty) {
      final lruKey = _imageCache.keys.reduce((a, b) {
        final aLastAccessed = _imageCache[a]?.lastAccessed ?? DateTime.now();
        final bLastAccessed = _imageCache[b]?.lastAccessed ?? DateTime.now();
        return aLastAccessed.isBefore(bLastAccessed) ? a : b;
      });

      _imageCache.remove(lruKey);
    }
  }

  /// Evict images that are older than 7 days
  static void _evictExpiredItems() {
    final now = DateTime.now();
    final expiredKeys = _imageCache.keys.where((key) {
      final cachedImage = _imageCache[key];
      return cachedImage != null &&
          now.difference(cachedImage.lastAccessed) > cacheExpiration;
    }).toList();
    expiredKeys.forEach(_imageCache.remove);
  }
}
