import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/image_credit.dart';
import 'package:foodly/widgets/image_credit_chip.dart';

void main() {
  Future<void> pump(WidgetTester tester, ImageCredit? credit) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: Center(child: ImageCreditChip(credit))),
        ),
      );

  double chipWidth(WidgetTester tester) =>
      tester.getSize(find.byType(ImageCreditChip)).width;

  testWidgets('collapsed "i" expands to the credit on tap', (tester) async {
    await pump(
      tester,
      const ImageCredit(source: 'Pexels', link: 'https://pexels.com/p/1'),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    final collapsed = chipWidth(tester);

    await tester.tap(find.byType(ImageCreditChip));
    await tester.pumpAndSettle();
    expect(find.text('Pexels'), findsOneWidget);
    expect(chipWidth(tester), greaterThan(collapsed));

    // Auto-collapses.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(chipWidth(tester), collapsed);
  });

  testWidgets('long credit fits a narrow slot without overflow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              child: Align(
                alignment: Alignment.bottomRight,
                child: ImageCreditChip(
                  ImageCredit(
                    source: 'Pixabay',
                    name: 'A Photographer With A Very Long Name',
                    link: 'https://pixabay.com/p/1',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ImageCreditChip));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(ImageCreditChip)).width,
      lessThanOrEqualTo(200),
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('taps do not reach the widget underneath', (tester) async {
    var backgroundTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: () => backgroundTaps++),
            ),
            const Center(
              child: ImageCreditChip(
                ImageCredit(source: 'Pexels', link: 'https://pexels.com/p/1'),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ImageCreditChip));
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(backgroundTaps, 0);
  });

  testWidgets('renders nothing when credit is null', (tester) async {
    await pump(tester, null);
    expect(find.byType(Text), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });
}
