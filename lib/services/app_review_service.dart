import 'dart:math' as math;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

import '../utils/analytics.dart';

/// Asks for a store review with the system prompt right when the user
/// completes the plan-and-shop loop (list done, a few meals planned), never behind
/// an "Enjoying it?" question: Google forbids that gating, and people rate
/// the moment. Saving dishes doesn't count: new users do that while setting
/// up, before the app proved itself.
///
/// Review prompt and Plus upsells share the app session: the review is asked
/// at most once, and not after something went wrong, a quota ran out or the
/// paywall showed.
class AppReviewService {
  AppReviewService._();

  static late Box _eventBox;

  static const _boxKeySuccessDays = 'successDays';
  static const _boxKeyMealsPlanned = 'mealsPlanned';
  static const _boxKeyFirstSeen = 'firstSeen';
  static const _boxKeyLastRequest = 'lastRequest';
  // Set by the former in-app rating banner; those users aren't asked again.
  static const _boxKeyHasRated = 'hasRated';

  /// Different days with a completed loop before the first ask.
  static const _minSuccessDays = 2;

  /// Meals the user adds to the plan per success moment, about a week's
  /// dinners.
  static const _mealsPerSuccess = 5;

  /// Use of the app before the first ask, counted from the first start that
  /// recorded it.
  static const _minTenure = Duration(days: 14);
  static const _cooldown = Duration(days: 120);

  static bool _skipSession = false;
  static bool _requested = false;

  static Future initialize() async {
    _eventBox = await Hive.openBox<dynamic>('reviewevents');
    if (!_eventBox.containsKey(_boxKeyFirstSeen)) {
      await _eventBox.put(_boxKeyFirstSeen, DateTime.now());
    }
  }

  /// Whether the review prompt was requested this session; Plus upsells hold
  /// back then.
  static bool get requestedThisSession => _requested;

  /// No review prompt for the rest of the session: something went wrong, a
  /// quota ran out or the paywall showed.
  static void skipThisSession() => _skipSession = true;

  /// Counts a meal the user added to the plan; every [_mealsPerSuccess]th is
  /// a success moment.
  static void logMealPlanned() {
    final count =
        (_eventBox.get(_boxKeyMealsPlanned, defaultValue: 0) as int) + 1;
    _eventBox.put(_boxKeyMealsPlanned, count % _mealsPerSuccess);
    if (count == _mealsPerSuccess) {
      logSuccess('meals_planned');
    }
  }

  /// Counts a completed loop [moment] and asks for a review once there were
  /// some on [_minSuccessDays] different days after [_minTenure] of use.
  static Future<void> logSuccess(String moment) async {
    final now = DateTime.now();
    final today = now.toIso8601String().substring(0, 10);
    final days = {
      ...(_eventBox.get(_boxKeySuccessDays, defaultValue: <dynamic>[]) as List)
          .cast<String>(),
      today,
    }.toList();
    await _eventBox.put(
      _boxKeySuccessDays,
      days.sublist(math.max(0, days.length - _minSuccessDays)),
    );

    final firstSeen = _eventBox.get(_boxKeyFirstSeen) as DateTime;
    final lastRequest = _eventBox.get(_boxKeyLastRequest) as DateTime?;
    final hasRated =
        _eventBox.get(_boxKeyHasRated, defaultValue: false) as bool;
    if (_skipSession ||
        _requested ||
        hasRated ||
        days.length < _minSuccessDays ||
        now.difference(firstSeen) < _minTenure ||
        (lastRequest != null && now.difference(lastRequest) < _cooldown)) {
      return;
    }
    final inAppReview = InAppReview.instance;
    if (!await inAppReview.isAvailable()) {
      return;
    }
    _requested = true;
    await _eventBox.put(_boxKeyLastRequest, DateTime.now());
    await _eventBox.put(_boxKeySuccessDays, <String>[]);
    logEvent(AnalyticsEvent.reviewPromptShown, {'moment': moment});
    await inAppReview.requestReview();
  }
}
