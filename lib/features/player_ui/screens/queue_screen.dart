import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/audio/playback_state_model.dart' as ps;
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackAsync = ref.watch(playbackProvider);
    final state = playbackAsync.valueOrNull ?? ps.PlaybackStateModel.empty;
    final queue = state.queue;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          if (queue.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(playbackProvider.notifier).clearAll(),
              child: Text(
                'Clear',
                style: textTheme.labelMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
        ],
      ),
      body: queue.isEmpty
          ? Center(
              child: Text(
                'Queue is empty',
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            )
          : ReorderableListView.builder(
              itemCount: queue.length,
              onReorder: (from, to) {
                final adjustedTo = to > from ? to - 1 : to;
                ref.read(playbackProvider.notifier).reorder(from, adjustedTo);
              },
              buildDefaultDragHandles: false,
              itemBuilder: (context, i) {
                final track = queue[i];
                final isCurrent = i == state.currentIndex;
                return Dismissible(
                  key: ValueKey('${track.id}_$i'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.md),
                    color: scheme.errorContainer,
                    child: Icon(Icons.delete, color: scheme.onErrorContainer),
                  ),
                  onDismissed: (_) =>
                      ref.read(playbackProvider.notifier).removeAt(i),
                  child: ListTile(
                    key: ValueKey('tile_${track.id}_$i'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    tileColor: isCurrent
                        ? scheme.primary.withValues(alpha: 0.08)
                        : null,
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ReorderableDragStartListener(
                          index: i,
                          child: Icon(
                            Icons.drag_handle,
                            color: scheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (isCurrent)
                          Icon(
                            Icons.equalizer,
                            size: 18,
                            color: scheme.primary,
                          )
                        else
                          SizedBox(
                            width: 18,
                            child: Text(
                              '${i + 1}',
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.4),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      track.title,
                      style: textTheme.bodyLarge?.copyWith(
                        fontWeight: isCurrent ? FontWeight.w600 : null,
                        color: isCurrent ? scheme.primary : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      track.artist,
                      style: textTheme.labelMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
