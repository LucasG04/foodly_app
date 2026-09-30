import 'package:easy_localization/easy_localization.dart';

class RateLimitException implements Exception {
  final int retryAfterSeconds;

  const RateLimitException({required this.retryAfterSeconds});

  /// Localized "try again in 1 hour and 5 minutes".
  String get message {
    final total = (retryAfterSeconds / 60).ceil();
    final hours = 'ai_rate_limit_hours'.plural(total ~/ 60);
    final minutes = 'ai_rate_limit_minutes'.plural(total % 60);
    final String duration;
    if (total < 60) {
      duration = minutes;
    } else if (total % 60 == 0) {
      duration = hours;
    } else {
      duration = 'ai_rate_limit_hours_minutes'.tr(args: [hours, minutes]);
    }
    return 'ai_rate_limit'.tr(args: [duration]);
  }

  @override
  String toString() =>
      'RateLimitException: retry after $retryAfterSeconds seconds';
}
