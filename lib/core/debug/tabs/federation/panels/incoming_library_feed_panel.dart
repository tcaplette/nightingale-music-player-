import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Debug panel showing incoming listen activities from followed nodes.
class IncomingLibraryFeedPanel extends StatefulWidget {
  const IncomingLibraryFeedPanel({super.key});

  @override
  State<IncomingLibraryFeedPanel> createState() => _IncomingLibraryFeedPanelState();
}

class _IncomingLibraryFeedPanelState extends State<IncomingLibraryFeedPanel> {
  final _social = sl<SocialSubscribingService>();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _social.getFollowing(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final following = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _section('Following', [
              _row('Count', following.length.toString()),
              ...following.map((f) => _row('Actor', f.actorUrl)),
            ]),
            const Divider(),
            _section('Incoming Feed', [
              _row('Status', 'Listen activities from followed nodes appear here'),
            ]),
          ],
        );
      },
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
}
