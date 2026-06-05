import 'dart:developer' as developer;

import 'package:nightingale/core/activitypub/models/ap_actor.dart';

class NightingaleActorValidator {
  const NightingaleActorValidator();

  bool isNightingalePeer(ApActor actor) {
    final hasPublicAddress = actor.nightingalePublicAddress != null;
    final isHttpUrl = actor.id.startsWith('http://');
    final result = hasPublicAddress || isHttpUrl;
    developer.log(
      'isNightingalePeer: ${actor.id} → $result '
      '[hasPublicAddress=$hasPublicAddress publicAddress=${actor.nightingalePublicAddress}, '
      'isHttpUrl=$isHttpUrl]',
      name: 'nightingale.validator',
    );
    return result;
  }
}
