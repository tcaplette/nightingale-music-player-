import 'package:flutter/material.dart';
import 'package:nightingale/features/social/providers/notifications_notifier.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Single and grouped notification item.
/// Grouped when senders.length >= 3: "[N people] verb [object]"
class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.group,
    this.onTap,
  });

  final GroupedNotification group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isGrouped = group.isGrouped;
    final count = group.senders.length;
    final actorName = _displayName(group.latest.fromActorUrl);
    final verb = _verb(group.type);
    final objectLabel = _objectLabel(group.objectRef);
    final unread = !group.latest.isRead;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? AppColors.accent.withValues(alpha: 0.05)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isGrouped)
              PersonDisplay(
                displayName: actorName,
                avatarSize: 36,
              )
            else
              _GroupedAvatars(senders: group.senders.take(3).toList()),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall,
                  children: [
                    TextSpan(
                      text: isGrouped ? '$count people' : actorName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: ' $verb'),
                    if (objectLabel != null) ...[
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: objectLabel,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _verb(String type) => switch (type) {
        'new_follower' => 'started following you',
        'like' => 'liked',
        'announce' => 'shared',
        'follow_rejected' => 'declined your follow request',
        _ => 'interacted',
      };

  String? _objectLabel(String? objectRef) {
    if (objectRef == null) return null;
    try {
      // Try to extract name from JSON object ref
      final decoded = objectRef.startsWith('{')
          ? (objectRef as dynamic)
          : null; // simplified — full parse in production
      return decoded?['name']?.toString();
    } catch (_) {
      return null;
    }
  }

  String _displayName(String actorUrl) {
    try {
      return Uri.parse(actorUrl).pathSegments.last;
    } catch (_) {
      return actorUrl;
    }
  }
}

class _GroupedAvatars extends StatelessWidget {
  const _GroupedAvatars({required this.senders});
  final List<dynamic> senders;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 36,
      child: Stack(
        children: [
          for (var i = 0; i < senders.length.clamp(0, 3); i++)
            Positioned(
              left: i * 10.0,
              child: PersonDisplay(
                displayName: _displayName(senders[i].fromActorUrl as String),
                avatarSize: 24,
              ),
            ),
        ],
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
