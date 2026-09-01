import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_organisations_repository.dart';
import '../models/admin_organisation.dart';
import 'admin_causes_providers.dart';

final adminOrganisationsRepositoryProvider =
    Provider<AdminOrganisationsRepository>((ref) {
  return AdminOrganisationsRepository(ref.watch(adminApiClientProvider));
});

final adminOrganisationsProvider =
    FutureProvider.autoDispose<List<AdminOrganisation>>((ref) {
  return ref.watch(adminOrganisationsRepositoryProvider).getOrganisations();
});
