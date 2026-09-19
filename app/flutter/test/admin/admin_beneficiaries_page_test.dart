import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:avijit_sahyog/core/network/api_client.dart';
import 'package:avijit_sahyog/features/admin/data/admin_beneficiaries_repository.dart';
import 'package:avijit_sahyog/features/admin/models/admin_beneficiary.dart';
import 'package:avijit_sahyog/features/admin/presentation/admin_beneficiaries_page.dart';
import 'package:avijit_sahyog/features/admin/providers/admin_beneficiaries_providers.dart';
import 'package:avijit_sahyog/l10n/app_localizations.dart';

class _FakeRepository extends AdminBeneficiariesRepository {
  _FakeRepository() : super(ApiClient());

  bool removeCalled = false;
  bool failRemove = false;
  int getCalls = 0;

  @override
  Future<List<AdminBeneficiary>> getBeneficiaries() async {
    getCalls++;
    return const [
        AdminBeneficiary(
          id: 'beneficiary-1',
          name: 'Rahul Kumar',
          supportedYear: 2025,
          contributionAmount: 25000,
          causeId: 'cause-1',
          isActive: true,
          displayOrder: 0,
        ),
      ];
  }

  @override
  Future<void> remove(String id) async {
    removeCalled = true;
    if (failRemove) throw Exception('delete failed');
    expect(id, 'beneficiary-1');
  }
}

void main() {
  testWidgets('admin beneficiary actions expose and confirm delete', (tester) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminBeneficiariesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminBeneficiariesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('admin_beneficiary_delete_beneficiary-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('admin_confirm_delete_beneficiary')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin_confirm_delete_beneficiary')));
    await tester.pumpAndSettle();

    expect(repository.removeCalled, isTrue);
  });
}


  testWidgets('pull-to-refresh reloads beneficiaries from the backend', (tester) async {
    final repository = _FakeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminBeneficiariesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminBeneficiariesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.getCalls, 1);
    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();

    expect(repository.getCalls, greaterThan(1));
  });

  testWidgets('shows a user-visible error when beneficiary deletion fails', (tester) async {
    final repository = _FakeRepository()..failRemove = true;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminBeneficiariesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AdminBeneficiariesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('admin_beneficiary_delete_beneficiary-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('admin_confirm_delete_beneficiary')));
    await tester.pumpAndSettle();

    expect(find.textContaining('delete failed'), findsOneWidget);
  });
