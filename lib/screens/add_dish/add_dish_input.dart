import '../../models/social_platform.dart';
import '../../utils/basic_utils.dart';

/// [social]: an Instagram or TikTok link (see [AddDishInput.platform]).
enum AddDishKind { empty, website, social, ai }

/// What the add-dish field contains: a link to import or a dish to generate.
class AddDishInput {
  final AddDishKind kind;

  /// Only set for [AddDishKind.website] and [AddDishKind.social]; always
  /// starts with `https://`.
  final String? url;

  /// Only set for [AddDishKind.social].
  final SocialPlatform? platform;

  /// The trimmed input.
  final String text;

  const AddDishInput(this.kind, this.text, [this.url, this.platform]);
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
  final platform = BasicUtils.socialPlatformOf(url);
  final kind = platform != null ? AddDishKind.social : AddDishKind.website;
  return AddDishInput(kind, text, url, platform);
}
