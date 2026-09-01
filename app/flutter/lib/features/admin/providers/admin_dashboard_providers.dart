import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/admin_dashboard_summary.dart';
import 'admin_causes_providers.dart';

final adminDashboardProvider = FutureProvider.autoDispose<AdminDashboardSummary>((ref) async {
  final ApiClient client = ref.watch(adminApiClientProvider);
  return AdminDashboardSummary.fromJson(await client.getAdminDashboardSummary());
});
