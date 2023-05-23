import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/models/foodly_user.dart';
import 'package:foodly/models/foodly_user_role.dart';
import 'package:foodly/utils/permission_utils.dart';

void main() {
  group('PermissionUtils', () {
    test('allowedToModerate returns true for admin user', () {
      final user = FoodlyUser(role: FoodlyUserRole.admin);
      expect(PermissionUtils.allowedToModerate(user), isTrue);
    });

    test('allowedToModerate returns true for moderator user', () {
      final user = FoodlyUser(role: FoodlyUserRole.moderator);
      expect(PermissionUtils.allowedToModerate(user), isTrue);
    });

    test('allowedToModerate returns false for null user', () {
      expect(PermissionUtils.allowedToModerate(null), isFalse);
    });

    test('allowedToModerate returns false for regular user', () {
      final user = FoodlyUser();
      expect(PermissionUtils.allowedToModerate(user), isFalse);
    });
  });
}
