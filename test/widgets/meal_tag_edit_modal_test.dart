import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/meal_create/meal_tag_edit_modal.dart';
import 'package:foodly/widgets/tag_chip.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<String> selected,
    List<String> all = const ['Vegan', 'Schnell'],
    Future<List<String>>? suggestions,
  }) =>
      tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MealTagEditModal(
              selectedContent: selected,
              allContent: all,
              suggestions: suggestions,
            ),
          ),
        ),
      ));

  Finder tag(String t) => find.byKey(ValueKey('tag-$t'));
  bool isSelected(WidgetTester tester, String t) => tester.widget<TagChip>(tag(t)).selected;

  List<String> cloudOrder(WidgetTester tester) => [
        for (final chip in tester.widgetList<TagChip>(find.byType(TagChip)))
          if (chip.key case ValueKey<String>(:final value)
              when value.startsWith('tag-') && value != 'tag-create')
            chip.label,
      ];

  testWidgets('selected then unselected, each alphabetical, re-sorted on toggle', (tester) async {
    await pump(
      tester,
      selected: ['Vegan', 'birne'],
      all: ['Vegan', 'Zucker', 'Äpfel', 'Schnell', 'birne'],
    );
    expect(cloudOrder(tester), ['birne', 'Vegan', 'Äpfel', 'Schnell', 'Zucker']);

    await tester.tap(tag('Vegan'));
    await tester.pumpAndSettle();
    expect(cloudOrder(tester), ['birne', 'Äpfel', 'Schnell', 'Vegan', 'Zucker']);

    await tester.tap(tag('Zucker'));
    await tester.pumpAndSettle();
    expect(cloudOrder(tester), ['birne', 'Zucker', 'Äpfel', 'Schnell', 'Vegan']);
  });

  testWidgets('does not mutate caller list before Done', (tester) async {
    final callerTags = <String>['Vegan'];
    await pump(tester, selected: callerTags);
    await tester.tap(tag('Schnell'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, 'Schnell'), isTrue);
    expect(callerTags, ['Vegan']);
  });

  testWidgets('tapping a tag toggles it', (tester) async {
    await pump(tester, selected: ['Vegan']);
    await tester.tap(tag('Vegan'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, 'Vegan'), isFalse);
    await tester.tap(tag('Vegan'));
    await tester.pumpAndSettle();
    expect(isSelected(tester, 'Vegan'), isTrue);
  });

  testWidgets('suggestions are not preselected; tapping toggles in place', (tester) async {
    await pump(tester, selected: [], suggestions: Future.value(['Vegan']));
    await tester.pumpAndSettle();
    final suggestion = find.byKey(const ValueKey('ai-tag-Vegan'));
    expect(tester.widget<TagChip>(suggestion).selected, isFalse);

    await tester.tap(suggestion);
    await tester.pumpAndSettle();
    expect(tester.widget<TagChip>(suggestion).selected, isTrue);
    await tester.tap(suggestion);
    await tester.pumpAndSettle();
    expect(tester.widget<TagChip>(suggestion).selected, isFalse);
  });

  testWidgets('search field sits above the AI suggestions', (tester) async {
    await pump(tester, selected: [], suggestions: Future.value(['Vegan']));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byType(TextField)).dy,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey('ai-tag-Vegan'))).dy),
    );
  });

  testWidgets('AI suggestions hide while searching and come back without reloading', (tester) async {
    await pump(tester, selected: [], suggestions: Future.value(['Vegan']));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-tag-Vegan')), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Sch');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-tag-Vegan')), findsNothing);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.byKey(const ValueKey('ai-tags-loading')), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-tag-Vegan')), findsOneWidget);
  });

  testWidgets('suggested tags are left out of the tag list, except while searching', (tester) async {
    await pump(tester, selected: [], suggestions: Future.value(['vegan']));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ai-tag-vegan')), findsOneWidget);
    expect(tag('Vegan'), findsNothing);
    expect(tag('Schnell'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Veg');
    await tester.pumpAndSettle();
    expect(tag('Vegan'), findsOneWidget);
  });

  testWidgets('search filters tags and offers create for a new query', (tester) async {
    await pump(tester, selected: []);
    await tester.enterText(find.byType(TextField), 'pas');
    await tester.pumpAndSettle();
    expect(tag('Vegan'), findsNothing);
    expect(tag('Schnell'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('tag-create')));
    await tester.pumpAndSettle();
    expect(isSelected(tester, 'pas'), isTrue);
    expect(find.byKey(const ValueKey('tag-create')), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('no create chip when the query matches an existing tag', (tester) async {
    await pump(tester, selected: []);
    await tester.enterText(find.byType(TextField), ' vegan ');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tag-create')), findsNothing);
    expect(tag('Vegan'), findsOneWidget);
  });

  testWidgets('keyboard submit selects the existing spelling without duplicating', (tester) async {
    await pump(tester, selected: []);
    await tester.enterText(find.byType(TextField), 'vegan');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(isSelected(tester, 'Vegan'), isTrue);
    expect(tag('vegan'), findsNothing);
  });

  testWidgets('sheet does not shrink while searching', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: MealTagEditModal(
              selectedContent: const [],
              allContent: [for (var i = 0; i < 40; i++) 'Tag $i'],
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final before = tester.getSize(find.byType(MealTagEditModal)).height;

    await tester.enterText(find.byType(TextField), 'Tag 7');
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MealTagEditModal)).height, before);
  });

  testWidgets('keyboard height is not locked into the sheet', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Future<void> pumpWithInset(double inset) => tester.pumpWidget(ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: const Size(800, 900),
                viewInsets: EdgeInsets.only(bottom: inset),
              ),
              // Like the real sheet: the inset reaches the modal unresized.
              child: Scaffold(
                resizeToAvoidBottomInset: false,
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: MealTagEditModal(
                    selectedContent: const [],
                    allContent: [for (var i = 0; i < 6; i++) 'Tag $i'],
                  ),
                ),
              ),
            ),
          ),
        ));
    double height() => tester.getSize(find.byType(MealTagEditModal)).height;

    await pumpWithInset(0);
    await tester.pumpAndSettle();
    final resting = height();

    await pumpWithInset(300);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tag 7');
    await tester.pumpAndSettle();
    expect(height(), resting + 300);

    await pumpWithInset(0);
    await tester.pumpAndSettle();
    expect(height(), resting);
  });

  testWidgets('no empty state when the AI has suggestions for a tagless plan', (tester) async {
    await pump(tester, selected: [], all: [], suggestions: Future.value(['Vegan']));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tags-empty')), findsNothing);
    expect(find.byKey(const ValueKey('ai-tag-Vegan')), findsOneWidget);
  });

  testWidgets('searching finds AI suggestions and reuses their spelling', (tester) async {
    await pump(tester, selected: [], all: [], suggestions: Future.value(['Vegan']));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'veg');
    await tester.pumpAndSettle();
    expect(tag('Vegan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'vegan');
    await tester.pump();
    expect(find.byKey(const ValueKey('tag-create')), findsNothing);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(tester.widget<TagChip>(find.byKey(const ValueKey('ai-tag-Vegan'))).selected, isTrue);
    expect(tag('vegan'), findsNothing);
  });

  testWidgets('shows empty state when the plan has no tags', (tester) async {
    await pump(tester, selected: [], all: []);
    expect(find.byKey(const ValueKey('tags-empty')), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Neu');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tags-empty')), findsNothing);
    expect(find.byKey(const ValueKey('tag-create')), findsOneWidget);
  });
}
