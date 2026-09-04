import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/admin_causes_repository.dart';
import '../models/admin_cause.dart';

final adminApiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    authTokenProvider: () async {
      final user = FirebaseAuth.instance.currentUser;
      return user == null ? null : await user.getIdToken();
    },
  );
  ref.onDispose(client.dispose);
  return client;
});

final adminCausesRepositoryProvider = Provider<AdminCausesRepository>((ref) {
  return AdminCausesRepository(ref.watch(adminApiClientProvider));
});

final adminCausesProvider =
    FutureProvider.autoDispose<List<AdminCause>>((ref) {
  return ref.watch(adminCausesRepositoryProvider).getCauses();
});
