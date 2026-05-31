import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/audio/playback_engine.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';
import 'package:nightingale/features/settings/models/playback_settings.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class PlaybackSettingsScreen extends ConsumerStatefulWidget {
  const PlaybackSettingsScreen({super.key});

  @override
  ConsumerState<PlaybackSettingsScreen> createState() =>
      _PlaybackSettingsScreenState();
}

class _PlaybackSettingsScreenState
    extends ConsumerState<PlaybackSettingsScreen> {
  late BufferPreset _bufferPreset;
  late SkipThreshold _skipThreshold;
  late AudioFocusBehaviour _audioFocus;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = sl<SettingsRepository>();
    final settings = await repo.loadPlaybackSettings();
    if (!mounted) return;
    setState(() {
      _bufferPreset = settings.bufferPreset;
      _skipThreshold = settings.skipThreshold;
      _audioFocus = settings.audioFocusBehaviour;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Playback')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _SectionHeader('Audio Buffer'),
          ListTile(
            title: const Text('Buffer size'),
            subtitle: Text(_bufferPreset.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showOptions<BufferPreset>(
              title: 'Buffer size',
              values: BufferPreset.values,
              current: _bufferPreset,
              label: (v) => v.label,
              onSelected: (v) async {
                await sl<SettingsRepository>().setBufferPreset(v);
                setState(() => _bufferPreset = v);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Buffer size change takes effect next time the app opens.'),
                    ),
                  );
                }
              },
            ),
          ),
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Controls'),
          ListTile(
            title: const Text('Skip previous sensitivity'),
            subtitle: Text(_skipThreshold.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showOptions<SkipThreshold>(
              title: 'Skip previous sensitivity',
              values: SkipThreshold.values,
              current: _skipThreshold,
              label: (v) => v.label,
              onSelected: (v) async {
                await sl<SettingsRepository>().setSkipThreshold(v);
                sl<PlaybackEngine>().setSkipThreshold(v);
                setState(() => _skipThreshold = v);
              },
            ),
          ),
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Audio Focus'),
          ListTile(
            title: const Text('When another app takes audio'),
            subtitle: Text(_audioFocus.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showOptions<AudioFocusBehaviour>(
              title: 'Audio focus',
              values: AudioFocusBehaviour.values,
              current: _audioFocus,
              label: (v) => v.label,
              onSelected: (v) async {
                await sl<SettingsRepository>().setAudioFocusBehaviour(v);
                sl<PlaybackEngine>().setAudioFocusBehaviour(v);
                setState(() => _audioFocus = v);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOptions<T>({
    required String title,
    required List<T> values,
    required T current,
    required String Function(T) label,
    required Future<void> Function(T) onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Text(title,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final v in values)
              RadioListTile<T>(
                title: Text(label(v)),
                value: v,
                groupValue: current,
                onChanged: (sel) async {
                  Navigator.of(ctx).pop();
                  if (sel != null) await onSelected(sel);
                },
                dense: true,
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.0,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
