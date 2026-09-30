import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/home/presentation/brand_splash_page.dart';
import 'core/analytics/analytics_service.dart';
import 'core/network/api_client.dart';
import 'core/service_window.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_shell_scope.dart';
import 'features/impact/presentation/impact_page.dart';

import 'l10n/app_localizations.dart';

class AvijitSahyogApp extends StatefulWidget {
  const AvijitSahyogApp({super.key, this.splashDuration = const Duration(seconds: 5)});

  final Duration splashDuration;

  @override
  State<AvijitSahyogApp> createState() => _AvijitSahyogAppState();
}

class _AvijitSahyogAppState extends State<AvijitSahyogApp> {
  static const _localeKey = 'selected_locale';

  Locale? _locale;
  Timer? _serviceWindowTimer;
  bool _serviceWindowActive = BackendServiceAvailability.isDowntime;
  bool _serviceWindowMessageVisible = false;
  final _navigation = AppNavigationController();

  @override
  void initState() {
    super.initState();
    _loadLocale();
    _serviceWindowTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      final active = BackendServiceAvailability.isDowntime;
      if (mounted && active != _serviceWindowActive) {
        setState(() => _serviceWindowActive = active);
      }
    });
  }

  @override
  void dispose() {
    _serviceWindowTimer?.cancel();
    _navigation.dispose();
    super.dispose();
  }

  Future<void> _loadLocale() async {
    final preferences = await SharedPreferences.getInstance();
    final languageCode = preferences.getString(_localeKey);
    if (!mounted || languageCode == null) return;

    final supportedCodes = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();

    if (supportedCodes.contains(languageCode)) {
      setState(() => _locale = Locale(languageCode));
    }
  }

  Future<void> setLocale(Locale locale) async {
    setState(() => _locale = locale);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, locale.languageCode);
  }

  ThemeData _buildTheme() => AppTheme.light();
  void _showServiceUnavailableMessage() {
    if (!_serviceWindowMessageVisible) {
      setState(() => _serviceWindowMessageVisible = true);
    }
  }

  Widget _buildServiceWindowOverlay(BuildContext context) {
    if (!_serviceWindowActive) return const SizedBox.shrink();

    final localizations = AppLocalizations.of(context)!;

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showServiceUnavailableMessage,
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              right: 12,
              child: IgnorePointer(
                child: Material(
                  elevation: 4,
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.nightlight_round,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            localizations.serviceUnavailableBanner(
                              BackendServiceAvailability.startLabel,
                              BackendServiceAvailability.endLabel,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_serviceWindowMessageVisible)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black26,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        margin: const EdgeInsets.all(24),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.serviceUnavailableTitle,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                localizations.serviceUnavailableMessage(
                                  BackendServiceAvailability.startLabel,
                                  BackendServiceAvailability.endLabel,
                                ),
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => setState(
                                    () => _serviceWindowMessageVisible = false,
                                  ),
                                  child: Text(localizations.serviceUnavailableDismiss),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analyticsObserver = AnalyticsService.instance.observer;

    return MaterialApp(
      locale: _locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: _buildTheme(),
      navigatorObservers: [
        ?analyticsObserver,
      ],
      builder: (context, child) => AppShellScope(
        onLocaleChanged: setLocale,
        navigation: _navigation,
        child: Stack(
          children: [
            child!,
            _buildServiceWindowOverlay(context),
            ValueListenableBuilder<int>(
              valueListenable: ApiClient.activeRequests,
              builder: (context, active, _) {
                final busy = active > 0;
                return IgnorePointer(
                  ignoring: true,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: busy
                        ? ColoredBox(
                            key: const ValueKey('backend_busy'),
                            color: Colors.black12,
                            child: Center(
                              child: Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(strokeWidth: 3),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('backend_idle'),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      home: BrandSplashPage(duration: widget.splashDuration),
      routes: {
        '/impact': (_) => const ImpactPage(),
      },
    );
  }
}
