import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../l10n/app_localizations.dart';

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

    final selectedLocale = await showDialog<Locale>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.language),
        children: [
          _languageOption(context, l10n.languageEnglish, 'en', currentLocale),
          _languageOption(context, l10n.languageHindi, 'hi', currentLocale),
          _languageOption(context, l10n.languageMarathi, 'mr', currentLocale),
          _languageOption(context, l10n.languageGujarati, 'gu', currentLocale),
        ],
      ),
    );

    if (selectedLocale != null) {
      widget.onLocaleChanged(selectedLocale);
    }
  }

  Widget _languageOption(
    BuildContext context,
    String label,
    String languageCode,
    String currentLocale,
  ) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, Locale(languageCode)),
      child: Row(
        children: [
          Icon(
            languageCode == currentLocale
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            tooltip: l10n.language,
            icon: const Icon(Icons.language),
            onPressed: _showLanguageSelector,
          ),
        ],
      ),
      body: Center(
        child: _isCheckingBackend
            ? Text(l10n.checkingBackend)
            : _status == null
                ? Text(l10n.backendUnavailable)
                : Text(
                    l10n.backendStatus(
                      _status!.split(' — ').first,
                      _status!.split(' — ').skip(1).join(' — '),
                    ),
                    textAlign: TextAlign.center,
                  ),
      ),
    );
  }
}
