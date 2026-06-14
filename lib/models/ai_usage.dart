import '../constants.dart';

/// Free-plan AI usage counts for the current weekly window.
class AiUsage {
  final String periodKey;
  final int kcalUsed;
  final int textUsed;
  final int instagramUsed;

  const AiUsage({
    required this.periodKey,
    required this.kcalUsed,
    required this.textUsed,
    required this.instagramUsed,
  });

  /// Builds usage from an `ai_usage` Firestore document. When the document is
  /// missing or belongs to a past window ([currentPeriodKey] differs), counts
  /// are treated as zero so the fresh quota shows immediately at rollover.
  factory AiUsage.fromDoc(
    Map<String, dynamic>? data, {
    required String currentPeriodKey,
  }) {
    if (data == null || data['periodKey'] != currentPeriodKey) {
      return AiUsage(
        periodKey: currentPeriodKey,
        kcalUsed: 0,
        textUsed: 0,
        instagramUsed: 0,
      );
    }
    return AiUsage(
      periodKey: currentPeriodKey,
      kcalUsed: (data['kcalUsed'] as num?)?.toInt() ?? 0,
      textUsed: (data['textUsed'] as num?)?.toInt() ?? 0,
      instagramUsed: (data['instagramUsed'] as num?)?.toInt() ?? 0,
    );
  }

  int get kcalRemaining =>
      (kFreeAiKcalLimit - kcalUsed).clamp(0, kFreeAiKcalLimit);

  int get textRemaining =>
      (kFreeAiTextLimit - textUsed).clamp(0, kFreeAiTextLimit);

  int get instagramRemaining =>
      (kFreeAiInstagramLimit - instagramUsed).clamp(0, kFreeAiInstagramLimit);

  bool canUseKcal(bool isSubscribed) => isSubscribed || kcalRemaining > 0;

  bool canUseText(bool isSubscribed) => isSubscribed || textRemaining > 0;

  bool canUseInstagram(bool isSubscribed) =>
      isSubscribed || instagramRemaining > 0;
}
