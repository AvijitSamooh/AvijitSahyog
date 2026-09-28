import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/service_window.dart';

void main() {
  group('ServiceWindow', () {
    final overnight = serviceWindowForTest();

    test('blocks during the overnight window', () {
      expect(overnight.isDowntime(DateTime(2026, 9, 28, 21, 0)), isTrue);
      expect(overnight.isDowntime(DateTime(2026, 9, 29, 1, 30)), isTrue);
      expect(overnight.isDowntime(DateTime(2026, 9, 29, 7, 59)), isTrue);
    });

    test('allows service at and after the morning boundary', () {
      expect(overnight.isDowntime(DateTime(2026, 9, 29, 8, 0)), isFalse);
      expect(overnight.isDowntime(DateTime(2026, 9, 29, 12, 0)), isFalse);
      expect(overnight.isDowntime(DateTime(2026, 9, 28, 20, 59)), isFalse);
    });

    test('can be disabled without changing the configured times', () {
      final disabled = serviceWindowForTest(enabled: false);
      expect(disabled.isDowntime(DateTime(2026, 9, 28, 23, 0)), isFalse);
    });

    test('supports a daytime window as well', () {
      final daytime = serviceWindowForTest(start: '13:00', end: '14:00');
      expect(daytime.isDowntime(DateTime(2026, 9, 28, 12, 59)), isFalse);
      expect(daytime.isDowntime(DateTime(2026, 9, 28, 13, 30)), isTrue);
      expect(daytime.isDowntime(DateTime(2026, 9, 28, 14, 0)), isFalse);
    });
  });
}
