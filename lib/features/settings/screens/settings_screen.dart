import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/federation/screens/mastodon_import_screen.dart';
import 'package:nightingale/features/onboarding/mastodon_account_provider.dart';
import 'package:nightingale/features/onboarding/onboarding_notifier.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mastodonHandle = ref.watch(mastodonAccountProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          // ── Playback ───────────────────────────────────────────────────────
          _SectionHeader('Playback'),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Playback'),
            subtitle: const Text('Buffer, skip threshold, audio focus'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsPlayback),
          ),

          // ── Privacy & Sharing ──────────────────────────────────────────────
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Privacy & Sharing'),
          ListTile(
            leading: const Icon(Icons.library_music_outlined),
            title: const Text('Library visibility'),
            subtitle: const Text('Control who can see your library'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsSharing),
          ),

          // ── Federation & Discovery ─────────────────────────────────────────
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Federation & Discovery'),
          ListTile(
            leading: const Icon(Icons.hub_outlined),
            title: const Text('Federation'),
            subtitle: const Text(
                'Listening activity, node discovery, global trending'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsFederation),
          ),
          ListTile(
            leading: const Icon(Icons.link),
            title: const Text('Mastodon account'),
            subtitle: Text(mastodonHandle ?? 'Not connected'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const MastodonImportScreen(),
              ),
            ),
          ),

          // ── Notifications ──────────────────────────────────────────────────
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('What appears in your notification centre'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsNotifications),
          ),

          // ── Appearance ─────────────────────────────────────────────────────
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Appearance'),
            subtitle: const Text('Theme and motion preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsAppearance),
          ),

          // ── Account ────────────────────────────────────────────────────────
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profile'),
            subtitle: const Text('Name, photo, and bio'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsProfile),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: const Text('Export identity'),
            subtitle: const Text('Generate a migration QR code'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsExportIdentity),
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked & muted'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.settingsBlockedMuted),
          ),
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.error),
            title: Text(
              'Sign out',
              style:
                  TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmSignOut(context, ref),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
            'This will clear your identity and return you to onboarding.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sign out',
              style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(onboardingProvider.notifier).signOut();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.0,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
