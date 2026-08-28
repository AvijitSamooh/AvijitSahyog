import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../causes/providers/causes_providers.dart';
import '../data/donations_repository.dart';

final donationRepositoryProvider = Provider<DonationsRepository>((ref) {
  return DonationsRepository(ref.watch(apiClientProvider));
});
