import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/advanced_analytics_repository.dart';
import '../models/advanced_analytics_summary.dart';

final advancedAnalyticsRepositoryProvider = Provider<AdvancedAnalyticsRepository>((ref) {
  final repository = AdvancedAnalyticsRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final advancedAnalyticsProvider = FutureProvider.autoDispose<AdvancedAnalyticsSummary>((ref) => ref.watch(advancedAnalyticsRepositoryProvider).getSummary());
