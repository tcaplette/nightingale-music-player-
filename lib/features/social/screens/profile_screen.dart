import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/social/providers/profile_notifier.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
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
    final nowPlaying = _nowPlayingActivity(state);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // ── Identity header ───────────────────────────────────────────────────
        _ProfileHeader(actorUrl: actorUrl, state: state),

        // ── Bio ───────────────────────────────────────────────────────────────
        if (actor?.summary != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, 0,
            ),
            child: Text(
              actor!.summary!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),

        // ── Meta: joined + stale ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (actor?.publishedAt != null)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: AppColors.neutral400,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Joined ${_formatDate(actor!.publishedAt!)}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: AppColors.neutral400),
                    ),
                  ],
                ),
              if (state.isStale && state.lastUpdated != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Profile may be out of date · last synced ${_relativeTime(state.lastUpdated!)}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.neutral400),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        const Divider(height: 1),

        // ── Now Playing ───────────────────────────────────────────────────────
        if (nowPlaying != null) ...[
          _SectionLabel(label: 'Now Playing', color: AppColors.accent),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: ActivityCard(activity: nowPlaying),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
        ],

        // ── Recent Activity ───────────────────────────────────────────────────
        if (state.recentActivities.isNotEmpty) ...[
          _SectionLabel(label: 'Recent Activity'),
          for (final activity in state.recentActivities)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: ActivityCard(activity: activity),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // ── Playlists ─────────────────────────────────────────────────────────
        if (state.playlists.isNotEmpty) ...[
          const Divider(height: 1),
          _SectionLabel(label: 'Playlists'),
          for (final playlist in state.playlists)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: PlaylistCard(
                playlist: playlist,
                onTap: () => context.push(
                  '/playlists/${Uri.encodeComponent(playlist.collectionUrl ?? '')}',
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  SocialActivitiesTableData? _nowPlayingActivity(ProfileState state) {
    final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
    try {
      return state.recentActivities.firstWhere(
        (a) => a.type == 'Listen' && a.publishedAt.isAfter(tenMinutesAgo),
      );
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.actorUrl, required this.state});
  final String actorUrl;
  final ProfileState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actor = state.actor;
    final displayName = (actor?.name.isNotEmpty == true)
        ? actor!.name
        : (actor?.preferredUsername ?? _fallbackName(actorUrl));
    final handle = actor?.preferredUsername != null
        ? '@${actor!.preferredUsername}@${Uri.parse(actorUrl).host}'
        : null;
    final isPrivate = actor?.manuallyApprovesFollowers == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md,
      ),
      child: Column(
        children: [
          // Avatar
          _ProfileAvatar(avatarUrl: actor?.icon, displayName: displayName),

          const SizedBox(height: AppSpacing.md),

          // Display name
          Text(
            displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),

          // Handle + lock icon
          if (handle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  handle,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: AppColors.neutral400),
                ),
                if (isPrivate) ...[
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.lock_outline,
                    size: 12,
                    color: AppColors.neutral400,
                  ),
                ],
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Follow / Unblock button
          _FollowButton(actorUrl: actorUrl, state: state),
        ],
      ),
    );
  }

  String _fallbackName(String url) {
    try {
      return Uri.parse(url).pathSegments.last;
    } catch (_) {
      return url;
    }
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl, required this.displayName});
  final String? avatarUrl;
  final String displayName;

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    const size = 88.0;

    final monogram = CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
            ),
      ),
    );

    final url = avatarUrl;
    if (url == null) return monogram;

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (_, image) => CircleAvatar(
        radius: size / 2,
        backgroundImage: image,
      ),
      placeholder: (_, _) => monogram,
      errorWidget: (_, _, _) => monogram,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.sm,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color ?? AppColors.neutral400,
              letterSpacing: 0.8,
            ),
      ),
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
        onPressed: () =>
            ref.read(socialGraphProvider.notifier).unblockActor(actorUrl),
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
        children: [
          const OutlinedButton(onPressed: null, child: Text('Requested')),
          const SizedBox(height: AppSpacing.xs),
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
      await ref.read(socialGraphProvider.notifier).unfollowActor(actorUrl);
    }
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
              content: const Text('Block this person? They will be notified.'),
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
            await ref.read(socialGraphProvider.notifier).blockActor(actorUrl);
            if (context.mounted) context.pop();
          }
        }
        if (value == 'mute') {
          await ref.read(socialGraphProvider.notifier).muteActor(actorUrl);
        }
        if (value == 'unmute') {
          await ref.read(socialGraphProvider.notifier).unmuteActor(actorUrl);
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
