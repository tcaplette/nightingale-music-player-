import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class BlockedMutedScreen extends ConsumerWidget {
  const BlockedMutedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(socialGraphProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Blocked & Muted'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Blocked'),
              Tab(text: 'Muted'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BlockedList(blocks: state.blocks),
            _MutedList(mutes: state.mutes),
          ],
        ),
      ),
    );
  }
}

class _BlockedList extends ConsumerWidget {
  const _BlockedList({required this.blocks});
  final List<BlocksTableData> blocks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (blocks.isEmpty) {
      return _EmptyState(message: 'No blocked accounts');
    }
    return ListView.builder(
      itemCount: blocks.length,
      itemBuilder: (_, i) {
        final block = blocks[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          title: Text(_displayName(block.actorUrl)),
          trailing: TextButton(
            onPressed: () => ref
                .read(socialGraphProvider.notifier)
                .unblockActor(block.actorUrl),
            child: const Text('Unblock'),
          ),
        );
      },
    );
  }
}

class _MutedList extends ConsumerWidget {
  const _MutedList({required this.mutes});
  final List<MutesTableData> mutes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mutes.isEmpty) {
      return _EmptyState(message: 'No muted accounts');
    }
    return ListView.builder(
      itemCount: mutes.length,
      itemBuilder: (_, i) {
        final mute = mutes[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          title: Text(_displayName(mute.actorUrl)),
          trailing: TextButton(
            onPressed: () => ref
                .read(socialGraphProvider.notifier)
                .unmuteActor(mute.actorUrl),
            child: const Text('Unmute'),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.neutral400),
      ),
    );
  }
}

String _displayName(String actorUrl) {
  try {
    return Uri.parse(actorUrl).pathSegments.last;
  } catch (_) {
    return actorUrl;
  }
}
