import '../../utils/basic_utils.dart';

enum AddDishKind { empty, website, instagram, ai }

/// What the add-dish field contains: a link to import or a dish to generate.
class AddDishInput {
  final AddDishKind kind;

  /// Only set for [AddDishKind.website] and [AddDishKind.instagram]; always
  /// starts with `https://`.
  final String? url;

  /// The trimmed input.
  final String text;

  const AddDishInput(this.kind, this.text, [this.url]);
}

final _linkStartExp = RegExp(r'^(https?:|www\.)', caseSensitive: false);

AddDishInput classifyAddDishInput(String input) {
  final text = input.trim();
  if (text.isEmpty) {
    return AddDishInput(AddDishKind.empty, text);
  }
  final url = BasicUtils.extractLink(text);
  if (url == null) {
    // A link still being typed is not a dish to generate.
    return _linkStartExp.hasMatch(text)
        ? AddDishInput(AddDishKind.empty, text)
        : AddDishInput(AddDishKind.ai, text);
  }
  final kind = BasicUtils.isValidInstagramUrl(url)
      ? AddDishKind.instagram
      : AddDishKind.website;
  return AddDishInput(kind, text, url);
}
