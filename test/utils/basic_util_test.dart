import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/grocery_group.dart';
import 'package:foodly/utils/basic_utils.dart';

void main() {
  group('sortGroceryGroups', () {
    test('should sort and add unsorted groups to end', () {
      final result = BasicUtils.sortGroceryGroups(
        [
          GroceryGroup(
            id: '1',
            name: 'A',
          ),
          GroceryGroup(
            id: '2',
            name: 'B',
          ),
          GroceryGroup(
            id: '3',
            name: 'C',
          ),
        ],
        ['2', '1'],
      );
      expect(result[0].id, '2');
      expect(result[1].id, '1');
      expect(result[2].id, '3');
    });
  });

  group('afterBuild', () {
    testWidgets('should call callback after build',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            BasicUtils.afterBuild(() {
              callbackCalled = true;
            });
            return Container();
          },
        ),
      );

      await tester.pump(); // Trigger a frame

      expect(callbackCalled, isTrue);
    });

    testWidgets('should not call callback if not mounted',
        (WidgetTester tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            BasicUtils.afterBuild(() {
              callbackCalled = true;
            }, false);
            return Container();
          },
        ),
      );

      await tester.pump(); // Trigger a frame

      expect(callbackCalled, isFalse);
    });
  });
}
