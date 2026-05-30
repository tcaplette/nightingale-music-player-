import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/features/recommendations/domain/recommendation_result.dart';
import 'package:nightingale/features/discover/widgets/provenance_chip.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_motion.dart';
import 'package:nightingale/shared/theme/app_radius.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class RecommendationCard extends ConsumerStatefulWidget {
  const RecommendationCard({
    super.key,
    required this.result,
    this.actorAvatarUrl,
    required this.onSave,
  });

  final RecommendationResult result;
  final String? actorAvatarUrl;
  final VoidCallback onSave;

  @override
  ConsumerState<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends ConsumerState<RecommendationCard> {
  bool _saved = false;
  bool _streaming = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;
    final isHostless = result.streamUrl == null && result.hostNodeUrl == null;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _Artwork(url: result.trackArtworkUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.trackTitle,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    result.trackArtist,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.neutral400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ProvenanceChip(
                    provenance: result.provenance,
                    avatarUrl: widget.actorAvatarUrl,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Actions — one primary (stream), one secondary (save)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isHostless)
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 20,
                    color: AppColors.neutral400,
                  )
                else
                  _StreamButton(
                    streaming: _streaming,
                    onTap: _handleStream,
                  ),
                const SizedBox(height: AppSpacing.xs),
                _SaveButton(
                  saved: _saved,
                  onTap: _handleSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStream() async {
    if (_streaming) return;
    setState(() => _streaming = true);

    final result = widget.result;
    final streamUrl = result.streamUrl ?? result.hostNodeUrl;
    if (streamUrl == null) {
      setState(() => _streaming = false);
      return;
    }

    final track = TrackModel(
      id: result.trackFingerprint.hashCode,
      filePath: streamUrl,
      title: result.trackTitle,
      artist: result.trackArtist,
      durationMs: 0,
      dateAdded: DateTime.now(),
      sourceActorUrl: result.hostNodeUrl,
      streamUrl: result.streamUrl,
    );

    await ref.read(playbackProvider.notifier).loadAndPlay([track]);
    if (mounted) setState(() => _streaming = false);
  }

  void _handleSave() {
    if (_saved) return;
    setState(() => _saved = true);
    widget.onSave();
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    const size = 56.0;
    final placeholder = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.neutral200,
        borderRadius: AppRadius.smAll,
      ),
      child: const Icon(
        Icons.music_note,
        color: AppColors.neutral400,
        size: 24,
      ),
    );

    if (url == null) return placeholder;

    return ClipRRect(
      borderRadius: AppRadius.smAll,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => placeholder,
        errorWidget: (_, _, _) => placeholder,
      ),
    );
  }
}

class _StreamButton extends StatelessWidget {
  const _StreamButton({required this.streaming, required this.onTap});
  final bool streaming;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.micro,
        curve: AppMotion.curveMicro,
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: streaming
            ? const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : const Icon(Icons.play_arrow, color: Colors.white, size: 20),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onTap});
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: AppMotion.micro,
        child: Icon(
          key: ValueKey(saved),
          saved ? Icons.bookmark : Icons.bookmark_border,
          color: saved ? AppColors.accent : AppColors.neutral400,
          size: 22,
        ),
      ),
    );
  }
}
