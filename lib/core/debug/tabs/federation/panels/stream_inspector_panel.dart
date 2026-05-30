import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/streaming/audio_cache_manager.dart';
import 'package:nightingale/features/federation/streaming/stream_resolver.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Debug panel showing active streams, cache status, and buffer health.
class StreamInspectorPanel extends StatefulWidget {
  const StreamInspectorPanel({super.key});

  @override
  State<StreamInspectorPanel> createState() => _StreamInspectorPanelState();
}

class _StreamInspectorPanelState extends State<StreamInspectorPanel> {
  final _cacheManager = sl<AudioCacheManager>();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _section('Stream Resolver', [
          _row('Fallback Chain', 'direct → relay → cache → unavailable'),
        ]),
        const Divider(),
        _section('Cache Status', [
          _row('Max Size', '2 GB'),
          _actionRow('Clear Cache', _clearCache),
        ]),
        const Divider(),
        _section('Buffer Health', [
          _row('Status', 'Not currently streaming'),
          _row('Buffered', '—'),
          _row('Source', '—'),
        ]),
      ],
    );
  }

  Future<void> _clearCache() async {
    // TODO: Implement cache clearing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache clear not yet implemented')),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: AppSpacing.sm),
        ...children,
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _row(String key, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(key, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 10)),
        ),
      ],
    ),
  );

  Widget _actionRow(String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox(width: 110),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    ),
  );
}
