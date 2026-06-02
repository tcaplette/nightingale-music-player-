import 'package:flutter/material.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/services/metadata_validator.dart';
import 'package:nightingale/features/library/widgets/metadata_badge.dart';
import 'package:nightingale/shared/components/artwork_thumbnail.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.track,
    required this.onTap,
    this.onLongPress,
  });

  final TrackModel track;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  static const _validator = MetadataValidator();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final duration = _formatDuration(track.duration);

    final validationResult =
        track.isRemote ? null : _validator.validate(track);

    Widget trailing = Text(
      duration,
      style: textTheme.labelSmall?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.5),
      ),
    );

    if (validationResult != null) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MetadataBadge(result: validationResult),
          const SizedBox(width: AppSpacing.xs),
          Text(
            duration,
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }

    return Semantics(
      label: '${track.title} by ${track.artist}, $duration'
          '${validationResult is MetadataIncomplete ? ', incomplete metadata' : ''}',
      button: true,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: ArtworkThumbnail(path: track.artworkPath, size: 44),
        title: Text(
          track.title,
          style: textTheme.bodyLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          track.artist,
          style: textTheme.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: trailing,
        onTap: onTap,
        onLongPress: track.isRemote ? null : onLongPress,
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
