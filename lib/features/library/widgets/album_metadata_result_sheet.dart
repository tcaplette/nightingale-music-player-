import 'package:flutter/material.dart';
import 'package:nightingale/features/library/services/album_metadata_fetch_service.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

void showAlbumMetadataResultSheet(
  BuildContext context,
  AlbumFetchResult result,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _AlbumMetadataResultSheet(result: result),
  );
}

class _AlbumMetadataResultSheet extends StatelessWidget {
  const _AlbumMetadataResultSheet({required this.result});
  final AlbumFetchResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Metadata Fetch Complete', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _buildSummary(context, theme, scheme),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(
    BuildContext context,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    // No data found at all
    if (result.noDataFound) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search_off, size: 18, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'No metadata found for this album',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try editing tracks individually using a long press on each song.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    final widgets = <Widget>[];

    // Summary line
    final successCount = result.matched.length;
    final total = result.totalTracks;
    final allMatched = successCount == total && result.errors.isEmpty;

    widgets.add(
      Row(
        children: [
          Icon(
            allMatched ? Icons.check_circle : Icons.info_outline,
            size: 18,
            color: allMatched
                ? const Color(0xFF34C759)
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            allMatched
                ? 'All $total track${total == 1 ? '' : 's'} updated'
                : '$successCount of $total track${total == 1 ? '' : 's'} matched',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );

    // Unmatched tracks
    if (result.unmatched.isNotEmpty) {
      widgets.add(const SizedBox(height: AppSpacing.md));
      widgets.add(
        Text(
          'Not matched',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      );
      widgets.add(const SizedBox(height: AppSpacing.xs));
      for (final track in result.unmatched) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '• ${track.title}',
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

    // Errors
    if (result.errors.isNotEmpty) {
      widgets.add(const SizedBox(height: AppSpacing.md));
      widgets.add(
        Text(
          'Errors',
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.error,
            letterSpacing: 0.8,
          ),
        ),
      );
      widgets.add(const SizedBox(height: AppSpacing.xs));
      for (final entry in result.errors.entries) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '• ${entry.key.title}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.error,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
