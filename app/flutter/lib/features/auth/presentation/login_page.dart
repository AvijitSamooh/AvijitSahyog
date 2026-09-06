import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/app_settings_menu.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authProvider);
    final l10n = AppLocalizations.of(context)!;

    ref.listen(authProvider, (_, next) {
      if (next.isAuthenticated && context.mounted) {
        Navigator.of(context).pop();
      }
      if (next.errorMessage != null && context.mounted) {
        final message = switch (next.errorMessage) {
          'authNotConfigured' => l10n.authNotConfigured,
          'authSignOutFailed' => l10n.authSignOutFailed,
          _ => l10n.authSignInFailed,
        };
        showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
              ),
            ],
          ),
        );
      }
    });

    return AppPageScaffold(
      title: Text(l10n.login),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.account_circle_rounded,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.loginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  key: const ValueKey('auth_google_sign_in'),
                  onPressed: state.isLoading
                      ? null
                      : () =>
                          ref.read(authProvider.notifier).signInWithGoogle(),
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login_rounded),
                  label: Text(l10n.continueWithGoogle),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.continueAsGuest),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
