import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/screens/tab_navigation/meal_list_view/week_goal_line.dart';

import '../../helpers/load_translations.dart';
import '../../helpers/screen_size.dart';
import '../../helpers/test_localizations.dart';

void main() {
  group('showWeekGoal', () {
    test(
        'hidden without dishes',
        () => expect(
            showWeekGoal(count: 0, reached: false, busy: false), isFalse));
    test(
        'shown for one dish',
        () => expect(
            showWeekGoal(count: 1, reached: false, busy: false), isTrue));
    test(
        'shown for six dishes',
        () => expect(
            showWeekGoal(count: 6, reached: false, busy: false), isTrue));
    test(
        'hidden at seven dishes',
        () => expect(
            showWeekGoal(count: 7, reached: false, busy: false), isFalse));
    test(
        'hidden for good once reached',
        () => expect(
            showWeekGoal(count: 3, reached: true, busy: false), isFalse));
    test(
        'hidden while loading, searching or filtering',
        () => expect(
            showWeekGoal(count: 3, reached: false, busy: true), isFalse));
  });

  testWidgets('tapping the line calls onAdd', (tester) async {
    var added = 0;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Scaffold(body: WeekGoalLine(count: 3, onAdd: () => added++)),
    ));
    await tester.tap(find.byType(WeekGoalLine));
    expect(added, 1);
  });

  testWidgets('German copy fits a 320 pt wide phone', (tester) async {
    loadTranslations('de');
    setScreenSize(tester, const Size(320, 640));
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: testLocalizationsDelegates,
      home: Scaffold(body: WeekGoalLine(count: 6, onAdd: () {})),
    ));
    expect(
      find.text('6 von 7 Gerichten für eine Woche · Mehr hinzufügen'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
