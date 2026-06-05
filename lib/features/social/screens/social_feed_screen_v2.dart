import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/social/providers/social_feed_notifier.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/components/empty_state_widget.dart';
import 'package:nightingale/shared/components/notifications_badge_button.dart';
import 'package:nightingale/shared/components/skeleton_loader.dart';
import 'package:nightingale/shared/components/social/activity_card.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class SocialFeedScreenV2 extends ConsumerWidget {
  const SocialFeedScreenV2({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Following',
            onPressed: () => context.push(AppRoutes.following),
          ),
          const NotificationsBadgeButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(socialFeedProvider.notifier).refresh(),
        child: _FeedBody(state: state),
      ),
    );
  }
}

class _FeedBody extends ConsumerWidget {
  const _FeedBody({required this.state});
  final SocialFeedState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.items.isEmpty) {
      return const SkeletonListView(count: 8);
    }

    return Column(
      children: [
        const _FollowSummaryRow(),
        if (state.isOffline) const _OfflineBanner(),
        if (state.items.isEmpty)
          Expanded(
            child: EmptyStateWidget(
              icon: Icons.people_outline,
              headline: 'Nothing here yet',
              subhead: 'Follow people to see what they\'re listening to.',
              action: TextButton(
                onPressed: () => context.push(AppRoutes.findPeople),
                child: const Text('Find people to follow'),
              ),
            ),
          )
        else
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200) {
                ref.read(socialFeedProvider.notifier).loadMore();
              }
              return false;
            },
            child: ListView.separated(
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (context, i) => const Divider(
                height: 1,
                indent: AppSpacing.md,
                endIndent: AppSpacing.md,
              ),
              itemBuilder: (context, i) {
                if (i == state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return ActivityCard(activity: state.items[i]);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowSummaryRow extends ConsumerWidget {
  const _FollowSummaryRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graph = ref.watch(socialGraphProvider);
    final followingCount = graph.following.length + graph.outgoingPending.length;
    final followersCount = graph.followers.length + graph.incomingPending.length;

    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.neutral400,
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.push(AppRoutes.following),
                child: Text('$followingCount following', style: style),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text('·', style: style),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.followers),
                child: Text('$followersCount followers', style: style),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      color: AppColors.neutral200,
      child: Text(
        'Showing cached feed — no network connection',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.neutral500,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
