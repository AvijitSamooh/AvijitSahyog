import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
