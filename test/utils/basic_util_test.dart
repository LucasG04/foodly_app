import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/grocery_group.dart';
import 'package:foodly/models/social_platform.dart';
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

  group('socialPlatformOf', () {
    test('accepts various Instagram URLs', () {
      expect(
        BasicUtils.socialPlatformOf('https://www.instagram.com/p/Cxy123_-/'),
        SocialPlatform.instagram,
      );
      expect(
        BasicUtils.socialPlatformOf(
            'https://instagram.com/reel/Cxy123?ig_sha=abc123'),
        SocialPlatform.instagram,
      );
      expect(
        BasicUtils.socialPlatformOf(
            'https://instagram.com/Cxy123?ig_sha=abc123'),
        SocialPlatform.instagram,
      );
    });

    test('accepts TikTok video and short links', () {
      for (final url in [
        'https://www.tiktok.com/@chef/video/7686516156886224161',
        'https://tiktok.com/@chef/photo/123',
        'https://vm.tiktok.com/ZGdCqSCL3/',
        'https://vt.tiktok.com/ZSabc123/',
        'https://m.tiktok.com/v/123.html',
      ]) {
        expect(BasicUtils.socialPlatformOf(url), SocialPlatform.tiktok,
            reason: url);
      }
    });

    test('rejects other hosts', () {
      expect(
        BasicUtils.socialPlatformOf('https://www.chefkoch.de/rezepte/123'),
        isNull,
      );
      expect(BasicUtils.socialPlatformOf('https://tiktok.com.evil.com/x'),
          isNull);
      expect(BasicUtils.socialPlatformOf('just some recipe text'), isNull);
      expect(BasicUtils.socialPlatformOf(''), isNull);
    });

    test('isValidUri', () {
      expect(BasicUtils.isValidUri('https://www.example.com'), isTrue);
      expect(BasicUtils.isValidUri('ftp://example.com/file.txt'), isTrue);
      expect(BasicUtils.isValidUri('not: a url'), isFalse);
      expect(BasicUtils.isValidUri('http:/invalid.com'), isFalse);
    });
  });
}
