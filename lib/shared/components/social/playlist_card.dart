import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/shared/components/cards/app_card.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class PlaylistCard extends StatelessWidget {
  const PlaylistCard({
    super.key,
    required this.playlist,
    this.onTap,
  });

  final PlaylistsTableData playlist;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final trackCount = _trackCount(playlist.trackIdsJson);

    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playlist.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$trackCount track${trackCount == 1 ? '' : 's'}',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.neutral400),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(Icons.chevron_right, color: AppColors.neutral400, size: 20),
        ],
      ),
    );
  }

  int _trackCount(String json) {
    try {
      return (jsonDecode(json) as List).length;
    } catch (_) {
      return 0;
    }
  }
}
