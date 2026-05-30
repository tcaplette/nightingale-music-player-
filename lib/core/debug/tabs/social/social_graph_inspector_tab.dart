import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class SocialGraphInspectorTab extends ConsumerWidget {
  const SocialGraphInspectorTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      kDebugMode,
      'SocialGraphInspectorTab must only be used in debug builds',
    );

    final state = ref.watch(socialGraphProvider);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.sm),
      children: [
        _Row('Following', '${state.following.length}'),
        _Row('Followers', '${state.followers.length}'),
        _Row('Outgoing pending', '${state.outgoingPending.length}'),
        _Row('Incoming pending', '${state.incomingPending.length}'),
        _Row('Blocked', '${state.blocks.length}'),
        _Row('Muted', '${state.mutes.length}'),
        if (state.blocks.isNotEmpty) ...[
          const Divider(),
          const _SectionLabel('Blocked'),
          for (final b in state.blocks)
            _ActorRow(b.actorUrl),
        ],
        if (state.mutes.isNotEmpty) ...[
          const Divider(),
          const _SectionLabel('Muted'),
          for (final m in state.mutes)
            _ActorRow(m.actorUrl),
        ],
        if (state.outgoingPending.isNotEmpty) ...[
          const Divider(),
          const _SectionLabel('Outgoing Pending'),
          for (final r in state.outgoingPending)
            _Row(r.actorUrl, r.state),
        ],
        if (state.incomingPending.isNotEmpty) ...[
          const Divider(),
          const _SectionLabel('Incoming Pending'),
          for (final r in state.incomingPending)
            _Row(r.actorUrl, r.state),
        ],
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.neutral400,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 3,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.neutral400,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _ActorRow extends StatelessWidget {
  const _ActorRow(this.url);
  final String url;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Text(
          url,
          style: const TextStyle(
            color: AppColors.neutral600,
            fontSize: 10,
            fontFamily: 'monospace',
          ),
          overflow: TextOverflow.ellipsis,
        ),
      );
}
