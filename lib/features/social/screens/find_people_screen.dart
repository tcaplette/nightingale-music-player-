import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/activitypub/models/ap_actor.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/features/federation/discovery/mastodon_auth_webview.dart';
import 'package:nightingale/features/federation/discovery/mastodon_bridge_service.dart';
import 'package:nightingale/features/federation/discovery/mastodon_oauth_service.dart';
import 'package:nightingale/features/federation/discovery/peer_discovery_service.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';
import 'package:nightingale/features/social/providers/social_graph_notifier.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// ── Lookup state ──────────────────────────────────────────────────────────────

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

// ── Mastodon import state ─────────────────────────────────────────────────────

sealed class _ImportState {}
class _ImportIdle extends _ImportState {}
class _ImportLoading extends _ImportState {}
class _ImportDone extends _ImportState {
  _ImportDone(this.matches);
  final List<MastodonMatch> matches;
}
class _ImportFailed extends _ImportState {
  _ImportFailed(this.message);
  final String message;
}

// ── Screen ────────────────────────────────────────────────────────────────────

class FindPeopleScreen extends ConsumerStatefulWidget {
  const FindPeopleScreen({super.key});

  @override
  ConsumerState<FindPeopleScreen> createState() => _FindPeopleScreenState();
}

class _FindPeopleScreenState extends ConsumerState<FindPeopleScreen> {
  final _searchController = TextEditingController();
  final _instanceController = TextEditingController();
  _LookupState _lookupState = _LookupIdle();
  _ImportState _importState = _ImportIdle();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromStoredAccount());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _instanceController.dispose();
    super.dispose();
  }

  Future<void> _initFromStoredAccount() async {
    // Check for a handle stored during onboarding first.
    final storedHandle = await sl<SecureStorageService>().getMastodonHandle();
    final instance = storedHandle != null
        ? _instanceFromHandle(storedHandle)
        : _instanceController.text.trim();

    if (instance == null || instance.isEmpty) return;

    // Pre-fill with the stored handle so the user doesn't have to re-type it.
    if (_instanceController.text.trim().isEmpty && storedHandle != null) {
      _instanceController.text = storedHandle;
    }

    // If we already have an OAuth token, run the import automatically.
    final token = await sl<MastodonOAuthService>().getStoredToken(instance);
    if (token != null) {
      await _runImport(instance, token);
    }
  }

  static String? _instanceFromHandle(String handle) {
    // Accepts @user@instance.social or user@instance.social
    final stripped = handle.startsWith('@') ? handle.substring(1) : handle;
    final parts = stripped.split('@');
    if (parts.length != 2 || parts[1].isEmpty) return null;
    return parts[1];
  }

  Future<void> _signInWithMastodon() async {
    final handle = _instanceController.text.trim();
    if (handle.isEmpty) {
      setState(() => _importState = _ImportFailed('Enter your Mastodon account first.'));
      return;
    }
    setState(() => _importState = _ImportLoading());

    final oauthService = sl<MastodonOAuthService>();
    final prepared = await oauthService.prepareSignIn(handle);
    if (!mounted) return;

    if (prepared == null) {
      setState(() => _importState = _ImportFailed('Could not reach that Mastodon server. Check your handle and try again.'));
      return;
    }

    final callbackUrl = await MastodonAuthWebView.show(
      context,
      authUrl: prepared.authUrl,
      callbackScheme: 'nightingale',
    );
    if (!mounted) return;

    final result = await oauthService.completeSignIn(prepared, callbackUrl);
    if (!mounted) return;

    switch (result) {
      case OAuthSuccess(:final accessToken, :final instance):
        await _runImport(instance, accessToken);
      case OAuthCancelled():
        setState(() => _importState = _ImportIdle());
      case OAuthFailed(:final reason):
        setState(() => _importState = _ImportFailed(reason));
    }
  }

  Future<void> _runImport(String instance, String accessToken) async {
    setState(() => _importState = _ImportLoading());
    final matches = await sl<MastodonBridgeService>()
        .importSocialGraphAuthenticated(instance, accessToken);
    if (!mounted) return;
    setState(() => _importState = _ImportDone(matches));
  }

  Future<void> _disconnect() async {
    final instance = _instanceController.text.trim();
    await sl<MastodonOAuthService>().signOut(instance);
    if (!mounted) return;
    setState(() => _importState = _ImportIdle());
  }

  Future<void> _resolveByUsername(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;
    setState(() => _lookupState = _LookupLoading());

    ApActor? actor;
    if (trimmed.contains('@') &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://')) {
      final result = await sl<ActorResolver>().resolve(trimmed);
      if (result is ResolveOk) actor = result.actor;
    } else if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final result = await sl<ActorResolver>().resolve(trimmed);
      if (result is ResolveOk) actor = result.actor;
    } else {
      actor = await sl<PeerDiscoveryService>().searchByUsername(trimmed);
    }

    if (!mounted) return;
    if (actor != null) {
      setState(() => _lookupState = _LookupFound(actor!));
    } else {
      setState(() => _lookupState = _LookupFailed(
            'Couldn\'t find "$trimmed". Try signing in with Mastodon to find people from your network.',
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
          _buildManualSection(),
        ],
      ),
    );
  }

  Widget _buildMastodonSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('From Mastodon', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Sign in with your Mastodon account to see which of your connections are on Nightingale.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.neutral400),
        ),
        const SizedBox(height: AppSpacing.md),

        if (_importState is _ImportIdle || _importState is _ImportFailed) ...[
          TextField(
            controller: _instanceController,
            decoration: const InputDecoration(
              labelText: 'Mastodon handle',
              hintText: '@you@mastodon.social',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _signInWithMastodon,
              child: const Text('Sign in with Mastodon'),
            ),
          ),
          if (_importState is _ImportFailed) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              (_importState as _ImportFailed).message,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
        ],

        if (_importState is _ImportLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),

        if (_importState is _ImportDone) ...[
          _ConnectedBanner(
            instance: _instanceController.text.trim(),
            onDisconnect: _disconnect,
          ),
          const SizedBox(height: AppSpacing.md),
          _MatchResults(matches: (_importState as _ImportDone).matches),
        ],
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
          'Search for someone you may already be connected to, or paste a link they shared with you.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.neutral400),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: _resolveByUsername,
          decoration: InputDecoration(
            hintText: 'Username or paste a shared link',
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _resolveByUsername(_searchController.text),
            ),
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
            child: _ActorResultCard(
              actor: (_lookupState as _LookupFound).actor,
            ),
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
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ConnectedBanner extends StatelessWidget {
  const _ConnectedBanner({required this.instance, required this.onDisconnect});
  final String instance;
  final VoidCallback onDisconnect;

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
          Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Connected to $instance',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onDisconnect,
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}

class _MatchResults extends ConsumerWidget {
  const _MatchResults({required this.matches});
  final List<MastodonMatch> matches;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (matches.isEmpty) {
      return Text(
        'None of your Mastodon connections are on Nightingale yet.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.neutral400),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${matches.length} connection${matches.length == 1 ? '' : 's'} found',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final match in matches)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: PersonDisplay(
                        displayName: match.displayName,
                        avatarUrl: match.avatarUrl,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _FollowButton(actorUrl: match.actorUrl),
                  ],
                ),
              ),
            ),
          ),
      ],
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
                  displayName:
                      actor.name.isNotEmpty ? actor.name : actor.preferredUsername,
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
