import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/service_window.dart';

void main() {
  group('ServiceWindow', () {
    final overnight = ServiceWindow(enabled: true, startMinutes: 21 * 60, endMinutes: 8 * 60, startLabel: '9:00 PM', endLabel: '8:00 AM');

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
      final disabled = ServiceWindow(enabled: false, startMinutes: 21 * 60, endMinutes: 8 * 60, startLabel: '9:00 PM', endLabel: '8:00 AM');
      expect(disabled.isDowntime(DateTime(2026, 9, 28, 23, 0)), isFalse);
    });



    test('reads the explicit offline environment window', () {
      final configured = ServiceWindow.fromEnvironment();

      expect(configured.startLabel, '9:00 PM');
      expect(configured.endLabel, '8:00 AM');
    });

    test('normalizes a reversed configured overnight window', () {
      final normalized = ServiceWindow.fromLabels(
        enabled: true,
        startLabel: '08:00',
        endLabel: '21:00',
      );

      expect(normalized.startLabel, '9:00 PM');
      expect(normalized.endLabel, '8:00 AM');
      expect(normalized.isDowntime(DateTime(2026, 9, 30, 23, 0)), isTrue);
      expect(normalized.isDowntime(DateTime(2026, 10, 1, 7, 59)), isTrue);
      expect(normalized.isDowntime(DateTime(2026, 10, 1, 12, 0)), isFalse);
    });

    test('supports a daytime window as well', () {
      final daytime = ServiceWindow(enabled: true, startMinutes: 13 * 60, endMinutes: 14 * 60, startLabel: '1:00 PM', endLabel: '2:00 PM');
      expect(daytime.isDowntime(DateTime(2026, 9, 28, 12, 59)), isFalse);
      expect(daytime.isDowntime(DateTime(2026, 9, 28, 13, 30)), isTrue);
      expect(daytime.isDowntime(DateTime(2026, 9, 28, 14, 0)), isFalse);
    });
  });
}
