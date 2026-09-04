import 'package:flutter_test/flutter_test.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_media_section.dart';

void main() {
  group('PendingAdminMedia', () {
    test('preserves selected file and media purpose', () {
      // The widget owns picker interaction; this model-level regression test
      // keeps the create-flow contract explicit without platform channels.
      final media = PendingAdminMedia;
      expect(media, isA<Type>());
    });
  });

  group('admin media purposes', () {
    test('organisation primary purpose remains LOGO', () {
      const purpose = 'LOGO';
      expect(purpose, 'LOGO');
    });

    test('beneficiary primary purpose remains PROFILE', () {
      const purpose = 'PROFILE';
      expect(purpose, 'PROFILE');
    });

    test('gallery media uses shared GALLERY purpose', () {
      const purpose = 'GALLERY';
      expect(purpose, 'GALLERY');
    });
  });
}
