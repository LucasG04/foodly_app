import 'package:isar/isar.dart';

part 'link_metadata.g.dart';

@collection
class LinkMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  String? url;

  String? image;

  String? title;

  String? description;

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
