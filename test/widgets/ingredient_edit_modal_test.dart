import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/grocery.dart';
import 'package:foodly/models/ingredient.dart';
import 'package:foodly/widgets/ingredient_edit_modal.dart';
// Transitive via easy_localization; only needed to mock its saved locale.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences/shared_preferences.dart';

/// Reads translations from disk; the modal needs a real [EasyLocalization]
/// ancestor because it reads `context.locale`.
class _FileAssetLoader extends AssetLoader {
  const _FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) =>
      Future.value(jsonDecode(
        File('$path/${locale.languageCode}.json').readAsStringSync(),
      ) as Map<String, dynamic>);
}

void main() {
  const lasagne = GrocerySource(mealId: 'm1', mealName: 'Lasagne');
  const chili = GrocerySource(mealId: 'm2', mealName: 'Chili');

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pump(WidgetTester tester, List<GrocerySource> sources) async {
    await tester.pumpWidget(EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _FileAssetLoader(),
      saveLocale: false,
      child: ProviderScope(
        child: Builder(
          builder: (context) => MaterialApp(
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            home: Scaffold(
              body: IngredientEditModal(
                ingredient: Ingredient(name: 'Hackfleisch'),
                sources: sources,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the meals as one muted line', (tester) async {
    await pump(tester, [lasagne, chili]);
    final caption = tester.widget<Text>(find.text('For Lasagne, Chili'));
    expect(caption.maxLines, 1);
    expect(caption.overflow, TextOverflow.ellipsis);
  });

  testWidgets('hides the line without sources', (tester) async {
    await pump(tester, []);
    expect(find.text('Hackfleisch'), findsOneWidget);
    expect(find.textContaining('For '), findsNothing);
  });

  testWidgets('meals with the same name show once', (tester) async {
    await pump(tester, [
      lasagne,
      const GrocerySource(mealId: 'm3', mealName: 'Lasagne'),
    ]);
    expect(find.text('For Lasagne'), findsOneWidget);
  });
}
