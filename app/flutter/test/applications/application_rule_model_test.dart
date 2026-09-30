import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/features/applications/models/application_rule.dart';

void main() {
  test('parses a localized application rule', () {
    final rule = ApplicationRule.fromJson({
      'id': 'rule-1',
      'type': 'PRATIBHA_SAMMAN',
      'displayOrder': 2,
      'text': 'Candidate must be from Pune.',
    });

    expect(rule.id, 'rule-1');
    expect(rule.type, 'PRATIBHA_SAMMAN');
    expect(rule.displayOrder, 2);
    expect(rule.text, 'Candidate must be from Pune.');
  });
}
