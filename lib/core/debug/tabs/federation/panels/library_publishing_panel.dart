import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Debug panel showing library publishing status and privacy settings.
class LibraryPublishingPanel extends StatelessWidget {
  const LibraryPublishingPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final publisher = sl<LibraryPublisher>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _section('Sharing Scope', [
          _row('Current', publisher.sharingScope.name),
          _actionRow(
            'Set Private',
            () => publisher.setSharingScope(SharingScope.private),
          ),
          _actionRow(
            'Set Followers-Only',
            () => publisher.setSharingScope(SharingScope.followersOnly),
          ),
          _actionRow(
            'Set Public',
            () => publisher.setSharingScope(SharingScope.public),
          ),
        ]),
        const Divider(),
        _section('Collection Info', [
          _row('Actor URL', 'See federation tab'),
          _row('Endpoint', '/users/<username>/library'),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: AppSpacing.sm),
        ...children,
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _row(String key, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(key, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 10)),
        ),
      ],
    ),
  );

  Widget _actionRow(String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox(width: 110),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    ),
  );
}
