import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/utils/ai_usage_period.dart';

void main() {
  group('AiUsagePeriod', () {
    test('period key is the ISO date of the week Monday', () {
      // 2026-06-10 is a Wednesday; its week starts Monday 2026-06-08.
      expect(
        AiUsagePeriod.currentPeriodKey(DateTime(2026, 6, 10)),
        '2026-06-08',
      );
    });

    test('a Monday maps to itself', () {
      expect(
        AiUsagePeriod.currentPeriodKey(DateTime(2026, 6, 8)),
        '2026-06-08',
      );
    });

    test('a Sunday maps back to the same week Monday', () {
      // 2026-06-14 is a Sunday.
      expect(
        AiUsagePeriod.currentPeriodKey(DateTime(2026, 6, 14)),
        '2026-06-08',
      );
    });

    test('every day of one week shares the same key', () {
      final keys = List.generate(
        7,
        (i) => AiUsagePeriod.currentPeriodKey(DateTime(2026, 6, 8 + i)),
      ).toSet();
      expect(keys, <String>{'2026-06-08'});
    });

    test('period end is the following Monday', () {
      expect(
        AiUsagePeriod.currentPeriodEnd(DateTime(2026, 6, 10)),
        DateTime(2026, 6, 15),
      );
    });

    test('pads single-digit month and day', () {
      expect(
        AiUsagePeriod.currentPeriodKey(DateTime(2026, 1, 5)),
        '2026-01-05',
      );
    });
  });
}
