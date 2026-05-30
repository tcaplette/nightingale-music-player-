import 'package:flutter/material.dart';
import 'package:nightingale/core/database/app_database.dart' show DefederatedNodesTableData;
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/moderation/moderation_repository.dart';
import 'package:nightingale/features/federation/moderation/rate_limiter.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class ModerationStatePanel extends StatefulWidget {
  const ModerationStatePanel({super.key});

  @override
  State<ModerationStatePanel> createState() => _ModerationStatePanelState();
}

class _ModerationStatePanelState extends State<ModerationStatePanel> {
  List<DefederatedNodesTableData> _blocked = [];
  Map<String, ({int count, int windowSeconds, DateTime windowStart})>
      _rateLimits = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = sl<ModerationRepository>();
    final rl = sl<RateLimiter>();
    final blocked = await repo.getDefederatedNodes();
    if (mounted) {
      setState(() {
        _blocked = blocked;
        _rateLimits = rl.liveCounters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Text('Defederated nodes',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        if (_blocked.isEmpty)
          const Text('None', style: TextStyle(fontSize: 10, color: Colors.grey))
        else
          for (final node in _blocked)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${node.domain} · blocked ${node.blockedAt.toIso8601String()}',
                style: const TextStyle(fontSize: 10),
              ),
            ),
        const SizedBox(height: AppSpacing.md),
        const Text('Rate limit counters',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        if (_rateLimits.isEmpty)
          const Text('No active windows',
              style: TextStyle(fontSize: 10, color: Colors.grey))
        else
          for (final entry in _rateLimits.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${entry.key}: ${entry.value.count}/${entry.value.windowSeconds}s',
                style: const TextStyle(fontSize: 10),
              ),
            ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: _load, child: const Text('Refresh')),
      ],
    );
  }
}
