import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/utils/convert_util.dart';

void main() {
  group('amountToString', () {
    test('should handle normal convert with both values', () {
      final result = ConvertUtil.amountToString(1, 'kg');
      expect(result, '1 kg');
    });

    test('should handle normal convert with both values and decimal', () {
      final result = ConvertUtil.amountToString(1.5, 'kg');
      expect(result, '1.5 kg');
    });

    test('should handle normal convert with both values and decimal 0', () {
      final result = ConvertUtil.amountToString(1.0, 'kg');
      expect(result, '1 kg');
    });

    test('should handle normal convert without unit', () {
      final result = ConvertUtil.amountToString(1);
      expect(result, '1');
    });

    test('should handle normal convert with null unit', () {
      final result = ConvertUtil.amountToString(1, null);
      expect(result, '1');
    });

    test('should handle normal convert without amount', () {
      final result = ConvertUtil.amountToString(null, 'kg');
      expect(result, '0 kg');
    });

    test('should handle normal convert without both', () {
      final result = ConvertUtil.amountToString(null, null);
      expect(result, '');
    });
  });

  group('calculateServingsAmount', () {
    test('should handle null amount with 0', () {
      final result = ConvertUtil.calculateServingsAmount(
        requestedServings: 1,
        mealServings: 1,
      );
      expect(result, 0);
    });
    test('should handle 0 requestedServings with amount', () {
      final result = ConvertUtil.calculateServingsAmount(
        requestedServings: 1,
        mealServings: 0,
        amount: 5,
      );
      expect(result, 5);
    });
    test('should calculate correct amount', () {
      final result = ConvertUtil.calculateServingsAmount(
        requestedServings: 5,
        mealServings: 1,
        amount: 100,
      );
      expect(result, 500);
    });
    test('should calculate correct amount with decimal places', () {
      final result = ConvertUtil.calculateServingsAmount(
        requestedServings: 1,
        mealServings: 3,
        amount: 1,
      );
      expect(result, 0.33);
    });
  });
}
