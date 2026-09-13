import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../data/platform_health_repository.dart';
import '../providers/platform_health_providers.dart';

class PlatformHealthPage extends ConsumerWidget {
  const PlatformHealthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(platformHealthProvider);
    return AppPageScaffold(
      title: const Text('Platform health'),
      body: health.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(platformHealthProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(platformHealthProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatusCard(summary: data),
              const SizedBox(height: 16),
              Text('Last 24 hours', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _MetricGrid(metrics: [
                _Metric('API errors', data.errors24h, Icons.error_outline_rounded),
                _Metric('Auth failures', data.authFailures24h, Icons.lock_outline_rounded),