import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/widgets/keyboard_aware_sheet.dart';

void main() {
  Widget sheet({required double keyboard}) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: const Size(400, 600),
            viewInsets: EdgeInsets.only(bottom: keyboard),
          ),
          child: const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: KeyboardAwareSheet(children: [Text('content')]),
            ),
          ),
        ),
      );

  testWidgets('shows its content above the keyboard', (tester) async {
    await tester.pumpWidget(sheet(keyboard: 300));
    expect(find.text('content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a keyboard taller than the sheet area does not break it',
      (tester) async {
    await tester.pumpWidget(sheet(keyboard: 590));
    expect(tester.takeException(), isNull);
  });
}
