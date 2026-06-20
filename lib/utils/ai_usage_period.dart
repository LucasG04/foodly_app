/// Helpers for the free-plan AI usage weekly window.
///
/// A window is identified by the ISO date (`YYYY-MM-DD`) of its Monday. Storing
/// a plain date keeps the bucket flexible (the granularity can change later)
/// and human-readable. The reset moment is the following Monday and is always
/// derived from the clock — never persisted.
class AiUsagePeriod {
  AiUsagePeriod._();

  /// Monday 00:00 of the week containing [now] (defaults to `DateTime.now()`).
  static DateTime periodStart([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: date.weekday - DateTime.monday));
  }

  /// Stable key for the current window, e.g. `2026-06-08`.
  static String currentPeriodKey([DateTime? now]) {
    final start = periodStart(now);
    final month = start.month.toString().padLeft(2, '0');
    final day = start.day.toString().padLeft(2, '0');
    return '${start.year}-$month-$day';
  }

  /// Start of the next window — the reset moment — for the week containing [now].
  static DateTime currentPeriodEnd([DateTime? now]) =>
      periodStart(now).add(const Duration(days: 7));
}
