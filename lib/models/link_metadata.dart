import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class LinkMetadata extends HiveObject {
  @HiveField(0)
  String url;

  @HiveField(1)
  String image;

  @HiveField(2)
  String title;

  @HiveField(3)
  String description;

  @HiveField(4)
  DateTime cachedAt;

  LinkMetadata({
    this.url,
    this.image,
    this.title,
    this.description,
    this.cachedAt,
  });
}
