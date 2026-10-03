import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avijit_sahyog/core/navigation/app_shell_scope.dart';
import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/applications/data/help_applications_repository.dart';
import 'package:avijit_sahyog/features/applications/presentation/admin_applications_page.dart';
import 'package:avijit_sahyog/features/applications/providers/help_applications_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

class _FakeRepository extends HelpApplicationsRepository {
  _FakeRepository() : super(ApiClient());

  @override
  Future<List<Map<String, dynamic>>> adminList({String? type, String? status}) async => const [];

  @override
  Future<Map<String, dynamic>> adminSummary({String? type}) async => const {
    'total': 50,
    'needsReview': 0,
    'selected': 50,
    'rejected': 0,
  };

  @override
  Future<Map<String, dynamic>> createCertificatePhotoExport({String? type, String? status}) async => const {
    'total': 50,
    'available': 49,
    'missing': [
      {'id': 'app-50', 'name': 'Missing Photo Student'},
    ],
    'downloadPath': '/exports/certificate-photos?token=test',
  };
}

void main() {
  testWidgets('admin exposes certificate photo export and flags missing photos', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          helpApplicationsRepositoryProvider.overrideWithValue(_FakeRepository()),
        ],
        child: AppShellScope(
        onLocaleChanged: (_) {},
        navigation: AppNavigationController(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: ThemeData(useMaterial3: true),
          home: const AdminApplicationsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final exportButton = find.byKey(const ValueKey('admin_application_certificate_photo_export'));
    expect(exportButton, findsOneWidget);
    await tester.tap(exportButton);
    await tester.pumpAndSettle();

    expect(find.text('Export Certificate Photos'), findsOneWidget);
    expect(find.text('Ready certificate photos: 49 / 50'), findsOneWidget);
    expect(find.text('Missing Photo Student'), findsOneWidget);
  });
}
