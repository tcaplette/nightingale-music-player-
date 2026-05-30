import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/features/social/providers/notifications_notifier.dart';
import 'package:nightingale/shared/components/social/notification_item.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.groups.isEmpty
              ? _EmptyNotifications()
              : ListView.separated(
                  itemCount: state.groups.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
                  itemBuilder: (context, i) {
                    final group = state.groups[i];
                    return NotificationItem(
                      group: group,
                      onTap: () {
                        if (group.type == 'new_follower') {
                          context.push(
                            '/profile/${Uri.encodeComponent(group.latest.fromActorUrl)}',
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'No notifications yet',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.neutral400),
        ),
      ),
    );
  }
}
