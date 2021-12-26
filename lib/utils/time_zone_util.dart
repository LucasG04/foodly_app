class TimeZoneUtil {
  static int getTimeDiffToUtc() {
    final now = DateTime.now();
    return now.difference(now.toUtc()).inHours;
  }
}
