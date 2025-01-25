import 'dart:typed_data';

class CachedImage {
  final Uint8List imageBytes;
  final DateTime lastAccessed;

  CachedImage({required this.imageBytes, required this.lastAccessed});
}
