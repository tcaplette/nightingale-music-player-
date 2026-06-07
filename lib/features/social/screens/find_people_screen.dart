import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/discovery/mastodon_auth_webview.dart';
import 'package:nightingale/features/federation/network/network_binding_service.dart';
import 'package:nightingale/features/federation/discovery/mastodon_bridge_service.dart';
import 'package:nightingale/features/federation/discovery/mastodon_oauth_service.dart';
import 'package:nightingale/features/federation/discovery/mastodon_profile_sync_service.dart';
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
  _LookupFound(this.match, this.mastodonHandle);
  final MastodonMatch match;
  final String mastodonHandle;
}
class _LookupFailed extends _LookupState {
  _LookupFailed(this.message);
  final String message;
}
class _LookupNotNightingale extends _LookupState {}

// ── Mastodon import state ─────────────────────────────────────────────────────

sealed class _ImportState {}
class _ImportIdle extends _ImportState {}
class _ImportAuthenticated extends _ImportState {
  _ImportAuthenticated(this.instance, this.token);
  final String instance;
  final String token;
}
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
    final storedHandle = await sl<SecureStorageService>().getMastodonHandle();
    if (storedHandle == null) return;

    final instance = _instanceFromHandle(storedHandle);
    if (instance == null || instance.isEmpty) return;

    if (_instanceController.text.trim().isEmpty) {
      _instanceController.text = storedHandle;
    }

    final token = await sl<MastodonOAuthService>().getStoredToken(instance);
    if (token != null) {
      setState(() => _importState = _ImportAuthenticated(instance, token));
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
        final handle = await sl<MastodonOAuthService>()
            .fetchAccountHandle(instance, accessToken);
        if (handle != null) {
          await sl<SecureStorageService>().setMastodonHandle(handle);
        }
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

    // Publish our address to Mastodon now that we have a valid token.
    _triggerProfileSync().ignore();
  }

  Future<void> _triggerProfileSync() async {
    // Re-run the full evaluate-and-bind cycle now that we have a Mastodon token.
    // NetworkBindingService builds the correct public actor URL and syncs it.
    sl<NetworkBindingService>().evaluateAndBind().ignore();
  }

  Future<void> _disconnect() async {
    final instance = _instanceController.text.trim();
    await sl<MastodonOAuthService>().signOut(instance);
    if (!mounted) return;
    setState(() => _importState = _ImportIdle());
  }

  Future<void> _lookupByHandle(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;

    if (!trimmed.contains('@')) {
      setState(() => _lookupState = _LookupFailed(
            'Enter a Mastodon handle like @alice@mastodon.social',
          ));
      return;
    }

    setState(() => _lookupState = _LookupLoading());

    final result = await sl<MastodonBridgeService>().lookupByHandle(trimmed);
    if (!mounted) return;

    switch (result) {
      case HandleLookupFound(:final match, :final mastodonHandle):
        setState(() => _lookupState = _LookupFound(match, mastodonHandle));
      case HandleLookupNotNightingale():
        setState(() => _lookupState = _LookupNotNightingale());
      case HandleLookupNotFound():
        setState(() => _lookupState = _LookupFailed(
              "Couldn't find that handle. Check the spelling and try again.",
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

        if (_importState is _ImportAuthenticated) ...[
          _ConnectedBanner(
            instance: (_importState as _ImportAuthenticated).instance,
            onDisconnect: _disconnect,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                final s = _importState as _ImportAuthenticated;
                _runImport(s.instance, s.token);
              },
              child: const Text('Find Nightingale connections'),
            ),
          ),
        ],

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
          if (sl<MastodonProfileSyncService>().needsReauth) ...[
            const SizedBox(height: AppSpacing.sm),
            _ReauthBanner(onReauth: _signInWithMastodon),
          ],
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
          'Find by Mastodon handle',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "Know someone's Mastodon handle? Enter it to see if they're on Nightingale.",
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.neutral400),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: _lookupByHandle,
          decoration: InputDecoration(
            hintText: '@alice@mastodon.social',
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _lookupByHandle(_searchController.text),
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
            child: _HandleResultCard(
              match: (_lookupState as _LookupFound).match,
              mastodonHandle: (_lookupState as _LookupFound).mastodonHandle,
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
        if (_lookupState is _LookupNotNightingale)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              "This person isn't on Nightingale yet.",
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

class _ReauthBanner extends StatelessWidget {
  const _ReauthBanner({required this.onReauth});
  final VoidCallback onReauth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: theme.colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Re-sign in with Mastodon so Nightingale can publish your address.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onReauth,
            child: const Text('Re-auth'),
          ),
        ],
      ),
    );
  }
}

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

class _HandleResultCard extends ConsumerWidget {
  const _HandleResultCard({
    required this.match,
    required this.mastodonHandle,
  });
  final MastodonMatch match;
  final String mastodonHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: PersonDisplay(
                displayName: match.displayName,
                handle: mastodonHandle,
                avatarUrl: match.avatarUrl,
                showHandle: true,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _FollowButton(actorUrl: match.actorUrl, mastodonHandle: mastodonHandle),
          ],
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({required this.actorUrl, this.mastodonHandle});
  final String actorUrl;
  final String? mastodonHandle;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _loading = false;
  String? _errorMessage;
  // Cached future so FutureBuilder doesn't restart on every rebuild.
  late Future<String?> _followStateFuture;

  @override
  void initState() {
    super.initState();
    _refreshFollowState();
  }

  void _refreshFollowState() {
    _followStateFuture =
        ref.read(socialGraphProvider.notifier).getFollowState(widget.actorUrl);
    debugPrint('[FollowButton] refreshing follow-state future for ${widget.actorUrl}');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _followStateFuture,
      builder: (context, snapshot) {
        debugPrint(
          '[FollowButton] FutureBuilder rebuild '
          'actorUrl=${widget.actorUrl} '
          'connState=${snapshot.connectionState} '
          'data=${snapshot.data} '
          'error=${snapshot.error} '
          '_loading=$_loading',
        );

        if (snapshot.hasError) {
          debugPrint('[FollowButton] followState future error for ${widget.actorUrl}: ${snapshot.error}\n${snapshot.stackTrace}');
          return FilledButton(onPressed: _follow, child: const Text('Follow'));
        }

        final followState = snapshot.data;

        if (followState == 'accepted') {
          return const OutlinedButton(onPressed: null, child: Text('Following'));
        }
        if (followState == 'pending' || followState == 'pending_delivery') {
          return const OutlinedButton(onPressed: null, child: Text('Requested'));
        }

        final button = FilledButton(
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

        if (_errorMessage != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              button,
              const SizedBox(height: 4),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          );
        }
        return button;
      },
    );
  }

  Future<void> _follow() async {
    debugPrint('[FollowButton] _follow() called for ${widget.actorUrl}');
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final result = await ref.read(socialGraphProvider.notifier).followActor(widget.actorUrl, mastodonHandle: widget.mastodonHandle);
      debugPrint('[FollowButton] followActor() → ${result.runtimeType} for ${widget.actorUrl}');
      if (!mounted) return;
      if (result is NotANightingalePeer) {
        setState(() {
          _loading = false;
          _errorMessage = "This account isn't on Nightingale and can't share music with you.";
          _refreshFollowState();
        });
        return;
      }
    } catch (e, st) {
      debugPrint('[FollowButton] followActor() threw for ${widget.actorUrl}: $e\n$st');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Follow failed. Check logs for details.';
          _refreshFollowState();
        });
        return;
      }
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _refreshFollowState();
      });
    }
  }
}
