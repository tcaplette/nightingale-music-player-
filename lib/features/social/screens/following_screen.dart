import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class FollowingScreen extends ConsumerWidget {
  const FollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialGraphProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Following')),
      body: _FollowingBody(
        following: state.following,
        outgoingPending: state.outgoingPending,
      ),
    );
  }
}

class _FollowingBody extends ConsumerWidget {
  const _FollowingBody({
    required this.following,
    required this.outgoingPending,
  });

  final List<FollowsTableData> following;
  final List<FollowRequestsTableData> outgoingPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (following.isEmpty && outgoingPending.isEmpty) {
      return const _EmptyFollowing();
    }

    return ListView(
      children: [
        if (outgoingPending.isNotEmpty) ...[
          _SectionHeader(
            label: 'Pending',
            count: outgoingPending.length,
          ),
          for (final req in outgoingPending)
            _PendingFollowTile(request: req),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (following.isNotEmpty) ...[
          if (outgoingPending.isNotEmpty)
            _SectionHeader(label: 'Following', count: following.length),
          for (final follow in following)
            _FollowingTile(follow: follow),
        ],
      ],
    );
  }
}

class _FollowingTile extends ConsumerWidget {
  const _FollowingTile({required this.follow});
  final FollowsTableData follow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: PersonDisplay(displayName: _displayName(follow.remoteActorUrl)),
      trailing: TextButton(
        onPressed: () => _confirmUnfollow(context, ref),
        child: Text(
          'Following',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      ),
      onTap: () => context.push('/profile/${Uri.encodeComponent(follow.remoteActorUrl)}'),
    );
  }

  Future<void> _confirmUnfollow(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unfollow'),
        content: Text('Stop following ${_displayName(follow.remoteActorUrl)}?'),
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
          .unfollowActor(follow.remoteActorUrl);
    }
  }

  // Extract a readable name from the actor URL for display until actor cache is consulted.
  String _displayName(String actorUrl) {
    try {
      final uri = Uri.parse(actorUrl);
      final segments = uri.pathSegments;
      return segments.isNotEmpty ? segments.last : actorUrl;
    } catch (_) {
      return actorUrl;
    }
  }
}

class _PendingFollowTile extends StatelessWidget {
  const _PendingFollowTile({required this.request});
  final FollowRequestsTableData request;

  @override
  Widget build(BuildContext context) {
    final label = request.state == 'pending_delivery'
        ? 'Waiting to deliver'
        : 'Awaiting approval';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: PersonDisplay(displayName: _displayName(request.actorUrl)),
      trailing: Text(
        label,
        style: const TextStyle(
          color: AppColors.neutral400,
          fontSize: 12,
        ),
      ),
      onTap: () => context.push(
        '/profile/${Uri.encodeComponent(request.actorUrl)}',
      ),
    );
  }

  String _displayName(String actorUrl) {
    try {
      return Uri.parse(actorUrl).pathSegments.last;
    } catch (_) {
      return actorUrl;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        '$label ($count)',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.neutral400,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _EmptyFollowing extends StatelessWidget {
  const _EmptyFollowing();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Not following anyone yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Follow people to see what they\'re listening to.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.neutral400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
