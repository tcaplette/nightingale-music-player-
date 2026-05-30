import 'package:drift/drift.dart' show OrderingTerm, OrderingMode;
import 'package:flutter/material.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Social feed screen showing incoming Listen activities from followed nodes.
class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final _db = sl<AppDatabase>();
  List<ListenActivitiesTableData> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    try {
      setState(() => _isLoading = true);
      final activities = await (_db.select(_db.listenActivitiesTable)
            ..orderBy([(t) => OrderingTerm(expression: t.listenedAt, mode: OrderingMode.desc)])
            ..limit(50))
          .get();
      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivities,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activities.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              'No listening activity yet',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              'Follow people to see what they\'re listening to',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.headphones),
          ),
          title: Text(activity.trackTitle),
          subtitle: Text('${activity.trackArtist} • ${activity.actorUrl.split('/').last}'),
          trailing: Text(
            _formatTime(activity.listenedAt),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
