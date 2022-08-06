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
}
