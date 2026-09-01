import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_beneficiaries_repository.dart';
import '../models/admin_beneficiary.dart';
import 'admin_causes_providers.dart';

final adminBeneficiariesRepositoryProvider =
    Provider<AdminBeneficiariesRepository>((ref) {
  return AdminBeneficiariesRepository(ref.watch(adminApiClientProvider));
});

final adminBeneficiariesProvider =
    FutureProvider.autoDispose<List<AdminBeneficiary>>((ref) {
  return ref.watch(adminBeneficiariesRepositoryProvider).getBeneficiaries();
});
