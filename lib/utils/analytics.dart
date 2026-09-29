import 'package:faro/faro.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' as foundation;

import 'env.dart';

/// Grafana Faro (RUM, HTTP traces into lunix-api, logs, events).
/// Release builds only, like Crashlytics.
final bool faroEnabled =
    !foundation.kDebugMode && Env.faroCollectorUrl.isNotEmpty;

/// Product events. [id] is the wire name: keep it stable, dashboards and
/// Firebase history depend on it.
enum AnalyticsEvent {
  // Auth & plan
  signUp('sign_up'),
  login('login'),
  planCreate('plan_create'),
  planJoin('plan_join'),
  planLock('plan_lock'),
  leavePlan('leave_plan'),
  deleteAccount('delete_account'),
  shareCode('share_code'),
  onboardingComplete('onboarding_complete'),

  // Navigation (routes are tracked by the navigator observers)
  tabView('tab_view'),

  // Meals
  mealCreate('meal_create'),
  mealsImport('meals_import'),
  searchMealList('search_meal_list'),
  searchMealSelect('search_meal_select'),

  // AI
  aiTagSuggestionApplied('ai_tag_suggestion_applied'),
  kcalEstimate('kcal_estimate'),
  mealAssistant('meal_assistant'),
  aiQuotaExceededShown('ai_quota_exceeded_shown'),

  // Plan
  addMealToPlan('add_meal_to_plan'),
  planMealMove('plan_meal_move'),
  mealVote('meal_vote'),
  planDownload('plan_download'),

  // Shopping list
  groceryAdd('grocery_add'),
  groceryBought('grocery_bought'),
  boughtCleared('bought_cleared'),

  // Premium
  paywallView('paywall_view'),
  purchaseStart('purchase_start'),
  purchaseResult('purchase_result'),
  purchaseRestore('purchase_restore'),

  // Feedback
  feedbackSubmit('feedback_submit'),
  reviewPromptShown('review_prompt_shown'),
  reviewPromptResult('review_prompt_result'),

  // MCP
  mcpTokenCreate('mcp_token_create'),
  mcpTokenRegenerate('mcp_token_regenerate'),
  mcpTokenDelete('mcp_token_delete');

  const AnalyticsEvent(this.id);
  final String id;
}

/// Product event to Firebase Analytics and Grafana (Faro event → Loki).
/// String values only: Faro event attributes are string maps.
/// Skips Firebase when it isn't initialized (widget tests).
void logEvent(AnalyticsEvent event, [Map<String, String>? parameters]) {
  if (Firebase.apps.isNotEmpty) {
    FirebaseAnalytics.instance.logEvent(name: event.id, parameters: parameters);
  }
  if (faroEnabled) {
    Faro().pushEvent(event.id, attributes: parameters);
  }
}
