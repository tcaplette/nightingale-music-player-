import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/node_identity/node_identity_notifier.dart';
import 'package:nightingale/features/onboarding/onboarding_notifier.dart';
import 'package:nightingale/shared/components/buttons/app_button.dart';
import 'package:nightingale/shared/components/inputs/app_text_input.dart';
import 'package:nightingale/shared/theme/app_motion.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

enum _OnboardingStep { welcome, identity, migration, complete }

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
            onNext: () => _advance(_OnboardingStep.migration),
          ),
        _OnboardingStep.migration => _MigrationStep(
            key: const ValueKey('migration'),
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

// ── Step 3: Migration story ───────────────────────────────────────────────────

class _MigrationStep extends StatelessWidget {
  const _MigrationStep({super.key, required this.onNext});
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
              const Spacer(),
              Text(
                'Take your music identity with you',
                style: theme.textTheme.displayLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'If you ever get a new phone, you can carry everything '
                'with you — your followers, your library, your history. '
                'Nothing gets left behind.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                child: AppButton(label: 'Back up my identity', onPressed: onNext),
              ),
              const SizedBox(height: AppSpacing.md),
              Center(
                child: TextButton(
                  onPressed: onNext,
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

// ── Step 4: Completion ────────────────────────────────────────────────────────

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
