import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../causes/providers/causes_providers.dart';
import '../data/beneficiaries_repository.dart';
import '../models/beneficiary.dart';

final beneficiariesRepositoryProvider = Provider<BeneficiariesRepository>((ref) {
  return BeneficiariesRepository(ref.watch(apiClientProvider));
});

final beneficiariesProvider = FutureProvider.autoDispose.family<List<Beneficiary>, ({String? search, String? sort})>((ref, query) {
  return ref.watch(beneficiariesRepositoryProvider).getBeneficiaries(search: query.search, sort: query.sort);
});
