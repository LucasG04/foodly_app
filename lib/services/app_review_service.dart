import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

class AppReviewService {
  AppReviewService._();

  static late Box _eventBox;

  static const _boxKeyPlanMeal = 'planMeal';
  static const _boxKeyGrocery = 'groceryBought';
  static const _boxKeyMealCreated = 'mealCreated';
  static const _boxKeyLastRequest = 'lastRequest';
  static const _boxKeyHasRated = 'hasRated';

  static Future initialize() async {
    _eventBox = await Hive.openBox<dynamic>('reviewevents');
  }

  static Stream<bool> shouldRequestReview() async* {
    await for (final _ in _eventBox.watch()) {
      if (_eventBox.get(_boxKeyHasRated, defaultValue: false) as bool) {
        yield false;
        continue;
      }

      final planMealCount =
          _eventBox.get(_boxKeyPlanMeal, defaultValue: 0) as int;
      final groceryCount =
          _eventBox.get(_boxKeyGrocery, defaultValue: 0) as int;
      final mealCreatedCount =
          _eventBox.get(_boxKeyMealCreated, defaultValue: 0) as int;

      yield planMealCount >= 20 &&
          groceryCount >= 50 &&
          mealCreatedCount >= 5 &&
          _timeSinceLastReviewRequest.inDays >= 60;
    }
  }

  static Future<void> requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
      _eventBox.put(_boxKeyHasRated, true);
    }
  }

  /// Resets all counters and flags. Used for testing.
  static void reset() {
    _eventBox.put(
        _boxKeyLastRequest, DateTime.now().subtract(const Duration(days: 70)));
    _eventBox.put(_boxKeyHasRated, false);
    _eventBox.put(_boxKeyPlanMeal, 20);
    _eventBox.put(_boxKeyGrocery, 50);
    _eventBox.put(_boxKeyMealCreated, 5);
  }

  static void discardRequest() {
    _eventBox.put(_boxKeyLastRequest, DateTime.now());
  }

  static void logPlanMeal() {
    final count = _eventBox.get(_boxKeyPlanMeal, defaultValue: 0) as int;
    _eventBox.put(_boxKeyPlanMeal, count + 1);
  }

  static void logGroceryBought(bool listIsEmpty) {
    final count = _eventBox.get(_boxKeyGrocery, defaultValue: 0) as int;
    _eventBox.put(_boxKeyGrocery, count + 1);
  }

  static void logMealCreated() {
    final count = _eventBox.get(_boxKeyMealCreated, defaultValue: 0) as int;
    _eventBox.put(_boxKeyMealCreated, count + 1);
  }

  static Duration get _timeSinceLastReviewRequest {
    final lastRequest = _eventBox.get(_boxKeyLastRequest) as DateTime?;
    if (lastRequest == null) {
      return const Duration(days: 60);
    }
    return DateTime.now().difference(lastRequest);
  }
}
