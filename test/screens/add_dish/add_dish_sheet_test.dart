import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/models/ai_usage.dart';
import 'package:foodly/providers/state_providers.dart';
import 'package:foodly/screens/add_dish/add_dish_input.dart';
import 'package:foodly/screens/add_dish/add_dish_sheet.dart';
import 'package:foodly/services/in_app_purchase_service.dart';
import 'package:simple_icons/simple_icons.dart';

import '../../helpers/load_translations.dart';
import '../../helpers/screen_size.dart';
import '../../helpers/test_localizations.dart';

AiUsage _usage({int textUsed = 0, int instagramUsed = 0}) => AiUsage(
      periodKey: '2026-10-19',
      kcalUsed: 0,
      textUsed: textUsed,
      instagramUsed: instagramUsed,
      limits: const AiLimits(text: 3, instagram: 3, kcal: 6),
    );

void main() {
  setUp(() => loadTranslations('en'));

  /// Opens the sheet on top of a host page; returns a getter for the value
  /// it popped with.
  Future<AddDishChoice? Function()> pumpSheet(
    WidgetTester tester, {
    AiUsage? usage,
    bool subscribed = false,
    bool showOtherPlans = false,
  }) async {
    AddDishChoice? result;
    await tester.pumpWidget(ProviderScope(
      overrides: [
        aiUsageProvider.overrideWith((ref) => Stream.value(usage)),
        InAppPurchaseService.$userIsSubscribed
            .overrideWith((ref) => subscribed),
      ],
      child: MaterialApp(
        localizationsDelegates: testLocalizationsDelegates,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<AddDishChoice>(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    body: SingleChildScrollView(
                      child: AddDishSheet(showOtherPlans: showOtherPlans),
                    ),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  Future<void> type(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pumpAndSettle();
  }

  testWidgets('recipe website link is free and imports', (tester) async {
    await pumpSheet(tester, usage: _usage());
    await type(tester, 'https://www.chefkoch.de/r/1');
    expect(find.text('Recipe website · free'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
  });

  testWidgets('instagram link shows remaining imports', (tester) async {
    await pumpSheet(tester, usage: _usage(instagramUsed: 1));
    await type(tester, 'https://www.instagram.com/reel/a/');
    expect(find.text('Instagram · 2 of 3 left this week'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
  });

  testWidgets('exhausted AI quota offers premium', (tester) async {
    await pumpSheet(tester, usage: _usage(textUsed: 3));
    await type(tester, 'Lasagne');
    expect(
      find.text(
          'No AI recipes left this week · links from recipe websites stay free'),
      findsOneWidget,
    );
    expect(find.text('Get Premium'), findsOneWidget);
    expect(find.text('Create with AI'), findsNothing);
  });

  testWidgets('get premium pops with the exhausted feature', (tester) async {
    final result = await pumpSheet(tester, usage: _usage(instagramUsed: 3));
    await type(tester, 'https://www.instagram.com/reel/a/');
    await tester.tap(find.text('Get Premium'));
    await tester.pumpAndSettle();
    expect((result()! as AddDishPremium).feature, 'instagram');
  });

  testWidgets('premium users see no counts', (tester) async {
    await pumpSheet(tester, usage: _usage(textUsed: 3), subscribed: true);
    await type(tester, 'Lasagne');
    expect(find.text('AI recipe'), findsOneWidget);
    expect(find.textContaining(' of '), findsNothing);
    expect(find.text('Create with AI'), findsOneWidget);
  });

  testWidgets('unknown quota still allows creating', (tester) async {
    final result = await pumpSheet(tester);
    await type(tester, 'Lasagne');
    expect(find.text('AI recipe'), findsOneWidget);
    await tester.tap(find.text('Create with AI'));
    await tester.pumpAndSettle();
    expect(result(), isA<AddDishAi>());
    expect((result()! as AddDishAi).prompt, 'Lasagne');
  });

  testWidgets('other plans row only with more than one plan', (tester) async {
    await pumpSheet(tester);
    expect(find.text('From my other plans'), findsNothing);
    expect(find.text('Discover dishes'), findsOneWidget);
    expect(find.text('Write it myself'), findsOneWidget);
  });

  testWidgets('other plans row with more than one plan', (tester) async {
    await pumpSheet(tester, showOtherPlans: true);
    expect(find.text('From my other plans'), findsOneWidget);
  });

  testWidgets('no action button while the field is empty', (tester) async {
    await pumpSheet(tester);
    expect(find.text('Import'), findsNothing);
    expect(find.text('Create with AI'), findsNothing);
  });

  testWidgets('import pops with the link', (tester) async {
    final result = await pumpSheet(tester, usage: _usage());
    await type(tester, 'https://www.chefkoch.de/r/1');
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    final link = result()! as AddDishLink;
    expect(link.url, 'https://www.chefkoch.de/r/1');
    expect(link.kind, AddDishKind.website);
  });

  testWidgets('library row pops with library choice', (tester) async {
    final result = await pumpSheet(tester);
    await tester.tap(find.text('Discover dishes'));
    await tester.pumpAndSettle();
    expect(result(), isA<AddDishLibrary>());
  });

  testWidgets('German copy fits a 320 pt wide phone', (tester) async {
    loadTranslations('de');
    setScreenSize(tester, const Size(320, 640));

    await pumpSheet(tester,
        usage: _usage(instagramUsed: 3), showOtherPlans: true);
    await type(tester, 'https://www.instagram.com/reel/a/');
    expect(
      find.text('Keine Instagram-Importe mehr diese Woche · '
          'Links von Rezeptseiten bleiben kostenlos'),
      findsOneWidget,
    );
    await type(tester, 'Spaghetti bolognese');
    expect(find.text('KI-Rezept · noch 3 von 3 diese Woche'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('typing a link char by char and closing does not break the tree',
      (tester) async {
    await pumpSheet(tester, usage: _usage());
    const text = 'Look at this https://www.instagram.com/reel/abc/';
    for (var i = 1; i <= text.length; i++) {
      await tester.enterText(find.byType(TextField), text.substring(0, i));
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(tester.takeException(), isNull);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing inside a link does not cross-fade the cost line',
      (tester) async {
    await pumpSheet(tester, usage: _usage());
    await type(tester, 'https://www.chefkoch.de/r/1');
    await tester.enterText(
        find.byType(TextField), 'https://www.chefkoch.de/r/12');
    await tester.pump(const Duration(milliseconds: 50));
    // Same kind: no outgoing copy of the line/button fading out.
    expect(find.text('Recipe website · free'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
  });

  testWidgets('premium button text is dark on the premium yellow',
      (tester) async {
    await pumpSheet(tester, usage: _usage(textUsed: 3));
    await type(tester, 'Lasagne');
    final label = tester.widget<Text>(find.text('Get Premium'));
    // White on the yellow is about 1.6:1; the app's dark ink reads.
    expect(label.style?.color, kPrimaryColor);
  });

  testWidgets('large text: nothing cut off, header pinned, icons scale',
      (tester) async {
    loadTranslations('de');
    setScreenSize(tester, const Size(320, 640), textScale: 2);

    await pumpSheet(tester, usage: _usage());
    await type(tester, 'https://www.instagram.com/reel/a/');
    expect(tester.takeException(), isNull);

    // Title and placeholder may wrap instead of ending in "…".
    final title = tester.widget<Text>(find.text('GERICHT HINZUFÜGEN'));
    expect(title.maxLines, 2);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintMaxLines, 2);

    // The header stays in place while the content scrolls under it.
    final sheetScroll = find.descendant(
      of: find.byType(AddDishSheet),
      matching: find.byType(SingleChildScrollView),
    );
    expect(sheetScroll, findsOneWidget);
    expect(
      find.descendant(
          of: sheetScroll, matching: find.text('GERICHT HINZUFÜGEN')),
      findsNothing,
    );

    // The cost line's icon grows with its text.
    expect(tester.widget<Icon>(find.byIcon(SimpleIcons.instagram)).size, 32);
  });
}
