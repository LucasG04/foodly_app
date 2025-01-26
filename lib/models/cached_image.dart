import 'dart:typed_data';

import 'package:objectbox/objectbox.dart';

@Entity()
class CachedImage {
  int id;

  @Unique(onConflict: ConflictStrategy.replace)
  String url;

  @Property(type: PropertyType.byteVector)
  Uint8List imageBytes;

  DateTime lastAccessed;

  CachedImage({
    this.id = 0,
    required this.url,
    required this.imageBytes,
    required this.lastAccessed,
  });
}
