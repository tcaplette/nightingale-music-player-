import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/features/federation/discovery/peer_discovery_service.dart';
import 'package:nightingale/features/federation/mdns/mdns_discovery_service.dart';
import 'package:nightingale/features/federation/screens/mastodon_import_screen.dart';
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
  _LookupState _lookupState = _LookupIdle();
  List<MdnsPeer> _nearbyPeers = [];
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _loadNearbyPeers();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadNearbyPeers() {
    try {
      final peers = sl<MdnsDiscoveryService>().peers.values.toList();
      setState(() => _nearbyPeers = peers);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await sl<MdnsDiscoveryService>().refresh();
      // Give mDNS a moment to populate results.
      await Future.delayed(const Duration(seconds: 2));
      _loadNearbyPeers();
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _resolveByUsername(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    setState(() => _lookupState = _LookupLoading());

    ApActor? actor;

    // Full WebFinger handle (@user@instance) — resolve directly.
    if (trimmed.contains('@')) {
      final result = await sl<ActorResolver>().resolve(trimmed);
      if (result is ResolveOk) actor = result.actor;
    } else {
      // Plain username — search via mDNS, actor cache, social graph.
      actor = await sl<PeerDiscoveryService>().searchByUsername(trimmed);
    }

    if (!mounted) return;
    if (actor != null) {
      setState(() => _lookupState = _LookupFound(actor!));
    } else {
      setState(() => _lookupState = _LookupFailed(
            'Couldn\'t find "$trimmed". Make sure the handle is correct and their device is reachable.',
          ));
    }
  }

  Future<void> _resolveUrl(String actorUrl) async {
    setState(() => _lookupState = _LookupLoading());
    final result = await sl<PeerDiscoveryService>()
        .searchByUsername(Uri.parse(actorUrl).pathSegments.last);
    if (!mounted) return;
    if (result != null) {
      setState(() => _lookupState = _LookupFound(result));
    } else {
      setState(() => _lookupState = _LookupFailed(
            'Couldn\'t reach that node.',
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find people')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _buildMastodonSection(context),
          const SizedBox(height: AppSpacing.xl),
          _buildNearbySection(),
          const SizedBox(height: AppSpacing.xl),
          _buildManualSection(),
        ],
      ),
    );
  }

  Widget _buildMastodonSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'From Mastodon',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Already on Mastodon? See which of your connections are here.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral400,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => MastodonImportScreen(
                onDone: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          icon: const Icon(Icons.link, size: 18),
          label: const Text('Connect Mastodon'),
        ),
      ],
    );
  }

  Widget _buildNearbySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Nearby',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            _refreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: _refresh,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                    ),
                    child: const Text('Refresh', style: TextStyle(fontSize: 12)),
                  ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_nearbyPeers.isEmpty)
          Text(
            _refreshing
                ? 'Scanning for nearby nodes…'
                : 'No Nightingale nodes found on this network.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.neutral400,
                ),
          )
        else
          ..._nearbyPeers.map(
            (peer) => _NearbyPeerTile(
              peer: peer,
              onTap: () => _resolveUrl(peer.actorUrl),
            ),
          ),
        if (_lookupState is _LookupLoading)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_lookupState is _LookupFound)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _ActorResultCard(actor: (_lookupState as _LookupFound).actor),
          ),
        if (_lookupState is _LookupFailed)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              (_lookupState as _LookupFailed).message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.neutral400,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildManualSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find by username',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Enter a username or Mastodon-style handle (@you@instance.social) to find someone directly.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.neutral400,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          onSubmitted: _resolveByUsername,
          decoration: InputDecoration(
            hintText: 'Username or @you@instance.social',
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _resolveByUsername(_controller.text),
            ),
          ),
        ),
      ],
    );
  }
}

class _NearbyPeerTile extends StatelessWidget {
  const _NearbyPeerTile({required this.peer, required this.onTap});
  final MdnsPeer peer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(
        child: Icon(Icons.person_outline, size: 20),
      ),
      title: Text(peer.username),
      subtitle: Text(
        '${peer.ip}:${peer.port}',
        style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
    );
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
          return const OutlinedButton(onPressed: null, child: Text('Following'));
        }
        if (followState == 'pending' || followState == 'pending_delivery') {
          return const OutlinedButton(onPressed: null, child: Text('Requested'));
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
    await ref.read(socialGraphProvider.notifier).followActor(widget.actorUrl);
    if (mounted) setState(() => _loading = false);
  }
}
