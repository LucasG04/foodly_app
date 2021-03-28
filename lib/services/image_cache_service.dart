import 'package:hive/hive.dart';

class ImageCacheService {
  ImageCacheService._();

  static var box = Hive.openBox('image_cache');
}
