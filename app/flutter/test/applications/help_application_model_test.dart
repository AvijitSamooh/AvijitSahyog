import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/features/applications/models/help_application.dart';

void main() {
  test('parses assistance application status, amounts and evidence', () {
    final application = HelpApplication.fromJson({
      'id': 'app-1',
      'type': 'EDUCATION_ASSISTANCE',
      'status': 'APPROVED_FOR_DONATION',
      'requestedAmount': 25000,
      'approvedAmount': 18000,
      'media': [
        {
          'id': 'media-1',
          'url': 'https://example.com/evidence.webp',
          'mimeType': 'image/webp',
        },
      ],
    });

    expect(application.requestedAmount, 25000);
    expect(application.approvedAmount, 18000);
    expect(application.status, 'APPROVED_FOR_DONATION');
    expect(application.media.single.id, 'media-1');
  });

  test('keeps Pratibha Samman applications distinct from assistance', () {
    final application = HelpApplication.fromJson({
      'id': 'app-2',
      'type': 'PRATIBHA_SAMMAN',
      'status': 'CONSIDERED_FOR_SAMMAN',
      'media': [],
    });

    expect(application.type, 'PRATIBHA_SAMMAN');
    expect(application.typeLabel, 'pratibhaSamman');
  });
}
