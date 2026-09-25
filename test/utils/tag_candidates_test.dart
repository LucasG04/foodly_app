import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/utils/tag_candidates.dart';

void main() {
  cacheTests();
  reviewFixTests();

  test('plan tags first, starter set appended, case-insensitive dedupe keeps plan spelling', () {
    expect(
      buildTagCandidates(['Vegan', 'Omas Rezepte'], ['vegan', 'Schnell']),
      ['Vegan', 'Omas Rezepte', 'Schnell'],
    );
  });

  test('trims, drops empty and >40 char tags', () {
    expect(
      buildTagCandidates([' Pasta ', '', 'x' * 41], []),
      ['Pasta'],
    );
  });

  test('caps at max with plan tags taking priority', () {
    final plan = List.generate(150, (i) => 'p$i');
    final result = buildTagCandidates(plan, ['Vegan']);
    expect(result.length, kMaxTagCandidates);
    expect(result.first, 'p0');
    expect(result, isNot(contains('Vegan')));
  });
}

void cacheTests() {
  group('TagSuggestionCache', () {
    late int calls;
    late List<String>? next;
    Future<List<String>?> fetch() async {
      calls++;
      return next;
    }

    setUp(() {
      calls = 0;
      next = ['Vegan'];
    });

    Future<List<String>>? get(
      TagSuggestionCache c, {
      String name = 'Curry',
      List<String> ingredients = const ['Reis'],
      List<String> candidates = const ['Vegan'],
    }) =>
        c.get(
          name: name,
          ingredients: ingredients,
          candidates: candidates,
          fetch: fetch,
        );

    test('empty name or no candidates → null, no fetch', () {
      final c = TagSuggestionCache();
      expect(get(c, name: '  '), isNull);
      expect(get(c, candidates: []), isNull);
      expect(calls, 0);
    });

    test('same content reuses the request', () async {
      final c = TagSuggestionCache();
      expect(await get(c), ['Vegan']);
      expect(await get(c), ['Vegan']);
      expect(calls, 1);
    });

    test('changed name, ingredients or candidates refetch', () async {
      final c = TagSuggestionCache();
      await get(c);
      await get(c, name: 'Suppe');
      await get(c, name: 'Suppe', ingredients: ['Tomate']);
      await get(c, name: 'Suppe', ingredients: ['Tomate'], candidates: ['Vegan', 'Suppe']);
      expect(calls, 4);
    });

    test('failed fetch yields [] and is not cached', () async {
      final c = TagSuggestionCache();
      next = null;
      expect(await get(c), <String>[]);
      next = ['Vegan'];
      expect(await get(c), ['Vegan']);
      expect(calls, 2);
    });
  });
}

void reviewFixTests() {
  test('normalizeTag trims and lowercases', () {
    expect(normalizeTag('  Vegan '), 'vegan');
  });

  test('changed instructions or duration refetch', () async {
    var calls = 0;
    final c = TagSuggestionCache();
    Future<List<String>>? get({String? instructions, int? duration}) => c.get(
          name: 'Curry',
          ingredients: const ['Reis'],
          instructions: instructions,
          duration: duration,
          candidates: const ['Schnell'],
          fetch: () async {
            calls++;
            return ['Schnell'];
          },
        );
    await get();
    await get(duration: 10);
    await get(duration: 10, instructions: 'Kochen.');
    await get(duration: 10, instructions: 'Kochen.');
    expect(calls, 3);
  });

  test('a stalled fetch times out to [] and is retried next time', () async {
    var calls = 0;
    final c = TagSuggestionCache(timeout: const Duration(milliseconds: 20));
    Future<List<String>>? get(Future<List<String>?> Function() fetch) => c.get(
          name: 'Curry',
          ingredients: const [],
          candidates: const ['Vegan'],
          fetch: () {
            calls++;
            return fetch();
          },
        );
    expect(await get(() => Completer<List<String>?>().future), <String>[]);
    expect(await get(() async => ['Vegan']), ['Vegan']);
    expect(calls, 2);
  });
}
