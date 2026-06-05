import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/router/app_router.dart';
import 'package:nightingale/features/federation/publishing/listen_activity_publisher.dart';
import 'package:nightingale/features/federation/serving/relay_handler.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/features/recommendations/data/cold_start_settings_repository.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Settings screen with federation options.
class FederationSettingsScreen extends StatefulWidget {
  const FederationSettingsScreen({super.key});

  @override
  State<FederationSettingsScreen> createState() => _FederationSettingsScreenState();
}

class _FederationSettingsScreenState extends State<FederationSettingsScreen> {
  final _listenPublisher = sl<ListenActivityPublisher>();
  final _coldStartSettings = sl<ColdStartSettingsRepository>();
  final _settingsRepo = sl<SettingsRepository>();

  bool _listenEnabled = false;
  bool _discoveryEnabled = true;
  bool _globalTrendingEnabled = false;
  bool _relayEnabled = false;
  String? _actorUrl;
  String? _publicAddress;

  @override
  void initState() {
    super.initState();
    _listenEnabled = _listenPublisher.isEnabled;
    _loadColdStartPrefs();
    _loadIdentity();
    _loadRelayPref();
  }

  Future<void> _loadRelayPref() async {
    final enabled = await _settingsRepo.isRelayModeEnabled();
    if (mounted) setState(() => _relayEnabled = enabled);
  }

  Future<void> _loadColdStartPrefs() async {
    final discovery = await _coldStartSettings.isDiscoveryEnabled();
    final trending = await _coldStartSettings.isGlobalTrendingEnabled();
    if (mounted) {
      setState(() {
        _discoveryEnabled = discovery;
        _globalTrendingEnabled = trending;
      });
    }
  }

  Future<void> _loadIdentity() async {
    final repo = sl<NodeIdentityRepository>();
    final actorUrl = await repo.getActorUrl();
    final publicAddress = await repo.getPublicAddress();
    if (mounted) {
      setState(() {
        _actorUrl = actorUrl;
        _publicAddress = publicAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Federation Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _section('Your Node Identity', [
            _IdentityRow(
              label: 'Actor URL',
              value: _actorUrl ?? 'Loading…',
              hint: 'Share this with others so they can follow your music library.',
            ),
            _IdentityRow(
              label: 'Public Address',
              value: _publicAddress ?? 'Not yet resolved — open the app on mobile data to publish.',
              hint: 'Your device\'s current public IP:port. Updated automatically.',
            ),
          ]),
          const Divider(),
          _section('Listening Activities', [
            SwitchListTile(
              title: const Text('Share listening activity'),
              subtitle: const Text(
                'Publish what you listen to so your followers can discover music. '
                'You can turn this off at any time.',
                style: TextStyle(fontSize: 12),
              ),
              value: _listenEnabled,
              onChanged: (value) {
                setState(() => _listenEnabled = value);
                _listenPublisher.setEnabled(value);
              },
            ),
          ]),
          const Divider(),
          _section('Discovery', [
            SwitchListTile(
              title: const Text('Node discovery'),
              subtitle: const Text(
                'Allow Nightingale to query a public list of active nodes '
                'to help you find people to follow. No personal data is sent.',
                style: TextStyle(fontSize: 12),
              ),
              value: _discoveryEnabled,
              onChanged: (value) {
                setState(() => _discoveryEnabled = value);
                _coldStartSettings.setDiscoveryEnabled(value);
              },
            ),
            SwitchListTile(
              title: const Text('Global trending'),
              subtitle: const Text(
                'Show tracks trending across the wider network, sourced from '
                'a community relay. Off by default — enables a broader but '
                'less personal view of what\'s popular.',
                style: TextStyle(fontSize: 12),
              ),
              value: _globalTrendingEnabled,
              onChanged: (value) {
                setState(() => _globalTrendingEnabled = value);
                _coldStartSettings.setGlobalTrendingEnabled(value);
              },
            ),
          ]),
          const Divider(),
          _section('Relay', [
            SwitchListTile(
              title: const Text('Volunteer as relay node'),
              subtitle: const Text(
                'Allow other Nightingale users to stream through your device '
                'when they cannot connect directly. Uses your bandwidth. Off by default.',
                style: TextStyle(fontSize: 12),
              ),
              value: _relayEnabled,
              onChanged: (value) async {
                setState(() => _relayEnabled = value);
                await _settingsRepo.setRelayModeEnabled(value);
                if (value) {
                  await sl<RelayServer>().start();
                } else {
                  await sl<RelayServer>().stop();
                }
              },
            ),
          ]),
          const Divider(),
          _section('Privacy', [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Library Sharing'),
              subtitle: const Text('Control who can see your library'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.settingsSharing),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(letterSpacing: 1.0),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...children,
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

class _IdentityRow extends StatelessWidget {
  const _IdentityRow({
    required this.label,
    required this.value,
    required this.hint,
  });

  final String label;
  final String value;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label, style: theme.textTheme.labelMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(hint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.copy, size: 18),
        tooltip: 'Copy',
        onPressed: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 2)),
          );
        },
      ),
      isThreeLine: true,
    );
  }
}
