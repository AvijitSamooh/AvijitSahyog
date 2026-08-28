import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onLocaleChanged,
  });

  final ValueChanged<Locale> onLocaleChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient _apiClient = ApiClient();

  String _backendStatus = '';

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  Future<void> _checkBackend() async {
    try {
      final result = await _apiClient.getHealth();

      if (!mounted) return;

      setState(() {
        _backendStatus = result['status']?.toString() ?? '';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _backendStatus = 'error';
      });
    }
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final backendAvailable = _backendStatus.isNotEmpty &&
        _backendStatus != 'error';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SettingsPage(
                    onLocaleChanged: widget.onLocaleChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcome(context, l10n),

              const SizedBox(height: 28),

              _buildExploreCard(context, l10n),

              const SizedBox(height: 24),

              Text(
                l10n.yourGiving,
                style: Theme.of(context).textTheme.titleLarge,
              ),

              const SizedBox(height: 12),

              _buildComingSoonCard(context, l10n),

              const SizedBox(height: 28),

              _buildBackendStatus(
                context,
                l10n,
                backendAvailable,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcome(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.welcomeTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.welcomeSubtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
        ),
      ],
    );
  }

  Widget _buildExploreCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 42,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.causes,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeSubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                // Causes will be implemented in Iteration 2.
              },
              child: Text(l10n.exploreCauses),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(18),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.favorite_outline,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(l10n.yourGiving),
        subtitle: Text(l10n.comingSoon),
      ),
    );
  }

  Widget _buildBackendStatus(
    BuildContext context,
    AppLocalizations l10n,
    bool available,
  ) {
    final text = available
        ? l10n.backendConnected
        : _backendStatus == 'error'
            ? l10n.backendUnavailable
            : l10n.checkingBackend;

    return Row(
      children: [
        Icon(
          available ? Icons.check_circle_outline : Icons.info_outline,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}