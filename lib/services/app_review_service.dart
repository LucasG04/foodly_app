import 'package:in_app_review/in_app_review.dart';
import 'package:isar/isar.dart';

import 'storage_service.dart';

part 'app_review_service.g.dart';

@collection
class AppReviewData {
  Id id = Isar.autoIncrement;

  int? planMeal;
  int? groceryBought;
  int? mealCreated;
  DateTime? lastRequest;
  bool? hasRated;
}

class AppReviewService {
  AppReviewService._();

  static late Isar _isar;

  static Future initialize() async {
    _isar = await StorageService.getIsar();
  }

  static AppReviewData _getReview() {
    return _isar.appReviewDatas.where().findFirstSync() ?? AppReviewData();
  }

  static Future<void> _updateReview(void Function(AppReviewData) update) async {
    await _isar.writeTxn(() async {
      var review = _isar.appReviewDatas.where().findFirstSync() ?? AppReviewData();
      update(review);
      await _isar.appReviewDatas.put(review);
    });
  }

  static Stream<bool> shouldRequestReview() async* {
    await for (final _ in _isar.appReviewDatas.watchLazy()) {
      final review = _getReview();
      if (review.hasRated ?? false) {
        yield false;
        continue;
      }

      final planMealCount = review.planMeal ?? 0;
      final groceryCount = review.groceryBought ?? 0;
      final mealCreatedCount = review.mealCreated ?? 0;

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
      await _updateReview((review) {
        review.hasRated = true;
      });
    }
  }

  /// Resets all counters and flags. Used for testing.
  static void reset() {
    _updateReview((review) {
      review.lastRequest = DateTime.now().subtract(const Duration(days: 70));
      review.hasRated = false;
      review.planMeal = 20;
      review.groceryBought = 50;
      review.mealCreated = 5;
    });
  }

  static void discardRequest() {
    _updateReview((review) {
      review.lastRequest = DateTime.now();
    });
  }

  static void logPlanMeal() {
    _updateReview((review) {
      review.planMeal = (review.planMeal ?? 0) + 1;
    });
  }

  static void logGroceryBought(bool listIsEmpty) {
    _updateReview((review) {
      review.groceryBought = (review.groceryBought ?? 0) + 1;
    });
  }

  static void logMealCreated() {
    _updateReview((review) {
      review.mealCreated = (review.mealCreated ?? 0) + 1;
    });
  }

  static Duration get _timeSinceLastReviewRequest {
    final review = _getReview();
    final lastRequest = review.lastRequest;
    if (lastRequest == null) {
      return const Duration(days: 60);
    }
    return DateTime.now().difference(lastRequest);
  }
}
