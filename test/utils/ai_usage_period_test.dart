import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/utils/ai_usage_period.dart';

void main() {
  group('AiUsagePeriod', () {
    test('period key is the ISO date of the week Monday', () {
      // 2026-06-10 is a Wednesday; its week starts Monday 2026-06-08.
      expect(
        AiUsagePeriod.currentPeriodKey(DateTime.utc(2026, 6, 10)),
        '2026-06-08',
      );
    });

    test('a Monday maps to itself', () {
      expect(
        AiUsagePeriod.currentPeriodKey(DateTime.utc(2026, 6, 8)),
        '2026-06-08',
      );
    });

    test('a Sunday maps back to the same week Monday', () {
      // 2026-06-14 is a Sunday.
      expect(
        AiUsagePeriod.currentPeriodKey(DateTime.utc(2026, 6, 14)),
        '2026-06-08',
      );
    });

    test('every day of one week shares the same key', () {
      final keys = List.generate(
        7,
        (i) => AiUsagePeriod.currentPeriodKey(DateTime.utc(2026, 6, 8 + i)),
      ).toSet();
      expect(keys, <String>{'2026-06-08'});
    });

    test('period end is the following Monday', () {
      expect(
        AiUsagePeriod.currentPeriodEnd(DateTime.utc(2026, 6, 10)),
        DateTime.utc(2026, 6, 15),
      );
    });

    test('pads single-digit month and day', () {
      expect(
        AiUsagePeriod.currentPeriodKey(DateTime.utc(2026, 1, 5)),
        '2026-01-05',
      );
    });

    test('late Sunday UTC and early Monday UTC produce different keys', () {
      // 2026-06-14 is a Sunday.
      final lateSunday = DateTime.utc(2026, 6, 14, 23, 59, 59);
      final earlyMonday = DateTime.utc(2026, 6, 15, 0, 0, 1);
      expect(AiUsagePeriod.currentPeriodKey(lateSunday), '2026-06-08');
      expect(AiUsagePeriod.currentPeriodKey(earlyMonday), '2026-06-15');
    });

    test('a non-UTC-aligned local time still yields the UTC Monday key', () {
      // Same instant as 2026-06-14 23:30 UTC (a Sunday), but represented as
      // a non-UTC (local) DateTime — exercises the `now.toUtc()` conversion
      // regardless of the host machine's own timezone.
      final utcInstant = DateTime.utc(2026, 6, 14, 23, 30);
      final nonUtcNow = utcInstant.toLocal();
      expect(nonUtcNow.isUtc, isFalse);
      expect(
        AiUsagePeriod.currentPeriodKey(nonUtcNow),
        AiUsagePeriod.currentPeriodKey(utcInstant),
      );
      expect(AiUsagePeriod.currentPeriodKey(nonUtcNow), '2026-06-08');
    });

    group('daysUntilReset', () {
      // Reset for the week of 2026-06-08 is 2026-06-15 00:00 UTC. Cases are
      // anchored on its local date so they hold in any host timezone.
      final reset = DateTime.utc(2026, 6, 15).toLocal();

      test('noon on the local day before the reset is 1 (tomorrow)', () {
        // Less than 24h may remain, so this checks calendar days, not hours.
        final now = DateTime(reset.year, reset.month, reset.day - 1, 12);
        expect(AiUsagePeriod.daysUntilReset(now), 1);
      });

      test('counts local calendar days earlier in the week', () {
        final now = DateTime(reset.year, reset.month, reset.day - 6, 12);
        expect(AiUsagePeriod.daysUntilReset(now), 6);
      });

      test('accepts a UTC now', () {
        final now = DateTime(reset.year, reset.month, reset.day - 3, 12);
        expect(AiUsagePeriod.daysUntilReset(now.toUtc()), 3);
      });
    });
  });
}
