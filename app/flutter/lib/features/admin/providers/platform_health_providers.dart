import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/platform_health_repository.dart';

final platformHealthRepositoryProvider = Provider.autoDispose<PlatformHealthRepository>((ref) {
  final repository = PlatformHealthRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final platformHealthProvider = FutureProvider.autoDispose<PlatformHealthSummary>((ref) {
  return ref.watch(platformHealthRepositoryProvider).getSummary();
});
