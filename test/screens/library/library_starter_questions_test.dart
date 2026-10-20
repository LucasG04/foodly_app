import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/library_meal.dart';
import 'package:foodly/screens/library/library_starter_sheet.dart';

import '../../helpers/load_translations.dart';
import '../../helpers/screen_size.dart';
import '../../helpers/test_localizations.dart';

void main() {
  Future<StarterAnswers? Function()> pump(WidgetTester tester) async {
    StarterAnswers? answers;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: LibraryStarterQuestions(onSubmit: (a) => answers = a),
        ),
      ),
    ));
    return () => answers;
  }

  testWidgets('submitting without a choice filters nothing', (tester) async {
    final answers = await pump(tester);
    await tester.tap(find.text('library_starter_show'));
    expect(answers(), isNotNull);
    expect(answers()!.toFilter('en').isEmpty, isTrue);
  });

  testWidgets('submits the chosen diet and kinds', (tester) async {
    final answers = await pump(tester);
    await tester.tap(find.text('library_starter_diet_vegetarian'));
    await tester.pump();
    await tester.tap(find.text(LibraryTag.soup.label('en')));
    await tester.pump();
    await tester.tap(find.text('library_starter_show'));
    expect(answers()!.diet, StarterDiet.vegetarian);
    expect(answers()!.kinds, {LibraryTag.soup});
  });

  testWidgets('German copy fits a 320 pt wide phone', (tester) async {
    loadTranslations('de');
    setScreenSize(tester, const Size(320, 640));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: 288,
            child: LibraryStarterQuestions(onSubmit: (_) {}),
          ),
        ),
      ),
    ));
    expect(find.text('Kein Fleisch, Fisch ist okay'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
