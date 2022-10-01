import 'package:hive/hive.dart';
import 'package:in_app_review/in_app_review.dart';

class AppReviewService {
  AppReviewService._();

  static late Box _eventBox;

  static const _boxKeyPlanMeal = 'planMeal';
  static const _boxKeyGrocery = 'groceryBought';
  static const _boxKeyMealCreated = 'mealCreated';

  static Future initialize() async {
    _eventBox = await Hive.openBox<dynamic>('reviewevents');
  }

  static void logPlanMeal() {
    final count = _eventBox.get(_boxKeyPlanMeal, defaultValue: 0) as int;
    _eventBox.put(_boxKeyPlanMeal, count + 1);
    _checkRequestReview();
  }

  static void logGroceryBought(bool listIsEmpty) {
    final count = _eventBox.get(_boxKeyGrocery, defaultValue: 0) as int;
    _eventBox.put(_boxKeyGrocery, count + 1);
    if (listIsEmpty) {
      _checkRequestReview();
    }
  }

  static void logMealCreated() {
    final count = _eventBox.get(_boxKeyMealCreated, defaultValue: 0) as int;
    _eventBox.put(_boxKeyMealCreated, count + 1);
    _checkRequestReview();
  }

  static void _checkRequestReview() {
    final planMealCount =
        _eventBox.get(_boxKeyPlanMeal, defaultValue: 0) as int;
    final groceryCount = _eventBox.get(_boxKeyGrocery, defaultValue: 0) as int;
    final mealCreatedCount =
        _eventBox.get(_boxKeyMealCreated, defaultValue: 0) as int;

    if (planMealCount >= 20 && groceryCount >= 50 && mealCreatedCount >= 5) {
      // delay to not request the review immediately after the action
      Future<dynamic>.delayed(const Duration(seconds: 1))
          .then((dynamic _) => _requestReview());
    }
  }

  static Future<void> _requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    }
  }
}
