import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/publishing/listen_activity_publisher.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Settings screen with federation options.
class FederationSettingsScreen extends StatefulWidget {
  const FederationSettingsScreen({super.key});

  @override
  State<FederationSettingsScreen> createState() => _FederationSettingsScreenState();
}

class _FederationSettingsScreenState extends State<FederationSettingsScreen> {
  final _listenPublisher = sl<ListenActivityPublisher>();
  bool _listenEnabled = false;

  @override
  void initState() {
    super.initState();
    _listenEnabled = _listenPublisher.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Federation Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
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
          _section('Privacy', [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Library Sharing'),
              subtitle: const Text('Control who can see your library'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pushNamed('/sharing-settings');
              },
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
