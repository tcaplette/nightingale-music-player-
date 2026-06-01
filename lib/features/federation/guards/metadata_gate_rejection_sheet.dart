import 'package:flutter/material.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/services/metadata_validator.dart';
import 'package:nightingale/features/library/widgets/metadata_editor_sheet.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Shows a bottom sheet explaining which required fields are missing and
/// offering to open the metadata editor for the affected track.
Future<void> showMetadataGateRejectionSheet(
  BuildContext context,
  TrackModel track,
  MetadataIncompleteException error,
) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _RejectionSheet(
      track: track,
      missingFields: error.missingFields,
    ),
  );
}

class _RejectionSheet extends StatelessWidget {
  const _RejectionSheet({
    required this.track,
    required this.missingFields,
  });

  final TrackModel track;
  final List<String> missingFields;

  static const _labels = {
    'title': 'Title',
    'artist': 'Artist',
    'album': 'Album',
    'albumArtist': 'Album Artist',
    'artworkPath': 'Artwork',
    'genre': 'Genre',
    'releaseYear': 'Release Year',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
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
          Row(
            children: [
              const Icon(Icons.block, color: Color(0xFFFF3B30), size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text('Cannot share this track', style: textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '"${track.title}" is missing required metadata:',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...missingFields.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.radio_button_unchecked,
                    size: 14,
                    color: Color(0xFFFF3B30),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    _labels[f] ?? f,
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Fix metadata'),
              onPressed: () {
                Navigator.of(context).pop();
                showMetadataEditorSheet(context, track);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}
