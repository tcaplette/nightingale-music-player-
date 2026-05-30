import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/shared/components/sheets/app_bottom_sheet.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Sharing settings screen for library federation privacy.
class SharingSettingsScreen extends StatefulWidget {
  const SharingSettingsScreen({super.key});

  @override
  State<SharingSettingsScreen> createState() => _SharingSettingsScreenState();
}

class _SharingSettingsScreenState extends State<SharingSettingsScreen> {
  final _publisher = sl<LibraryPublisher>();
  SharingScope _scope = SharingScope.private;

  @override
  void initState() {
    super.initState();
    _scope = _publisher.sharingScope;
  }

  void _setScope(SharingScope scope) {
    setState(() => _scope = scope);
    _publisher.setSharingScope(scope);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sharing Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _section('Library Visibility', [
            _radioTile(
              title: 'Private',
              subtitle: 'No one can see your library',
              value: SharingScope.private,
            ),
            _radioTile(
              title: 'Followers Only',
              subtitle: 'Only your followers can see your library',
              value: SharingScope.followersOnly,
            ),
            _radioTile(
              title: 'Public',
              subtitle: 'Anyone can see your library',
              value: SharingScope.public,
            ),
          ]),
          const Divider(),
          _section('What is shared?', [
            _infoRow('Track titles, artists, albums'),
            _infoRow('Stream URLs (with authentication)'),
            _infoRow('Artwork URLs'),
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

  Widget _radioTile({
    required String title,
    required String subtitle,
    required SharingScope value,
  }) {
    return RadioListTile<SharingScope>(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      groupValue: _scope,
      onChanged: (v) => v != null ? _setScope(v) : null,
      dense: true,
    );
  }

  Widget _infoRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

/// Shows sharing settings as a bottom sheet.
void showSharingSettings(BuildContext context) {
  showAppBottomSheet(
    context: context,
    child: const SharingSettingsScreen(),
  );
}
