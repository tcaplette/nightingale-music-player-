import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/federation/discovery/mastodon_bridge_service.dart';
import 'package:nightingale/features/federation/discovery/mastodon_oauth_service.dart';
import 'package:nightingale/features/federation/screens/mastodon_import_screen.dart';
import 'package:nightingale/features/node_identity/node_identity_notifier.dart';
import 'package:nightingale/features/onboarding/mastodon_account_provider.dart';
import 'package:nightingale/features/onboarding/onboarding_notifier.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';
import 'package:nightingale/shared/components/buttons/app_button.dart';
import 'package:nightingale/shared/components/inputs/app_text_input.dart';
import 'package:nightingale/shared/theme/app_motion.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

enum _OnboardingStep { welcome, identity, mastodon, discovery, complete }

class OnboardingShell extends ConsumerStatefulWidget {
  const OnboardingShell({super.key});

  @override
  ConsumerState<OnboardingShell> createState() => _OnboardingShellState();
}

class _OnboardingShellState extends ConsumerState<OnboardingShell> {
  _OnboardingStep _step = _OnboardingStep.welcome;

  void _advance(_OnboardingStep next) {
    setState(() => _step = next);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.pageTransition,
      switchInCurve: AppMotion.curvePageTransition,
      switchOutCurve: AppMotion.curveExit,
      child: switch (_step) {
        _OnboardingStep.welcome => _WelcomeStep(
            key: const ValueKey('welcome'),
            onNext: () => _advance(_OnboardingStep.identity),
          ),
        _OnboardingStep.identity => _IdentityStep(
            key: const ValueKey('identity'),
            onNext: () => _advance(_OnboardingStep.mastodon),
          ),
        _OnboardingStep.mastodon => _MastodonStep(
            key: const ValueKey('mastodon'),
            onNext: () => _advance(_OnboardingStep.discovery),
          ),
        _OnboardingStep.discovery => _DiscoveryStep(
            key: const ValueKey('discovery'),
            onNext: () => _advance(_OnboardingStep.complete),
          ),
        _OnboardingStep.complete => _CompleteStep(
            key: const ValueKey('complete'),
            onFinish: () async {
              await ref
                  .read(onboardingProvider.notifier)
                  .completeOnboarding();
              if (context.mounted) {
                context.go(AppRoutes.library);
              }
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

// ── Step 2: Identity setup ────────────────────────────────────────────────────

class _IdentityStep extends ConsumerStatefulWidget {
  const _IdentityStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  ConsumerState<_IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends ConsumerState<_IdentityStep> {
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter your name to get started.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(nodeIdentityProvider.notifier)
          .createIdentity(displayName: name);
      widget.onNext();
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Something went wrong. Please try again.';
          _loading = false;
        });
      }
    }
  }

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
              const Spacer(),
              Text('What should we call you?', style: theme.textTheme.displayLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This is how others will see you.',
                style: theme.textTheme.bodyMedium?.copyWith(
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
                      Text(
                        'Setting up your space…',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              else
                AppTextInput(
                  label: 'Your name',
                  hint: 'Your name',
                  controller: _nameController,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _error!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (!_loading)
                SizedBox(
                  width: double.infinity,
                  child: AppButton(label: 'Continue', onPressed: _submit),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 3: Mastodon sign-in ──────────────────────────────────────────────────

class _MastodonStep extends ConsumerStatefulWidget {
  const _MastodonStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  ConsumerState<_MastodonStep> createState() => _MastodonStepState();
}

class _MastodonStepState extends ConsumerState<_MastodonStep> {
  final _instanceController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _connectedAs;

  @override
  void dispose() {
    _instanceController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final handle = _instanceController.text.trim();
    final password = _passwordController.text;
    if (handle.isEmpty) {
      setState(() => _error = 'Enter your Mastodon account to continue.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<MastodonOAuthService>().signIn(
      handle,
      password: password.isNotEmpty ? password : null,
    );
    if (!mounted) return;
    switch (result) {
      case OAuthSuccess(:final instance, :final accessToken):
        // Fetch the account handle so we can store it for display elsewhere.
        final handle = await _fetchHandle(instance, accessToken);
        if (handle != null) {
          await sl<SecureStorageService>().setMastodonHandle(handle);
          ref.invalidate(mastodonAccountProvider);
        }
        setState(() {
          _loading = false;
          _connectedAs = handle ?? instance;
        });
        // Brief pause so the user sees the confirmation, then advance.
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) widget.onNext();
      case OAuthCancelled():
        setState(() => _loading = false);
      case OAuthFailed(:final reason):
        setState(() {
          _loading = false;
          _error = reason;
        });
    }
  }

  Future<String?> _fetchHandle(String instance, String accessToken) async {
    try {
      final response = await (sl<MastodonOAuthService>())
          .fetchAccountHandle(instance, accessToken);
      return response;
    } catch (_) {
      return null;
    }
  }

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
              const Spacer(),
              Text(
                'Bring your network with you',
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in with Mastodon to see which of your connections are already on Nightingale.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_connectedAs != null) ...[
                Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Connected as $_connectedAs',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                AppTextInput(
                  label: 'Mastodon account',
                  hint: '@you@mastodon.social',
                  controller: _instanceController,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextInput(
                  label: 'Password',
                  hint: 'Your Mastodon password',
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: _loading ? 'Signing in…' : 'Sign in with Mastodon',
                    onPressed: _loading ? null : _signIn,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              if (!_loading)
                Center(
                  child: TextButton(
                    onPressed: widget.onNext,
                    child: Text(
                      'Skip for now',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 4: Discovery ─────────────────────────────────────────────────────────

class _DiscoveryStep extends ConsumerWidget {
  const _DiscoveryStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storedHandle = ref.watch(mastodonAccountProvider).valueOrNull;
    return DiscoveryOnboardingStep(
      onNext: onNext,
      initialMastodonHandle: storedHandle,
    );
  }
}

/// The post-identity discovery step — offered once during onboarding and also
/// accessible any time from the Find People screen.
///
/// Extracted as a public widget so it can be unit/widget tested independently.
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
  bool _showMastodonImport = false;

  Future<void> _markShownAndAdvance() async {
    await sl<SecureStorageService>().setDiscoveryShown(true);
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    if (_showMastodonImport) {
      return MastodonImportScreen(
        key: const ValueKey('mastodon_import'),
        initialHandle: widget.initialMastodonHandle,
        onDone: _markShownAndAdvance,
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'Find your people',
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Connect with friends already on Nightingale or bring your Mastodon network with you.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Connect Mastodon',
                  onPressed: () => setState(() => _showMastodonImport = true),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.findPeople),
                  child: const Text('Find by username'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: _markShownAndAdvance,
                  child: Text(
                    'Skip for now',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 5: Completion ────────────────────────────────────────────────────────

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
