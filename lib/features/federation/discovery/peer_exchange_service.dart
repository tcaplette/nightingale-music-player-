import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nightingale/core/activitypub/models/ap_collection.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'peer_exchange';
const _collectionCap = 200;

/// Expands the local actor cache whenever the user follows someone new.
///
/// On follow, the newly followed actor's followers and following collections
/// are fetched (up to 200 items each) and every discovered actor URL is
/// resolved and cached. This means a single mDNS contact can propagate an
/// entire social graph to the device, making previously unknown nodes
/// discoverable without a central registry.
///
/// Jobs run sequentially at low priority (one at a time, with a small yield
/// between items) and never block the UI or foreground network activity.
/// Failures are discarded silently — peer exchange is best-effort.
class PeerExchangeService {
  PeerExchangeService({required ActorResolver actorResolver})
      : _actorResolver = actorResolver;

  final ActorResolver _actorResolver;
  final Queue<String> _queue = Queue();
  bool _processing = false;

  /// Enqueues a peer exchange job for [actorUrl].
  /// Returns immediately; processing happens in the background.
  void enqueue(String actorUrl) {
    _queue.add(actorUrl);
    _drain();
  }

  void _drain() {
    if (_processing) return;
    _processing = true;
    _processNext();
  }

  void _processNext() {
    if (_queue.isEmpty) {
      _processing = false;
      return;
    }
    final actorUrl = _queue.removeFirst();
    _exchange(actorUrl).then((_) => _processNext()).ignore();
  }

  Future<void> _exchange(String actorUrl) async {
    AppLogger.debug('Peer exchange start: $actorUrl', tag: _tag);
    try {
      // Resolve the target actor to get their collection URLs.
      final result = await _actorResolver.resolve(
        actorUrl,
        discoverySource: 'peerExchange',
      );
      if (result is! ResolveOk) return;
      final actor = result.actor;

      await _fetchCollection(actor.followers);
      await _fetchCollection(actor.following);
    } catch (e) {
      AppLogger.debug('Peer exchange failed for $actorUrl: $e', tag: _tag);
    }
  }

  Future<void> _fetchCollection(String collectionUrl) async {
    final items = await _collectItems(collectionUrl);
    for (final actorUrl in items) {
      // Yield between items so foreground work can interleave.
      await Future.delayed(Duration.zero);
      try {
        await _actorResolver.resolve(
          actorUrl,
          discoverySource: 'peerExchange',
        );
      } catch (_) {
        // Non-fatal — skip unresolvable actors.
      }
    }
    AppLogger.debug(
      'Peer exchange: cached ${items.length} actors from $collectionUrl',
      tag: _tag,
    );
  }

  /// Fetches up to [_collectionCap] actor URLs from an ActivityPub collection.
  Future<List<String>> _collectItems(String collectionUrl) async {
    final items = <String>[];
    try {
      final response = await http.get(
        Uri.parse(collectionUrl),
        headers: {'Accept': 'application/activity+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401 || response.statusCode == 403) return [];
      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final collection = ApOrderedCollection.fromJson(json);

      // Inline items (small collections).
      if (collection.orderedItems != null) {
        for (final item in collection.orderedItems!) {
          final url = _toActorUrl(item);
          if (url != null) items.add(url);
          if (items.length >= _collectionCap) return items;
        }
      }

      // First page of a paginated collection.
      if (items.length < _collectionCap && collection.first != null) {
        final pageResp = await http.get(
          Uri.parse(collection.first!),
          headers: {'Accept': 'application/activity+json'},
        ).timeout(const Duration(seconds: 10));

        if (pageResp.statusCode == 200) {
          final pageJson = jsonDecode(pageResp.body) as Map<String, dynamic>;
          final page = ApOrderedCollectionPage.fromJson(pageJson);
          for (final item in page.orderedItems) {
            final url = _toActorUrl(item);
            if (url != null) items.add(url);
            if (items.length >= _collectionCap) break;
          }
        }
      }
    } catch (e) {
      AppLogger.debug(
        'Peer exchange collection fetch failed ($collectionUrl): $e',
        tag: _tag,
      );
    }
    return items;
  }

  static String? _toActorUrl(dynamic item) {
    if (item is String) return item;
    if (item is Map) return item['id'] as String?;
    return null;
  }
}
