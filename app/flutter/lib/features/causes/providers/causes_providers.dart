import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/causes_repository.dart';
import '../models/cause.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    authTokenProvider: () async {
      final user = FirebaseAuth.instance.currentUser;
      return user == null ? null : await user.getIdToken();
    },
  );
  ref.onDispose(client.dispose);
  return client;
});

final causesRepositoryProvider = Provider<CausesRepository>((ref) {
  return CausesRepository(ref.watch(apiClientProvider));
});

final causesProvider = FutureProvider.family<List<Cause>, String>((ref, languageCode) {
  return ref.watch(causesRepositoryProvider).getCauses(languageCode);
});

final causeProvider = FutureProvider.family<Cause, ({String slug, String languageCode})>(
  (ref, request) {
    return ref
        .watch(causesRepositoryProvider)
        .getCause(request.slug, request.languageCode);
  },
);
