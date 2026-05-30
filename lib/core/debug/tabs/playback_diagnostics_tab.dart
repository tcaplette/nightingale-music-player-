import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/audio/audio_source.dart';
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/features/playback/providers/playback_providers.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Only used in debug builds. Registered via DebugOverlayController.addTab.
class PlaybackDiagnosticsTab extends ConsumerWidget {
  const PlaybackDiagnosticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(kDebugMode);
    final playbackAsync = ref.watch(playbackProvider);
    final state = playbackAsync.valueOrNull ?? PlaybackStateModel.empty;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _DiagRow('Status', state.status.name),
        _DiagRow(
          'Position',
          '${_fmt(state.position)} / ${_fmt(state.duration)}',
        ),
        _DiagRow('Buffered', _fmt(state.bufferStatus.bufferedDuration)),
        _DiagRow('Buffer health', state.bufferStatus.health.name),
        _DiagRow('Shuffle', state.shuffleMode.name),
        _DiagRow('Repeat', state.repeatMode.name),
        _DiagRow(
          'Stream source',
          switch (state.streamSourceType) {
            LocalAudioSource(:final filePath) => 'local: $filePath',
            RemoteAudioSource(:final uri) => 'remote: $uri',
            null => '—',
          },
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'QUEUE',
          style: TextStyle(
            color: AppColors.neutral400,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < state.queue.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${i == state.currentIndex ? "▶ " : "  "}[$i] ${state.queue[i].title} — ${state.queue[i].artist}',
              style: TextStyle(
                color: i == state.currentIndex
                    ? AppColors.accent
                    : AppColors.neutral500,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        if (state.queue.isEmpty)
          const Text(
            'Queue empty',
            style: TextStyle(color: AppColors.neutral400, fontSize: 11),
          ),
      ],
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _DiagRow extends StatelessWidget {
  const _DiagRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.neutral400,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.neutral700,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
