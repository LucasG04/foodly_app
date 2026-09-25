import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/widgets/tag_chip.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget chip) => tester.pumpWidget(
        MaterialApp(home: Scaffold(body: Center(child: chip))),
      );

  testWidgets('uses the shared FilterChip design', (tester) async {
    await pump(tester, TagChip(label: 'Vegan', selected: true, onTap: () {}));
    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    final primary = Theme.of(tester.element(find.byType(FilterChip))).primaryColor;
    expect(chip.selected, isTrue);
    expect(chip.selectedColor, primary);
    expect(chip.backgroundColor, primary);
  });

  testWidgets('suggested and create chips carry a leading icon', (tester) async {
    await pump(tester, TagChip(label: 'Vegan', style: TagChipStyle.suggested, onTap: () {}));
    expect(tester.widget<FilterChip>(find.byType(FilterChip)).avatar, isNotNull);
    await pump(tester, TagChip(label: 'Neu', style: TagChipStyle.create, onTap: () {}));
    expect(tester.widget<FilterChip>(find.byType(FilterChip)).avatar, isNotNull);
  });

  testWidgets('selected suggested chip looks like any selected chip (check, no sparkle)', (tester) async {
    await pump(tester, TagChip(label: 'Vegan', style: TagChipStyle.suggested, selected: true, onTap: () {}));
    final chip = tester.widget<FilterChip>(find.byType(FilterChip));
    expect(chip.avatar, isNull);
    expect(chip.checkmarkColor, Colors.white);
  });

  testWidgets('tapping calls onTap', (tester) async {
    var taps = 0;
    await pump(tester, TagChip(label: 'Vegan', onTap: () => taps++));
    await tester.tap(find.byType(FilterChip));
    expect(taps, 1);
  });

  testWidgets('long labels ellipsize instead of overflowing', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: Wrap(children: [TagChip(label: 'x' * 80, onTap: () {})]),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
