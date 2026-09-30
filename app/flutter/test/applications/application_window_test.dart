import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/features/applications/models/application_window.dart';

void main() {
  test('parses a scheduled application window', () {
    final window = ApplicationWindow.fromJson({
      'type': 'PRATIBHA_SAMMAN',
      'startsAt': '2026-10-05T10:00:00.000Z',
      'closedAt': null,
      'status': 'SCHEDULED',
      'canApply': false,
    });

    expect(window.type, 'PRATIBHA_SAMMAN');
    expect(window.status, ApplicationWindowStatus.scheduled);
    expect(window.canApply, isFalse);
  });

  test('parses an open window as applicable', () {
    final window = ApplicationWindow.fromJson({
      'type': 'PRATIBHA_SAMMAN',
      'startsAt': '2026-09-01T10:00:00.000Z',
      'closedAt': null,
      'status': 'OPEN',
      'canApply': true,
    });

    expect(window.isOpen, isTrue);
  });

  test('parses a closed window and keeps the close timestamp', () {
    final window = ApplicationWindow.fromJson({
      'type': 'PRATIBHA_SAMMAN',
      'startsAt': '2026-09-01T10:00:00.000Z',
      'closedAt': '2026-09-29T10:00:00.000Z',
      'status': 'CLOSED',
      'canApply': false,
    });

    expect(window.status, ApplicationWindowStatus.closed);
    expect(window.closedAt, isNotNull);
    expect(window.isOpen, isFalse);
  });
}
