import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/federation/discovery/mastodon_auth_webview.dart';
import 'package:nightingale/features/federation/discovery/mastodon_oauth_service.dart';
import 'package:nightingale/features/node_identity/node_identity_notifier.dart';
import 'package:nightingale/features/onboarding/mastodon_account_provider.dart';
import 'package:nightingale/features/onboarding/onboarding_notifier.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';
import 'package:nightingale/shared/components/buttons/app_button.dart';
import 'package:nightingale/shared/components/inputs/app_text_input.dart';
import 'package:nightingale/shared/theme/app_motion.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

enum _OnboardingStep { welcome, signIn, complete }

class OnboardingShell extends ConsumerStatefulWidget {
  const OnboardingShell({super.key});

  @override
  ConsumerState<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends ConsumerState<OnboardingShell> {
  _OnboardingStep _step = _OnboardingStep.welcome;

  void _advance(_OnboardingStep next) => setState(() => _step = next);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.pageTransition,
      switchInCurve: AppMotion.curvePageTransition,
      switchOutCurve: AppMotion.curveExit,
      child: switch (_step) {
        _OnboardingStep.welcome => _WelcomeStep(
            key: const ValueKey('welcome'),
            onNext: () => _advance(_OnboardingStep.signIn),
          ),
        _OnboardingStep.signIn => _SignInStep(
            key: const ValueKey('signIn'),
            onNext: () => _advance(_OnboardingStep.complete),
          ),
        _OnboardingStep.complete => _CompleteStep(
            key: const ValueKey('complete'),
            onFinish: () async {
              await ref.read(onboardingProvider.notifier).completeOnboarding();
              if (context.mounted) context.go(AppRoutes.library);
            },
          ),
      },
    );
  }
}

// ── Step 1: Welcome ───────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text('nightingale', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your music. Your people. Your network.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: AppButton(label: 'Get started', onPressed: onNext),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 2: Sign in with Mastodon (creates identity) ─────────────────────────

class _SignInStep extends ConsumerStatefulWidget {
  const _SignInStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  ConsumerState<_SignInStep> createState() => _SignInStepState();
}

class _SignInStepState extends ConsumerState<_SignInStep> {
  final _handleController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _helpExpanded = false;

  @override
  void dispose() {
    _handleController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final input = _handleController.text.trim();
    if (input.isEmpty) {
      setState(() => _error = 'Enter your Mastodon handle or server — e.g. @you@mastodon.social');
      return;
    }
    setState(() { _loading = true; _error = null; });

    final oauthService = sl<MastodonOAuthService>();

    AppLogger.debug('[onboarding] prepareSignIn for: $input', tag: 'onboarding_auth');
    final prepared = await oauthService.prepareSignIn(input);
    AppLogger.debug('[onboarding] prepareSignIn result: ${prepared == null ? "null (server unreachable)" : "OK, instance=${prepared.instance}"}', tag: 'onboarding_auth');

    if (!mounted) return;

    if (prepared == null) {
      setState(() {
        _loading = false;
        _error = 'Could not reach that Mastodon server. Check your handle and try again.';
      });
      return;
    }

    AppLogger.debug('[onboarding] launching webview for authUrl: ${prepared.authUrl}', tag: 'onboarding_auth');
    final callbackUrl = await MastodonAuthWebView.show(
      context,
      authUrl: prepared.authUrl,
      callbackScheme: 'nightingale',
    );
    AppLogger.debug('[onboarding] webview returned callbackUrl: ${callbackUrl ?? "null (cancelled)"}', tag: 'onboarding_auth');

    if (!mounted) return;

    AppLogger.debug('[onboarding] calling completeSignIn…', tag: 'onboarding_auth');
    final result = await oauthService.completeSignIn(prepared, callbackUrl);
    AppLogger.debug('[onboarding] completeSignIn result: ${result.runtimeType}', tag: 'onboarding_auth');

    if (!mounted) return;

    switch (result) {
      case OAuthSuccess(:final instance, :final accessToken):
        AppLogger.debug('[onboarding] OAuthSuccess for $instance — fetching account details', tag: 'onboarding_auth');
        final details = await oauthService.fetchAccountDetails(instance, accessToken);
        AppLogger.debug('[onboarding] fetchAccountDetails: ${details == null ? "null" : "handle=${details.handle}"}', tag: 'onboarding_auth');
        if (!mounted) return;
        if (details == null) {
          setState(() {
            _loading = false;
            _error = 'Signed in but could not fetch account details. Try again.';
          });
          return;
        }
        await ref.read(nodeIdentityProvider.notifier).createIdentity(
              displayName: details.displayName,
              username: details.username,
            );
        await sl<SecureStorageService>().setMastodonHandle(details.handle);
        ref.invalidate(mastodonAccountProvider);
        if (mounted) widget.onNext();

      case OAuthCancelled():
        AppLogger.debug('[onboarding] OAuthCancelled — resetting loading state', tag: 'onboarding_auth');
        setState(() => _loading = false);

      case OAuthFailed(:final reason):
        AppLogger.debug('[onboarding] OAuthFailed: $reason', tag: 'onboarding_auth');
        setState(() {
          _loading = false;
          _error = reason;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // Scaffold shrinks body when keyboard appears; SingleChildScrollView handles the rest.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              Text('Connect your Mastodon', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Nightingale uses your Mastodon account to find and follow people you know.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text('Connecting to Mastodon…', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                )
              else
                AppTextInput(
                  label: 'Mastodon handle',
                  hint: '@you@mastodon.social',
                  controller: _handleController,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              // "What's my handle?" inline explainer
              GestureDetector(
                onTap: () => setState(() => _helpExpanded = !_helpExpanded),
                child: Row(
                  children: [
                    Text(
                      "What's my handle?",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _helpExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
              if (_helpExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Mastodon handle has two parts:',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.bodySmall,
                          children: [
                            TextSpan(
                              text: '@username',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' — your name on your server\n'),
                            TextSpan(
                              text: '@server.com',
                              style: TextStyle(
                                color: theme.colorScheme.tertiary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' — the server you signed up on'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Example: @alice@mastodon.social\n\nNot sure which server? Check your Mastodon app — it\'s shown on your profile.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              if (!_loading)
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: 'Continue',
                    onPressed: _signIn,
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 3: Complete ──────────────────────────────────────────────────────────

class _CompleteStep extends StatelessWidget {
  const _CompleteStep({super.key, required this.onFinish});
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Text("You're all set", style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your music space is ready. Start listening.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: AppButton(label: 'Go to my library', onPressed: onFinish),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Public: Discovery step (still used standalone from Find People) ───────────

class DiscoveryOnboardingStep extends StatefulWidget {
  const DiscoveryOnboardingStep({
    super.key,
    required this.onNext,
    this.initialMastodonHandle,
  });
  final VoidCallback onNext;
  final String? initialMastodonHandle;

  @override
  State<DiscoveryOnboardingStep> createState() =>
      _DiscoveryOnboardingStepState();
}

class _DiscoveryOnboardingStepState extends State<DiscoveryOnboardingStep> {
  @override
  Widget build(BuildContext context) {
    // No longer used in onboarding — Find People handles discovery.
    // Kept as a no-op for any remaining call sites during transition.
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onNext());
    return const SizedBox.shrink();
  }
}
