import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nightingale/core/activitypub/models/ap_activity.dart';
import 'package:nightingale/core/audio/playback_state_model.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/federation/delivery/activity_delivery_service.dart';
import 'package:nightingale/features/federation/social/social_subscribing_service.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';

const _tag = 'listen_activity';

/// Observes playback state and publishes Listen activities to the network.
class ListenActivityPublisher {
  ListenActivityPublisher({
    required NodeIdentityRepository identityRepo,
    required ActivityDeliveryService delivery,
    required SocialSubscribingService social,
    required SettingsRepository settings,
  })  : _identityRepo = identityRepo,
        _delivery = delivery,
        _social = social,
        _settings = settings;

  final NodeIdentityRepository _identityRepo;
  final ActivityDeliveryService _delivery;
  final SocialSubscribingService _social;
  final SettingsRepository _settings;

  bool _enabled = false;

  bool get isEnabled => _enabled;

  Future<void> init() async {
    _enabled = await _settings.isListenActivityEnabled();
  }

  void setEnabled(bool value) {
    _enabled = value;
    _settings.setListenActivityEnabled(value).ignore();
    AppLogger.info('Listen activity publishing ${value ? 'enabled' : 'disabled'}', tag: _tag);
  }

  /// Starts observing the playback engine's state.
  void startObserving(ValueNotifier<PlaybackStateModel> stateNotifier) {
    _stateNotifier = stateNotifier;
    void listener() => _onPlaybackStateChanged(stateNotifier.value);
    stateNotifier.addListener(listener);
    _removeListener = listener;
  }

  VoidCallback? _removeListener;
  ValueNotifier<PlaybackStateModel>? _stateNotifier;

  void stopObserving() {
    if (_removeListener != null && _stateNotifier != null) {
      _stateNotifier!.removeListener(_removeListener!);
      _removeListener = null;
      _stateNotifier = null;
    }
  }

  DateTime? _lastPublishedTrackStart;
  String? _lastPublishedTrackId;

  void _onPlaybackStateChanged(PlaybackStateModel state) {
    if (!_enabled) return;
    if (state.status != PlaybackStatus.playing) return;
    if (state.currentTrack == null) return;

    final track = state.currentTrack!;
    final now = DateTime.now();

    // Debounce: only publish once per track start (not on every state update)
    if (_lastPublishedTrackId == track.id.toString() &&
        _lastPublishedTrackStart != null &&
        now.difference(_lastPublishedTrackStart!).inSeconds < 5) {
      return;
    }

    _lastPublishedTrackId = track.id.toString();
    _lastPublishedTrackStart = now;

    _publishListen(track);
  }

  Future<void> _publishListen(TrackModel track) async {
    try {
      final actorUrl = await _identityRepo.getActorUrl();
      final activity = ApListen(
        id: '$actorUrl/listen/${DateTime.now().millisecondsSinceEpoch}',
        actor: actorUrl,
        object: {
          'type': 'Audio',
          'id': track.sourceActorUrl != null
              ? '${track.sourceActorUrl}/tracks/${track.id}'
              : '$actorUrl/tracks/${track.id}',
          'name': track.title,
          'artist': track.artist,
        },
        published: DateTime.now(),
      );

      // Deliver to all followers' inboxes
      final followers = await _social.getFollowers();
      for (final follower in followers) {
        // Resolve follower to get inbox
        final result = await sl<ActorResolver>().resolve(follower.actorUrl);
        if (result is ResolveOk && result.actor.inbox != null) {
          await _delivery.deliver(activity, result.actor.inbox!);
        }
      }

      AppLogger.info('Published Listen activity for ${track.title} to ${followers.length} followers', tag: _tag);
    } catch (e) {
      AppLogger.error('Failed to publish Listen activity', tag: _tag, error: e);
    }
  }
}
