/// Free-plan AI limits per weekly window, served by the backend
/// (`GET /foodly/ai-limits`) as the single source of truth.
class AiLimits {
  final int text;

  /// Instagram and TikTok imports together.
  final int social;
  final int kcal;

  const AiLimits({
    required this.text,
    required this.social,
    required this.kcal,
  });

  factory AiLimits.fromMap(Map<String, dynamic> map) => AiLimits(
        text: (map['text'] as num).toInt(),
        // Named before TikTok joined; it is the shared social quota.
        social: (map['instagram'] as num).toInt(),
        kcal: (map['kcal'] as num).toInt(),
      );
}

/// Free-plan AI usage counts for the current weekly window.
class AiUsage {
  final String periodKey;
  final int kcalUsed;
  final int textUsed;

  /// Instagram and TikTok imports together.
  final int socialUsed;
  final AiLimits limits;

  const AiUsage({
    required this.periodKey,
    required this.kcalUsed,
    required this.textUsed,
    required this.socialUsed,
    required this.limits,
  });

  /// Builds usage from an `aiUsage` Firestore document. When the document is
  /// missing or belongs to a past window ([currentPeriodKey] differs), counts
  /// are treated as zero so the fresh quota shows immediately at rollover.
  factory AiUsage.fromDoc(
    Map<String, dynamic>? data, {
    required String currentPeriodKey,
    required AiLimits limits,
  }) {
    if (data == null || data['periodKey'] != currentPeriodKey) {
      return AiUsage(
        periodKey: currentPeriodKey,
        kcalUsed: 0,
        textUsed: 0,
        socialUsed: 0,
        limits: limits,
      );
    }
    return AiUsage(
      periodKey: currentPeriodKey,
      kcalUsed: (data['kcalUsed'] as num?)?.toInt() ?? 0,
      textUsed: (data['textUsed'] as num?)?.toInt() ?? 0,
      // Stored as `instagramUsed` from before TikTok joined.
      socialUsed: (data['instagramUsed'] as num?)?.toInt() ?? 0,
      limits: limits,
    );
  }

  int get kcalRemaining => (limits.kcal - kcalUsed).clamp(0, limits.kcal);

  int get textRemaining => (limits.text - textUsed).clamp(0, limits.text);

  int get socialRemaining =>
      (limits.social - socialUsed).clamp(0, limits.social);

  bool canUseKcal(bool isSubscribed) => isSubscribed || kcalRemaining > 0;

  bool canUseText(bool isSubscribed) => isSubscribed || textRemaining > 0;

  bool canUseSocial(bool isSubscribed) => isSubscribed || socialRemaining > 0;
}
