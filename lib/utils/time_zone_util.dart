class TimeZoneUtil {
  static int getTimeDiffToUtc() {
    final now = new DateTime.now();
    return now.difference(now.toUtc()).inHours;
  }
}
