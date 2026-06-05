import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/network/source_availability_provider.dart';
import 'package:nightingale/features/federation/network/source_availability_status.dart';
import 'package:nightingale/features/federation/publishing/library_publisher.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/widgets/metadata_editor_sheet.dart';
import 'package:nightingale/features/library/widgets/track_tile.dart';
import 'package:nightingale/shared/components/sheets/app_bottom_sheet.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Sharing settings screen for library federation privacy.
class SharingSettingsScreen extends ConsumerStatefulWidget {
  const SharingSettingsScreen({super.key});

  @override
  ConsumerState<SharingSettingsScreen> createState() =>
      _SharingSettingsScreenState();
}

class _SharingSettingsScreenState
    extends ConsumerState<SharingSettingsScreen> {
  final _publisher = sl<LibraryPublisher>();
  SharingScope _scope = SharingScope.private;
  List<TrackModel> _incompleteTracks = [];
  bool _loadingIncomplete = false;

  @override
  void initState() {
    super.initState();
    _scope = _publisher.sharingScope;
    if (_scope != SharingScope.private) _loadIncomplete();
  }

  Future<void> _setScope(SharingScope scope) async {
    setState(() => _scope = scope);
    _publisher.setSharingScope(scope);
    if (scope != SharingScope.private) {
      await _loadIncomplete();
    } else {
      setState(() => _incompleteTracks = []);
    }
  }

  Future<void> _loadIncomplete() async {
    setState(() => _loadingIncomplete = true);
    final tracks = await _publisher.getIncompleteSharedTracks();
    if (mounted) {
      setState(() {
        _incompleteTracks = tracks;
        _loadingIncomplete = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sharing Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _sourceAvailabilityBanner(),
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
          if (_scope != SharingScope.private) ...[
            const Divider(),
            _incompleteSection(),
          ],
        ],
      ),
    );
  }

  Widget _sourceAvailabilityBanner() {
    final status = ref
        .watch(sourceAvailabilityProvider)
        .valueOrNull;

    if (status == SourceAvailabilityStatus.consumerOnly) {
      return _statusBanner(
        icon: Icons.signal_wifi_off,
        message:
            'Your library is not reachable. Connect to mobile data to share your music.',
        color: Colors.orange,
      );
    }
    if (status == SourceAvailabilityStatus.availableViaCellular) {
      return _statusBanner(
        icon: Icons.signal_cellular_alt,
        message:
            'Sharing via mobile data — WiFi does not allow incoming connections.',
        color: Colors.blue,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _statusBanner({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 13, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _incompleteSection() {
    if (_loadingIncomplete) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_incompleteTracks.isEmpty) {
      return _section('Metadata Status', [
        _infoRow('All shared tracks have complete metadata'),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metadata Status',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B30)),
          title: Text(
            '${_incompleteTracks.length} track${_incompleteTracks.length == 1 ? '' : 's'} excluded',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          subtitle: const Text(
            'Tap to view and fix incomplete metadata',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showIncompleteTracksList(context),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  void _showIncompleteTracksList(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Tracks with incomplete metadata',
                    style: Theme.of(ctx).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Long-press any track to edit its metadata.',
                    style: Theme.of(ctx).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _incompleteTracks.length,
                itemBuilder: (ctx, i) {
                  final track = _incompleteTracks[i];
                  return TrackTile(
                    track: track,
                    onTap: () {},
                    onLongPress: () {
                      showMetadataEditorSheet(ctx, track);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            letterSpacing: 1.0,
          ),
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
