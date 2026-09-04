import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_media_section.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

Widget buildSubject({
  required Future<XFile?> Function() pickImage,
  required ValueChanged<List<PendingAdminMedia>> onChanged,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AdminMediaSection(
        title: 'Images',
        primaryPurpose: 'PROFILE',
        pickImage: pickImage,
        onPendingChanged: onChanged,
      ),
    ),
  );
}

void main() {
  testWidgets('selecting a primary image reports one pending primary item', (tester) async {
    var calls = 0;
    List<PendingAdminMedia> pending = [];
    await tester.pumpWidget(buildSubject(
      pickImage: () async => XFile('/tmp/primary-${++calls}.jpg'),
      onChanged: (items) => pending = items,
    ));
    await tester.tap(find.byIcon(Icons.image));
    await tester.pump();
    expect(pending, hasLength(1));
    expect(pending.single.purpose, 'PROFILE');
  });

  testWidgets('selecting primary twice replaces the existing primary image', (tester) async {
    var calls = 0;
    List<PendingAdminMedia> pending = [];
    await tester.pumpWidget(buildSubject(
      pickImage: () async => XFile('/tmp/primary-${++calls}.jpg'),
      onChanged: (items) => pending = items,
    ));
    await tester.tap(find.byIcon(Icons.image));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.image));
    await tester.pump();
    expect(pending, hasLength(1));
    expect(pending.single.file.path, '/tmp/primary-2.jpg');
  });

  testWidgets('gallery selection appends multiple gallery images', (tester) async {
    var calls = 0;
    List<PendingAdminMedia> pending = [];
    await tester.pumpWidget(buildSubject(
      pickImage: () async => XFile('/tmp/gallery-${++calls}.jpg'),
      onChanged: (items) => pending = items,
    ));
    await tester.tap(find.byIcon(Icons.add_photo_alternate));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_photo_alternate));
    await tester.pump();
    expect(pending.where((item) => item.purpose == 'GALLERY'), hasLength(2));
  });

  testWidgets('removing selected media updates pending callback', (tester) async {
    List<PendingAdminMedia> pending = [];
    await tester.pumpWidget(buildSubject(
      pickImage: () async => XFile('/tmp/primary.jpg'),
      onChanged: (items) => pending = items,
    ));
    await tester.tap(find.byIcon(Icons.image));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pump();
    expect(pending, isEmpty);
  });
}
