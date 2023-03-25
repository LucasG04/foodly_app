import '../models/foodly_user.dart';
import '../models/foodly_user_role.dart';

// ignore: avoid_classes_with_only_static_members
class PermissionUtils {
  static bool allowedToModerate(FoodlyUser? user) {
    if (user == null) {
      return false;
    }
    return user.role == FoodlyUserRole.admin ||
        user.role == FoodlyUserRole.moderator;
  }
}
