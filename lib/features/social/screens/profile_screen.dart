import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/social/providers/profile_notifier.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/components/social/activity_card.dart';
import 'package:nightingale/shared/components/social/playlist_card.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.actorUrl});
  final String actorUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider(actorUrl));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!state.isLoading && state.actor != null)
            _OverflowMenu(actorUrl: actorUrl, state: state),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ProfileBody(actorUrl: actorUrl, state: state),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  const _ProfileBody({required this.actorUrl, required this.state});
  final String actorUrl;
  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = state.actor;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonDisplay(
              displayName: actor?.name ?? _fallbackName(actorUrl),
              avatarUrl: actor?.icon,
              avatarSize: 64,
            ),
            const Spacer(),
            _FollowButton(actorUrl: actorUrl, state: state),
          ],
        ),

        if (state.isStale && state.lastUpdated != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Last updated ${_relativeTime(state.lastUpdated!)}',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.neutral400),
          ),
        ],

        if (actor?.summary != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            actor!.summary!,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],

        // ── Advanced info affordance ──────────────────────────────────────────
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: () => _showAdvancedInfo(context, actor, actorUrl),
          child: Text(
            'Advanced info',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.neutral400,
                  decoration: TextDecoration.underline,
                ),
          ),
        ),

        // ── Now Playing ───────────────────────────────────────────────────────
        if (_nowPlayingActivity(state) != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _NowPlayingSection(activity: _nowPlayingActivity(state)!),
        ],

        // ── Playlists ─────────────────────────────────────────────────────────
        if (state.playlists.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Playlists',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final playlist in state.playlists)
            PlaylistCard(
              playlist: playlist,
              onTap: () => context.push(
                '/playlists/${Uri.encodeComponent(playlist.collectionUrl ?? '')}',
              ),
            ),
        ],

        // ── Recent Activity ───────────────────────────────────────────────────
        if (state.recentActivities.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final activity in state.recentActivities)
            ActivityCard(activity: activity),
        ],
      ],
    );
  }

  SocialActivitiesTableData? _nowPlayingActivity(ProfileState state) {
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    try {
      return state.recentActivities.firstWhere(
        (a) =>
            a.type == 'Listen' &&
            a.publishedAt.isAfter(tenMinutesAgo),
      );
    } catch (_) {
      return null;
    }
  }

  String _fallbackName(String url) {
    try {
      return Uri.parse(url).pathSegments.last;
    } catch (_) {
      return url;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _showAdvancedInfo(
    BuildContext context,
    dynamic actor,
    String actorUrl,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _AdvancedInfoSheet(actor: actor, actorUrl: actorUrl),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  const _FollowButton({required this.actorUrl, required this.state});
  final String actorUrl;
  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isBlocked) {
      return OutlinedButton(
        onPressed: () => ref
            .read(socialGraphProvider.notifier)
            .unblockActor(actorUrl),
        child: const Text('Unblock'),
      );
    }

    final followState = state.followState;

    if (followState == 'accepted') {
      return OutlinedButton(
        onPressed: () => _confirmUnfollow(context, ref),
        child: const Text('Following'),
      );
    }

    if (followState == 'pending' || followState == 'pending_delivery') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          const OutlinedButton(
            onPressed: null,
            child: Text('Requested'),
          ),
          Text(
            'Awaiting approval',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.neutral400),
          ),
        ],
      );
    }

    return FilledButton(
      onPressed: () =>
          ref.read(socialGraphProvider.notifier).followActor(actorUrl),
      child: const Text('Follow'),
    );
  }

  Future<void> _confirmUnfollow(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: const Text('Stop following this person?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unfollow'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(socialGraphProvider.notifier)
          .unfollowActor(actorUrl);
    }
  }
}

class _NowPlayingSection extends StatelessWidget {
  const _NowPlayingSection({required this.activity});
  final SocialActivitiesTableData activity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Now Playing',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: AppColors.accent, letterSpacing: 0.8),
        ),
        const SizedBox(height: AppSpacing.xs),
        ActivityCard(activity: activity),
      ],
    );
  }
}

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.actorUrl, required this.state});
  final String actorUrl;
  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'block') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Block'),
              content: const Text(
                'Block this person? They will be notified.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Block'),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await ref
                .read(socialGraphProvider.notifier)
                .blockActor(actorUrl);
            if (context.mounted) context.pop();
          }
        }
        if (value == 'mute') {
          await ref
              .read(socialGraphProvider.notifier)
              .muteActor(actorUrl);
        }
        if (value == 'unmute') {
          await ref
              .read(socialGraphProvider.notifier)
              .unmuteActor(actorUrl);
        }
      },
      itemBuilder: (_) => [
        if (!state.isBlocked)
          const PopupMenuItem(value: 'block', child: Text('Block')),
        if (state.isMuted)
          const PopupMenuItem(value: 'unmute', child: Text('Unmute'))
        else
          const PopupMenuItem(value: 'mute', child: Text('Mute')),
      ],
    );
  }
}

class _AdvancedInfoSheet extends StatelessWidget {
  const _AdvancedInfoSheet({required this.actor, required this.actorUrl});
  final dynamic actor;
  final String actorUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advanced Info',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(label: 'Handle', value: actor?.preferredUsername != null
              ? '@${actor.preferredUsername}@${Uri.parse(actorUrl).host}'
              : actorUrl),
          _InfoRow(label: 'Node URL', value: Uri.parse(actorUrl).host),
          if (actor?.publishedAt != null)
            _InfoRow(
              label: 'Joined',
              value: actor.publishedAt.toString().substring(0, 10),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.neutral400),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
