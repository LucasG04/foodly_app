import 'package:flutter_test/flutter_test.dart';
import 'package:foodly/utils/debouncer.dart';

void main() {
  group('Debouncer', () {
    test('should run the action after the specified time', () async {
      final debouncer = Debouncer(milliseconds: 100);
      var counter = 0;

      debouncer.run(() {
        counter++;
      });

      await Future<dynamic>.delayed(const Duration(milliseconds: 50));
      expect(counter, 0);

      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      expect(counter, 1);

      debouncer.dispose();
    });

    test('should cancel the previous action if a new one is run', () async {
      final debouncer = Debouncer(milliseconds: 100);
      var counter = 0;

      debouncer.run(() {
        counter++;
      });

      await Future<dynamic>.delayed(const Duration(milliseconds: 50));
      expect(counter, 0);

      debouncer.run(() {
        counter++;
      });

      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      expect(counter, 1);

      debouncer.dispose();
    });

    test('should cancel the timer when disposed', () async {
      final debouncer = Debouncer(milliseconds: 100);
      var counter = 0;

      debouncer.run(() {
        counter++;
      });

      await Future<dynamic>.delayed(const Duration(milliseconds: 50));
      expect(counter, 0);

      debouncer.dispose();

      await Future<dynamic>.delayed(const Duration(milliseconds: 100));
      expect(counter, 0);
    });
  });
}
