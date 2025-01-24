import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

part 'cached_image.g.dart';

@HiveType(typeId: 2)
class CachedImage {
  @HiveField(0)
  final Uint8List imageBytes;

  @HiveField(1)
  final DateTime lastAccessed;

  CachedImage({required this.imageBytes, required this.lastAccessed});
}
