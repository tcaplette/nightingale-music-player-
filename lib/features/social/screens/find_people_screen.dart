import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

sealed class _LookupState {}
class _LookupIdle extends _LookupState {}
class _LookupLoading extends _LookupState {}
class _LookupFound extends _LookupState {
  _LookupFound(this.actor);
  final ApActor actor;
}
class _LookupFailed extends _LookupState {
  _LookupFailed(this.message);
  final String message;
}

class FindPeopleScreen extends ConsumerStatefulWidget {
  const FindPeopleScreen({super.key});

  @override
  ConsumerState<FindPeopleScreen> createState() => _FindPeopleScreenState();
}

class _FindPeopleScreenState extends ConsumerState<FindPeopleScreen> {
  final _controller = TextEditingController();
  _LookupState _state = _LookupIdle();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() => _state = _LookupLoading());

    final result = await sl<ActorResolver>().resolve(input);

    if (!mounted) return;
    setState(() {
      _state = switch (result) {
        ResolveOk(:final actor) => _LookupFound(actor),
        ResolveFailed(:final reason) => _LookupFailed(
            reason.contains('404') || reason.contains('failed')
                ? 'Couldn\'t find anyone at that address.'
                : 'Couldn\'t reach that address. Check your connection and try again.',
          ),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find people')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _resolve(),
              decoration: InputDecoration(
                hintText: '@username@instance or https://…',
                suffixIcon: _state is _LookupLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _resolve,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    return switch (_state) {
      _LookupIdle() => const SizedBox.shrink(),
      _LookupLoading() => const SizedBox.shrink(),
      _LookupFailed(:final message) => Text(
          message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.neutral400),
        ),
      _LookupFound(:final actor) => _ActorResultCard(actor: actor),
    };
  }
}

class _ActorResultCard extends ConsumerWidget {
  const _ActorResultCard({required this.actor});
  final ApActor actor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = Uri.tryParse(actor.id)?.host ?? actor.id;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => context.push(
                  '/profile/${Uri.encodeComponent(actor.id)}',
                ),
                child: PersonDisplay(
                  displayName: actor.name.isNotEmpty
                      ? actor.name
                      : actor.preferredUsername,
                  handle: '@${actor.preferredUsername}@$node',
                  avatarUrl: actor.icon,
                  showHandle: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _FollowButton(actorUrl: actor.id),
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({required this.actorUrl});
  final String actorUrl;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ref
          .read(socialGraphProvider.notifier)
          .getFollowState(widget.actorUrl),
      builder: (context, snapshot) {
        final followState = snapshot.data;

        if (followState == 'accepted') {
          return const OutlinedButton(
            onPressed: null,
            child: Text('Following'),
          );
        }
        if (followState == 'pending' || followState == 'pending_delivery') {
          return const OutlinedButton(
            onPressed: null,
            child: Text('Requested'),
          );
        }

        return FilledButton(
          onPressed: _loading ? null : _follow,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Follow'),
        );
      },
    );
  }

  Future<void> _follow() async {
    setState(() => _loading = true);
    await ref
        .read(socialGraphProvider.notifier)
        .followActor(widget.actorUrl);
    if (mounted) setState(() => _loading = false);
  }
}
