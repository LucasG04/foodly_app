import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/widgets/page_title.dart';

import '../helpers/screen_size.dart';
import '../helpers/test_localizations.dart';

void main() {
  Widget app() => ProviderScope(
        child: MaterialApp(
          localizationsDelegates: testLocalizationsDelegates,
          home: Scaffold(
            body: PageTitle(
              text: 'Essensplan',
              checkConnectivity: true,
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
                IconButton(
                    onPressed: () {}, icon: const Icon(Icons.more_horiz)),
              ],
            ),
          ),
        ),
      );

  testWidgets('large text: the title fits next to its actions', (tester) async {
    setScreenSize(tester, const Size(402, 874), textScale: 2);

    await tester.pumpWidget(app());
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });

  testWidgets('normal text keeps the 50 pt title row', (tester) async {
    setScreenSize(tester, const Size(402, 874));

    await tester.pumpWidget(app());
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(Row).first).height, 50);
  });
}
