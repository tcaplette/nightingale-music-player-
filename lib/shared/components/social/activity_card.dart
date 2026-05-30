import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Person-first activity card: [Avatar] [Name] [verb] [track/playlist]
/// Supports Listen, Announce (Share), and Save activity types.
class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key, required this.activity});
  final SocialActivitiesTableData activity;

  @override
  Widget build(BuildContext context) {
    final actorName = _displayName(activity.actorUrl);
    final (verb, objectLabel) = _verbAndObject(activity);
    final relativeTime = _relativeTime(activity.publishedAt);

    return InkWell(
      onTap: () => context.push(
        '/profile/${Uri.encodeComponent(activity.actorUrl)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonDisplay(
              displayName: actorName,
              avatarSize: 36,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: [
                        TextSpan(
                          text: actorName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(text: ' $verb '),
                        TextSpan(
                          text: objectLabel,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relativeTime,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.neutral400,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String verb, String objectLabel) _verbAndObject(
    SocialActivitiesTableData a,
  ) {
    final obj = _parseObject(a.objectJson);
    final trackName = obj?['name']?.toString() ??
        obj?['id']?.toString() ??
        'a track';
    final artist = obj?['artist']?.toString();
    final label = artist != null ? '$trackName · $artist' : trackName;

    return switch (a.type) {
      'Listen' => ('is listening to', label),
      'Announce' => ('shared', label),
      'Save' => ('saved', label),
      'Like' => ('liked', label),
      _ => ('interacted with', label),
    };
  }

  Map<String, dynamic>? _parseObject(String? json) {
    if (json == null) return null;
    try {
      return jsonDecode(json) as Map<String, dynamic>?;
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

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
