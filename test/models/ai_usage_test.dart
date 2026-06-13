import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/constants.dart';
import 'package:foodly/models/ai_usage.dart';

void main() {
  group('AiUsage.fromDoc', () {
    test('reads counts when the period key matches', () {
      final usage = AiUsage.fromDoc(
        <String, dynamic>{
          'periodKey': '2026-06-08',
          'kcalUsed': 2,
          'textUsed': 1,
        },
        currentPeriodKey: '2026-06-08',
      );
      expect(usage.kcalUsed, 2);
      expect(usage.textUsed, 1);
    });

    test('treats counts as zero when the doc is null', () {
      final usage = AiUsage.fromDoc(null, currentPeriodKey: '2026-06-08');
      expect(usage.kcalUsed, 0);
      expect(usage.textUsed, 0);
      expect(usage.periodKey, '2026-06-08');
    });

    test('treats counts as zero for a past window (implicit reset)', () {
      final usage = AiUsage.fromDoc(
        <String, dynamic>{
          'periodKey': '2026-06-01',
          'kcalUsed': 6,
          'textUsed': 3,
        },
        currentPeriodKey: '2026-06-08',
      );
      expect(usage.kcalUsed, 0);
      expect(usage.textUsed, 0);
    });
  });

  group('AiUsage remaining', () {
    test('computes remaining against the limits', () {
      const usage = AiUsage(periodKey: 'k', kcalUsed: 2, textUsed: 1);
      expect(usage.kcalRemaining, kFreeAiKcalLimit - 2);
      expect(usage.textRemaining, kFreeAiTextLimit - 1);
    });

    test('clamps remaining at zero when over the limit', () {
      const usage = AiUsage(periodKey: 'k', kcalUsed: 99, textUsed: 99);
      expect(usage.kcalRemaining, 0);
      expect(usage.textRemaining, 0);
    });
  });

  group('AiUsage gating', () {
    test('premium can always use both features', () {
      const usage = AiUsage(periodKey: 'k', kcalUsed: 99, textUsed: 99);
      expect(usage.canUseKcal(true), isTrue);
      expect(usage.canUseText(true), isTrue);
    });

    test('free user gated once quota is exhausted', () {
      const exhausted = AiUsage(
        periodKey: 'k',
        kcalUsed: kFreeAiKcalLimit,
        textUsed: kFreeAiTextLimit,
      );
      expect(exhausted.canUseKcal(false), isFalse);
      expect(exhausted.canUseText(false), isFalse);

      const fresh = AiUsage(periodKey: 'k', kcalUsed: 0, textUsed: 0);
      expect(fresh.canUseKcal(false), isTrue);
      expect(fresh.canUseText(false), isTrue);
    });
  });
}
