import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';

sealed class NodeIdentityState {}

class NodeIdentityLoading extends NodeIdentityState {}

class NodeIdentityReady extends NodeIdentityState {
  NodeIdentityReady(this.actorUrl);
  final String actorUrl;
}

class NodeIdentityMissing extends NodeIdentityState {}

class NodeIdentityNotifier extends Notifier<NodeIdentityState> {
  @override
  NodeIdentityState build() {
    _check();
    return NodeIdentityLoading();
  }

  Future<void> _check() async {
    final repo = sl<NodeIdentityRepository>();
    final has = await repo.hasIdentity();
    if (has) {
      final url = await repo.getActorUrl();
      state = NodeIdentityReady(url);
    } else {
      state = NodeIdentityMissing();
    }
  }

  Future<void> createIdentity({required String displayName}) async {
    final repo = sl<NodeIdentityRepository>();
    await repo.generateIdentity(displayName: displayName);
    final url = await repo.getActorUrl();
    state = NodeIdentityReady(url);
  }
}

final nodeIdentityProvider =
    NotifierProvider<NodeIdentityNotifier, NodeIdentityState>(
  NodeIdentityNotifier.new,
);
