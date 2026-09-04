import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/features/causes/models/organisation.dart';

void main() {
  test('organisation model parses dynamic logo and gallery media', () {
    final organisation = Organisation.fromJson({
      'id': 'org-1',
      'slug': 'animal-care',
      'name': 'Animal Care',
      'logoUrl': 'https://images.example.com/logo.webp',
      'gallery': [
        {'id': 'm-1', 'url': 'https://images.example.com/1.webp'},
        {'id': 'm-2', 'url': 'https://images.example.com/2.webp'},
      ],
    });

    expect(organisation.logoUrl, 'https://images.example.com/logo.webp');
    expect(organisation.gallery, hasLength(2));
  });
}
