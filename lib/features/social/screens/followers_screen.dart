import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class FollowersScreen extends ConsumerWidget {
  const FollowersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialGraphProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Followers')),
      body: _FollowersBody(
        followers: state.followers,
        incomingPending: state.incomingPending,
      ),
    );
  }
}

class _FollowersBody extends ConsumerWidget {
  const _FollowersBody({
    required this.followers,
    required this.incomingPending,
  });

  final List<FollowersTableData> followers;
  final List<FollowRequestsTableData> incomingPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (followers.isEmpty && incomingPending.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No followers yet',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral400,
                ),
          ),
        ),
      );
    }

    return ListView(
      children: [
        if (incomingPending.isNotEmpty) ...[
          _SectionHeader(
            label: 'Follow Requests',
            count: incomingPending.length,
          ),
          for (final req in incomingPending)
            _PendingIncomingTile(request: req),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (followers.isNotEmpty) ...[
          if (incomingPending.isNotEmpty)
            _SectionHeader(label: 'Followers', count: followers.length),
          for (final follower in followers)
            _FollowerTile(follower: follower),
        ],
      ],
    );
  }
}

class _FollowerTile extends ConsumerWidget {
  const _FollowerTile({required this.follower});
  final FollowersTableData follower;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actorAsync = ref.watch(cachedActorProvider(follower.actorUrl));
    final actor = actorAsync.valueOrNull;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: PersonDisplay(
        displayName: _resolvedName(actor, follower.actorUrl),
        avatarUrl: actor?.icon,
      ),
      onTap: () => context.push(
        '/profile/${Uri.encodeComponent(follower.actorUrl)}',
      ),
    );
  }
}

class _PendingIncomingTile extends ConsumerWidget {
  const _PendingIncomingTile({required this.request});
  final FollowRequestsTableData request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actorAsync = ref.watch(cachedActorProvider(request.actorUrl));
    final actor = actorAsync.valueOrNull;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: PersonDisplay(
        displayName: _resolvedName(actor, request.actorUrl),
        avatarUrl: actor?.icon,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => ref
                .read(socialGraphProvider.notifier)
                .acceptFollowRequest(request.rowId),
            child: const Text('Accept'),
          ),
          TextButton(
            onPressed: () => ref
                .read(socialGraphProvider.notifier)
                .rejectFollowRequest(request.rowId),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.neutral400,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

String _resolvedName(ApActor? actor, String actorUrl) {
  if (actor != null) {
    if (actor.name.isNotEmpty) return actor.name;
    if (actor.preferredUsername.isNotEmpty) return actor.preferredUsername;
  }
  try {
    return Uri.parse(actorUrl).pathSegments.last;
  } catch (_) {
    return actorUrl;
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
