import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/features/admin/models/admin_beneficiary.dart';

void main() {
  test('parses contribution amount when backend returns a JSON string', () {
    final beneficiary = AdminBeneficiary.fromJson({
      'id': 'beneficiary-1',
      'name': 'Test beneficiary',
      'supportedYear': 2026,
      'contributionAmount': '12500.00',
      'causeId': 'cause-1',
      'organisationId': null,
      'isActive': true,
      'displayOrder': 0,
    });

    expect(beneficiary.supportedYear, 2026);
    expect(beneficiary.contributionAmount, 12500);
  });

  test('parses numeric beneficiary response values', () {
    final beneficiary = AdminBeneficiary.fromJson({
      'id': 'beneficiary-2',
      'name': 'Test beneficiary',
      'supportedYear': '2025',
      'contributionAmount': 7500.5,
      'causeId': 'cause-1',
      'organisationId': null,
      'isActive': true,
      'displayOrder': '2',
    });

    expect(beneficiary.supportedYear, 2025);
    expect(beneficiary.contributionAmount, 7500.5);
    expect(beneficiary.displayOrder, 2);
  });
}
