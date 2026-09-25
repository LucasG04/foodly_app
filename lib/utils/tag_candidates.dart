import 'dart:async';

/// Tag identity for matching and dedup: case- and whitespace-insensitive.
String normalizeTag(String tag) => tag.trim().toLowerCase();

/// Server rejects more than this (lunix-api `meal-tags.ts`).
const int kMaxTagCandidates = 100;
const int _kMaxTagLength = 40;

/// Plan tags first (their spelling wins), then starter tags; trimmed,
/// case-insensitively deduped, capped at [max].
List<String> buildTagCandidates(
  List<String> planTags,
  List<String> starterTags, {
  int max = kMaxTagCandidates,
}) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in [...planTags, ...starterTags]) {
    final tag = raw.trim();
    if (tag.isEmpty || tag.length > _kMaxTagLength) {
      continue;
    }
    if (!seen.add(normalizeTag(tag))) {
      continue;
    }
    result.add(tag);
    if (result.length == max) {
      break;
    }
  }
  return result;
}

/// Reuses one suggestion request per meal content + candidates.
/// A failed (`null`) or stalled (> [timeout]) fetch resolves to `[]` and is
/// not cached, so the next open retries.
class TagSuggestionCache {
  final Duration timeout;
  String? _key;
  Future<List<String>>? _future;

  TagSuggestionCache({this.timeout = const Duration(seconds: 8)});

  Future<List<String>>? get({
    required String name,
    required List<String> ingredients,
    required List<String> candidates,
    String? instructions,
    int? duration,
    required Future<List<String>?> Function() fetch,
  }) {
    if (name.trim().isEmpty || candidates.isEmpty) {
      return null;
    }
    // Everything the request sends, so any edit asks again.
    final key = [
      name.trim(),
      instructions ?? '',
      '${duration ?? ''}',
      ...ingredients,
      '\u0001',
      ...candidates,
    ].join('\u0000');
    if (key != _key) {
      _key = key;
      _future = fetch()
          // Widen first: a Future<List<String>> can't take a null onTimeout.
          .then<List<String>?>((tags) => tags)
          .timeout(timeout, onTimeout: () => null)
          .then((tags) {
        if (tags == null && _key == key) {
          _key = null;
        }
        return tags ?? const <String>[];
      });
    }
    return _future;
  }
}
