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

  group('isValidInstagramUrl', () {
    test('accepts various URLs', () {
      expect(
        BasicUtils.isValidInstagramUrl('https://www.instagram.com/p/Cxy123_-/'),
        isTrue,
      );
      expect(
        BasicUtils.isValidInstagramUrl(
            'https://instagram.com/reel/Cxy123?ig_sha=abc123'),
        isTrue,
      );
      expect(
        BasicUtils.isValidInstagramUrl(
            'https://instagram.com/Cxy123?ig_sha=abc123'),
        isTrue,
      );
    });

    test('rejects non-post Instagram URLs and other hosts', () {
      expect(
        BasicUtils.isValidInstagramUrl('https://www.instagram.com/some_user/'),
        isFalse,
      );
      expect(
        BasicUtils.isValidInstagramUrl('https://www.chefkoch.de/rezepte/123'),
        isFalse,
      );
      expect(BasicUtils.isValidInstagramUrl('just some recipe text'), isFalse);
      expect(BasicUtils.isValidInstagramUrl(''), isFalse);
    });
  });
}
