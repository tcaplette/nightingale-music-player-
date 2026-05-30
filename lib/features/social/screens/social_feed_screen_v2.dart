import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/social/providers/social_feed_notifier.dart';
import 'package:nightingale/shared/components/empty_state_widget.dart';
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
      appBar: AppBar(title: const Text('Feed')),
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
        if (state.isOffline) const _OfflineBanner(),
        if (state.items.isEmpty)
          const Expanded(
            child: EmptyStateWidget(
              icon: Icons.people_outline,
              headline: 'Nothing here yet',
              subhead: 'Follow people to see what they\'re listening to.',
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
              separatorBuilder: (_, __) => const Divider(
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

class _EmptyFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Follow people to see what they\'re listening to',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your feed will show listens, shares, and new additions from people you follow.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral400,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
