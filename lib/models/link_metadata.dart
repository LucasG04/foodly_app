import 'package:hive/hive.dart';

part 'link_metadata.g.dart';

@HiveType(typeId: 1)
class LinkMetadata {
  @HiveField(0)
  String? url;

  @HiveField(1)
  String? image;

  @HiveField(2)
  String? title;

  @HiveField(3)
  String? description;

  @HiveField(4)
  DateTime? cachedAt;

  LinkMetadata({
    this.url,
    this.image,
    this.title,
    this.description,
    this.cachedAt,
  });

  @override
  String toString() {
    return 'LinkMetadata(url: $url, image: $image, title: $title, description: $description, cachedAt: $cachedAt)';
  }
}
