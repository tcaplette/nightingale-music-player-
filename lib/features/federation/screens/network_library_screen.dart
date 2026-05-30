import 'package:flutter/material.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/library/remote_library_fetcher.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Network tab for browsing followed actors' libraries.
class NetworkLibraryScreen extends StatefulWidget {
  const NetworkLibraryScreen({super.key});

  @override
  State<NetworkLibraryScreen> createState() => _NetworkLibraryScreenState();
}

class _NetworkLibraryScreenState extends State<NetworkLibraryScreen> {
  final _social = sl<SocialSubscribingService>();
  final _fetcher = sl<RemoteLibraryFetcher>();
  List<FollowingTableData> _following = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    try {
      setState(() => _isLoading = true);
      final following = await _social.getFollowing();
      setState(() {
        _following = following;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLibrary(String actorUrl) async {
    try {
      setState(() => _isLoading = true);
      final tracks = await _fetcher.fetchLibrary(actorUrl);
      if (mounted) {
        if (tracks != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _RemoteLibraryView(
                actorUrl: actorUrl,
                tracks: tracks,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Library is private or not accessible')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch library: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFollowing,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFollowing,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_following.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'Not following anyone yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: _following.length,
      itemBuilder: (context, index) {
        final actor = _following[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(actor.actorUrl.split('/').last),
          subtitle: Text(actor.actorUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _fetchLibrary(actor.actorUrl),
        );
      },
    );
  }
}

class _RemoteLibraryView extends StatelessWidget {
  const _RemoteLibraryView({
    required this.actorUrl,
    required this.tracks,
  });

  final String actorUrl;
  final List<TrackModel> tracks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(actorUrl.split('/').last),
      ),
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return ListTile(
            leading: const Icon(Icons.music_note),
            title: Text(track.title),
            subtitle: Text(track.artist),
            trailing: track.isReachable
                ? const Icon(Icons.play_arrow)
                : const Icon(Icons.cloud_off, color: Colors.grey),
            onTap: () {
              // TODO: Play remote track
            },
          );
        },
      ),
    );
  }
}
