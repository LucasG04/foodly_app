// ignore: avoid_classes_with_only_static_members
class TimeZoneUtil {
  static int getTimeDiffToUtc() {
    final now = DateTime.now();
    return now.difference(now.toUtc()).inHours;
  }
}
