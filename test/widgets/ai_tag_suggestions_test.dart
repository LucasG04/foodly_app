import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/meal_create/ai_tag_suggestions.dart';
import 'package:foodly/widgets/tag_chip.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required Future<List<String>>? future,
    List<String> selected = const [],
    ValueChanged<String>? onToggle,
  }) =>
      tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AiTagSuggestions(
            suggestions: future,
            selected: selected,
            onToggle: onToggle ?? (_) {},
          ),
        ),
      ));

  TagChip chip(WidgetTester tester, String tag) =>
      tester.widget<TagChip>(find.byKey(ValueKey('ai-tag-$tag')));

  testWidgets('shows loading, then suggestion chips', (tester) async {
    final completer = Completer<List<String>>();
    await pump(tester, future: completer.future);
    expect(find.byKey(const ValueKey('ai-tags-loading')), findsOneWidget);

    completer.complete(['Vegan', 'Schnell']);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-tags-loading')), findsNothing);
    expect(find.byKey(const ValueKey('ai-tag-Vegan')), findsOneWidget);
    expect(find.byKey(const ValueKey('ai-tag-Schnell')), findsOneWidget);
  });

  testWidgets('loading placeholders are real suggested chips without text', (tester) async {
    await pump(tester, future: Completer<List<String>>().future);
    final loading = find.byKey(const ValueKey('ai-tags-loading'));
    final chips = find.descendant(of: loading, matching: find.byType(TagChip));
    expect(chips, findsNWidgets(3));
    for (final chip in tester.widgetList<TagChip>(chips)) {
      expect(chip.style, TagChipStyle.suggested);
      expect(chip.placeholder, isNotNull);
    }
    expect(find.descendant(of: loading, matching: find.byType(Text)), findsNothing);
    expect(find.descendant(of: loading, matching: find.byIcon(Icons.auto_awesome_rounded)), findsNWidgets(3));
  });

  testWidgets('tapping a chip calls onToggle', (tester) async {
    String? toggled;
    await pump(tester, future: Future.value(['Vegan']), onToggle: (t) => toggled = t);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ai-tag-Vegan')));
    expect(toggled, 'Vegan');
  });

  testWidgets('selected tags stay in place, marked selected (case/whitespace-insensitive)', (tester) async {
    await pump(tester, future: Future.value(['Vegan', 'Schnell']), selected: ['vegan ']);
    await tester.pumpAndSettle();
    expect(chip(tester, 'Vegan').selected, isTrue);
    expect(chip(tester, 'Schnell').selected, isFalse);
  });

  testWidgets('renders nothing for null, empty, or failed', (tester) async {
    for (final future in <Future<List<String>>?>[null, Future.value(<String>[])]) {
      await pump(tester, future: future);
      await tester.pumpAndSettle();
      expect(find.byType(TagChip), findsNothing);
      expect(find.byKey(const ValueKey('ai-tags-loading')), findsNothing);
    }
    // Fail only after FutureBuilder subscribed, else the error counts as unhandled.
    final failing = Completer<List<String>>();
    await pump(tester, future: failing.future);
    failing.completeError('x');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-tags-loading')), findsNothing);
    expect(find.byType(TagChip), findsNothing);
  });

  testWidgets('no animation when disableAnimations', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: AiTagSuggestions(
            suggestions: Completer<List<String>>().future,
            selected: const [],
            onToggle: (_) {},
          ),
        ),
      ),
    ));
    // pumpAndSettle would time out if a repeating animation were running.
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-tags-loading')), findsOneWidget);
  });
}
