/// Attribution for a stock photo (e.g. Pexels/Pixabay). Mirrors the backend
/// `credit` object: `{source, name, link}`.
class ImageCredit {
  final String source;
  final String? name;
  final String link;

  const ImageCredit({required this.source, this.name, required this.link});

  /// Fail-soft: returns null for anything that is not a complete credit, so
  /// old/cached payloads without the field parse fine.
  static ImageCredit? tryParse(Object? value) {
    if (value is! Map) {
      return null;
    }
    final source = value['source'];
    final link = value['link'];
    final name = value['name'];
    if (source is! String ||
        source.isEmpty ||
        link is! String ||
        link.isEmpty) {
      return null;
    }
    return ImageCredit(
      source: source,
      name: name is String && name.isNotEmpty ? name : null,
      link: link,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'source': source,
        'name': name,
        'link': link,
      };
}
