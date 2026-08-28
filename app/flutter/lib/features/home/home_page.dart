import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../l10n/app_localizations.dart';
import '../causes/presentation/causes_page.dart';

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

  String? _status;
  bool _isCheckingBackend = true;

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
        _status = '${result['status']} — ${result['service']}';
        _isCheckingBackend = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _status = null;
        _isCheckingBackend = false;
      });
    }
  }

  Future<void> _showLanguageSelector() async {
    final l10n = AppLocalizations.of(context)!;
    final currentLocale = Localizations.localeOf(context).languageCode;

    final selectedLocale = await showModalBottomSheet<Locale>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _LanguageSheet(
        l10n: l10n,
        currentLocale: currentLocale,
      ),
    );

    if (selectedLocale != null) {
      widget.onLocaleChanged(selectedLocale);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.language,
            icon: const Icon(Icons.language_rounded),
            onPressed: _showLanguageSelector,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkBackend,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6E1A14), Color(0xFF4C120D)],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFC89B3C)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✦',
                    style: TextStyle(
                      color: Color(0xFFF5A623),
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.welcomeTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.welcomeSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.88),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF5A623),
                        foregroundColor: const Color(0xFF4C120D),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CausesPage()),
                        );
                      },
                      icon: const Icon(Icons.volunteer_activism_rounded),
                      label: Text(l10n.causesTitle),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _QuickInfoCard(
                    icon: Icons.favorite_rounded,
                    title: l10n.causesTitle,
                    subtitle: l10n.affiliatedOrganisations,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickInfoCard(
                    icon: Icons.translate_rounded,
                    title: l10n.language,
                    subtitle: Localizations.localeOf(context)
                        .languageCode
                        .toUpperCase(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCE8C9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.cloud_done_rounded,
                        color: Color(0xFF6E1A14),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _isCheckingBackend
                          ? Text(l10n.checkingBackend)
                          : _status == null
                              ? Text(l10n.backendUnavailable)
                              : Text(
                                  l10n.backendStatus(
                                    _status!.split(' — ').first,
                                    _status!.split(' — ').skip(1).join(' — '),
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickInfoCard extends StatelessWidget {
  const _QuickInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF6E1A14)),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.l10n,
    required this.currentLocale,
  });

  final AppLocalizations l10n;
  final String currentLocale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8ED),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBB083),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 18),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.language,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 8),
            _option(context, l10n.languageEnglish, 'en'),
            _option(context, l10n.languageHindi, 'hi'),
            _option(context, l10n.languageMarathi, 'mr'),
            _option(context, l10n.languageGujarati, 'gu'),
          ],
        ),
      ),
    );
  }

  Widget _option(BuildContext context, String label, String code) {
    final selected = code == currentLocale;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? const Color(0xFF6E1A14) : const Color(0xFF9A574C),
      ),
      title: Text(label),
      onTap: () => Navigator.pop(context, Locale(code)),
    );
  }
}
