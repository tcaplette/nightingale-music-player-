import 'package:flutter/material.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/app_database.dart' show ActorCacheTableData;
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class ActorCachePanel extends StatefulWidget {
  const ActorCachePanel({super.key});

  @override
  State<ActorCachePanel> createState() => _ActorCachePanelState();
}

class _ActorCachePanelState extends State<ActorCachePanel> {
  List<ActorCacheTableData> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resolver = sl<ActorResolver>();
    final entries = await resolver.getCacheEntries();
    if (mounted) setState(() => _entries = entries);
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Cache empty',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: _load, child: const Text('Refresh')),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final e = _entries[i];
        final age = DateTime.now().toUtc().difference(e.cachedAt).inSeconds;
        final ttlLeft = e.ttlSeconds - age;
        return ListTile(
          dense: true,
          title: Text(e.actorUrl, style: const TextStyle(fontSize: 10)),
          subtitle: Text(
            'TTL: ${ttlLeft}s remaining',
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
          trailing: TextButton(
            onPressed: () async {
              await sl<ActorResolver>().invalidate(e.actorUrl);
              _load();
            },
            child: const Text('Invalidate', style: TextStyle(fontSize: 10)),
          ),
        );
      },
    );
  }
}
