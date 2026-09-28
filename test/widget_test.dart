import 'package:expense_tracker/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formatters.currency', () {
    test('formats zero', () {
      expect(Formatters.currency(0), 'Rs. 0.00');
    });

    test('keeps two decimals', () {
      expect(Formatters.currency(1250.5), 'Rs. 1,250.50');
    });

    test('adds thousands separators', () {
      expect(Formatters.currency(1234567.891), 'Rs. 1,234,567.89');
    });

    test('does not add separator under 1000', () {
      expect(Formatters.currency(999), 'Rs. 999.00');
    });

    test('rounds up across a thousand boundary', () {
      expect(Formatters.currency(999.999), 'Rs. 1,000.00');
    });
  });

  group('Formatters dates', () {
    test('date pads day and month', () {
      expect(Formatters.date(DateTime(2026, 9, 5)), '05/09/2026');
    });

    test('monthYear', () {
      expect(Formatters.monthYear(DateTime(2026, 9, 28)), 'September 2026');
    });

    test('dayHeader today and yesterday', () {
      final now = DateTime.now();
      expect(Formatters.dayHeader(now), 'Today');
      expect(
        Formatters.dayHeader(now.subtract(const Duration(days: 1))),
        'Yesterday',
      );
    });
  });
}