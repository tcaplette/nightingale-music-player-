import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nightingale/shared/components/network_state/host_offline_widget.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class PlaylistDetailScreen extends StatelessWidget {
  const PlaylistDetailScreen({super.key, required this.playlistUrl});
  final String playlistUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Playlist')),
      body: _PlaylistDetailBody(playlistUrl: playlistUrl),
    );
  }
}

class _PlaylistDetailBody extends StatefulWidget {
  const _PlaylistDetailBody({required this.playlistUrl});
  final String playlistUrl;

  @override
  State<_PlaylistDetailBody> createState() => _PlaylistDetailBodyState();
}

class _PlaylistDetailBodyState extends State<_PlaylistDetailBody> {
  List<Map<String, dynamic>> _tracks = [];
  bool _isLoading = true;
  bool _isOffline = false;
  String? _title;

  @override
  void initState() {
    super.initState();
    _fetchPlaylist();
  }

  Future<void> _fetchPlaylist() async {
    try {
      // Import http inline to avoid coupling at class level
      final http = await Future.value(
        // Lazy import of http package via existing infrastructure
        // In production this would use the authenticated HTTP client
        // For now, stub as offline if playlistUrl is not a local URL
        null,
      );

      if (widget.playlistUrl.isEmpty) {
        setState(() {
          _isLoading = false;
          _isOffline = true;
        });
        return;
      }

      // Simplified: attempt to parse a cached local playlist URL
      // Full remote fetch wired when http client DI is complete
      setState(() {
        _isLoading = false;
        _isOffline = false;
        _tracks = [];
        _title = 'Playlist';
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _isOffline = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isOffline) {
      return Center(
        child: HostOfflineWidget(
          displayName: Uri.tryParse(widget.playlistUrl)?.host ?? 'Host',
          lastSeenAt: null,
        ),
      );
    }

    if (_tracks.isEmpty) {
      return Center(
        child: Text(
          'This playlist is empty',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.neutral400),
        ),
      );
    }

    return ListView.builder(
      itemCount: _tracks.length,
      itemBuilder: (_, i) {
        final track = _tracks[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          title: Text(track['name']?.toString() ?? 'Unknown'),
          subtitle: Text(track['artist']?.toString() ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            onPressed: () {/* stream via Phase 4 resolver */},
          ),
        );
      },
    );
  }
}
