// ignore_for_file: avoid_dynamic_calls

class LunixImageResponse {
  int page;
  int size;
  List<LunixImage> images;

  LunixImageResponse({
    required this.page,
    required this.size,
    required this.images,
  });

  factory LunixImageResponse.fromMap(Map<String, dynamic> map) {
    return LunixImageResponse(
      page: map['page'] as int? ?? 0,
      size: map['size'] as int? ?? 0,
      images: List<LunixImage>.from((map['data'] as List<dynamic>)
              .map<LunixImage>(
                  (dynamic x) => LunixImage.fromMap(x as Map<String, dynamic>)))
          .toList(),
    );
  }
}

class LunixImage {
  String url;
  int width;
  int height;

  LunixImage({
    required this.url,
    required this.width,
    required this.height,
  });

  factory LunixImage.fromMap(Map<String, dynamic> map) {
    return LunixImage(
      url: map['url'] as String? ?? '',
      width: map['width'] as int? ?? 0,
      height: map['height'] as int? ?? 0,
    );
  }
}
