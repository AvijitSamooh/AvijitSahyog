import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_analytics_repository.dart';
import '../models/admin_analytics_summary.dart';

final adminAnalyticsRepositoryProvider = Provider<AdminAnalyticsRepository>((ref) {
  final repository = AdminAnalyticsRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

final adminAnalyticsProvider =
    FutureProvider.autoDispose<AdminAnalyticsSummary>((ref) {
  return ref.watch(adminAnalyticsRepositoryProvider).getSummary();
});
