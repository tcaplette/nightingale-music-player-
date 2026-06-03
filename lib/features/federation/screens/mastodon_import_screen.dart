import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/discovery/mastodon_bridge_service.dart';
import 'package:nightingale/features/onboarding/mastodon_account_provider.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

sealed class _ImportState {}

class _ImportIdle extends _ImportState {}

class _ImportLoading extends _ImportState {}

class _ImportDone extends _ImportState {
  _ImportDone(this.matches);
  final List<MastodonMatch> matches;
}


/// Screen for importing a user's Mastodon social graph into Nightingale.
///
/// Shows which Mastodon connections are already on Nightingale (via the
/// `x-nightingale-actor-url` extension field) and lets the user follow them
/// individually or all at once.
class MastodonImportScreen extends ConsumerStatefulWidget {
  const MastodonImportScreen({super.key, this.onDone, this.initialHandle});

  /// Called when the import is complete or dismissed. Use to advance onboarding.
  final VoidCallback? onDone;

  /// Pre-fills the handle input. Passed from the onboarding Mastodon step.
  final String? initialHandle;

  @override
  ConsumerState<MastodonImportScreen> createState() =>
      _MastodonImportScreenState();
}

class _MastodonImportScreenState extends ConsumerState<MastodonImportScreen> {
  final _controller = TextEditingController();
  _ImportState _state = _ImportIdle();
  String? _validationError;
  final Set<String> _followed = {};
  bool _followingAll = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialHandle != null) {
      _controller.text = widget.initialHandle!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _import());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHandleChanged(String value) {
    if (_validationError != null) {
      setState(() => _validationError = null);
    }
  }

  Future<void> _import() async {
    final handle = _controller.text.trim();
    final error = MastodonBridgeService.validateHandle(handle);
    if (error != null) {
      setState(() => _validationError = error);
      return;
    }

    setState(() {
      _state = _ImportLoading();
      _validationError = null;
    });

    final bridge = sl<MastodonBridgeService>();
    final matches = await bridge.importSocialGraph(handle);

    if (!mounted) return;
    await sl<SecureStorageService>().setMastodonHandle(handle);
    ref.invalidate(mastodonAccountProvider);
    setState(() => _state = _ImportDone(matches));
  }

  Future<void> _follow(String actorUrl) async {
    await ref.read(socialGraphProvider.notifier).followActor(actorUrl);
    if (mounted) setState(() => _followed.add(actorUrl));
  }

  Future<void> _followAll(List<MastodonMatch> matches) async {
    setState(() => _followingAll = true);
    for (final match in matches) {
      if (!_followed.contains(match.actorUrl)) {
        await _follow(match.actorUrl);
      }
    }
    if (mounted) setState(() => _followingAll = false);
    widget.onDone?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accountAsync = ref.watch(mastodonAccountProvider);
    final connectedHandle = accountAsync.valueOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Mastodon'),
        actions: [
          if (widget.onDone != null)
            TextButton(
              onPressed: widget.onDone,
              child: Text(
                'Skip',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          if (connectedHandle != null) ...[
            _ConnectionBanner(handle: connectedHandle),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            'Find your Mastodon connections on Nightingale',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter your Mastodon handle to see which of your connections are already here.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _controller,
            onChanged: _onHandleChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _import(),
            decoration: InputDecoration(
              hintText: '@you@mastodon.social',
              errorText: _validationError,
              suffixIcon: _state is _ImportLoading
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
                      onPressed: _import,
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildResults(theme),
        ],
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final state = _state;
    if (state is _ImportLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is _ImportDone) {
      if (state.matches.isEmpty) {
        return _EmptyState(onDone: widget.onDone);
      }
      return _MatchList(
        matches: state.matches,
        followed: _followed,
        followingAll: _followingAll,
        onFollow: _follow,
        onFollowAll: () => _followAll(state.matches),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.handle});
  final String handle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Connected as $handle',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onDone});
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'None of your Mastodon connections are on Nightingale yet.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Share Nightingale with your Mastodon network to grow your circle.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (onDone != null)
          TextButton(
            onPressed: onDone,
            child: const Text('Continue'),
          ),
      ],
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList({
    required this.matches,
    required this.followed,
    required this.followingAll,
    required this.onFollow,
    required this.onFollowAll,
  });

  final List<MastodonMatch> matches;
  final Set<String> followed;
  final bool followingAll;
  final Future<void> Function(String actorUrl) onFollow;
  final VoidCallback onFollowAll;

  bool get _allFollowed => matches.every((m) => followed.contains(m.actorUrl));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${matches.length} connection${matches.length == 1 ? '' : 's'} found',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const Spacer(),
            if (!_allFollowed)
              FilledButton(
                onPressed: followingAll ? null : onFollowAll,
                child: followingAll
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Follow all'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ...matches.map((match) => _MatchCard(
              match: match,
              isFollowed: followed.contains(match.actorUrl),
              onFollow: () => onFollow(match.actorUrl),
            )),
      ],
    );
  }
}

class _MatchCard extends StatefulWidget {
  const _MatchCard({
    required this.match,
    required this.isFollowed,
    required this.onFollow,
  });

  final MastodonMatch match;
  final bool isFollowed;
  final VoidCallback onFollow;

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  bool _loading = false;

  Future<void> _tap() async {
    setState(() => _loading = true);
    widget.onFollow();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: PersonDisplay(
                  displayName: widget.match.displayName,
                  avatarUrl: widget.match.avatarUrl,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              widget.isFollowed
                  ? const OutlinedButton(
                      onPressed: null,
                      child: Text('Following'),
                    )
                  : FilledButton(
                      onPressed: _loading ? null : _tap,
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
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
