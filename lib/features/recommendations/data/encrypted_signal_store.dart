import 'package:nightingale/features/recommendations/data/taste_profile_key_store.dart';
import 'package:nightingale/features/recommendations/domain/signal_event.dart';

/// Encrypts/decrypts sensitive fields (trackFingerprint, sourceActorId)
/// before they touch Drift storage.
///
/// All scoring is done in memory after decryption — encrypted fingerprints
/// cannot be matched in SQL, so callers must load-all then filter.
class EncryptedSignalStore {
  const EncryptedSignalStore(this._keyStore);

  final TasteProfileKeyStore _keyStore;

  Future<String> encryptFingerprint(String fingerprint) =>
      _keyStore.encrypt(fingerprint);

  Future<String> decryptFingerprint(String encrypted) =>
      _keyStore.decrypt(encrypted);

  Future<String?> encryptActorId(String? actorId) async {
    if (actorId == null) return null;
    return _keyStore.encrypt(actorId);
  }

  Future<String?> decryptActorId(String? encrypted) async {
    if (encrypted == null) return null;
    return _keyStore.decrypt(encrypted);
  }

  Future<({String fingerprint, String? actorId})> encryptFields({
    required String fingerprint,
    String? actorId,
  }) async {
    return (
      fingerprint: await encryptFingerprint(fingerprint),
      actorId: await encryptActorId(actorId),
    );
  }

  Future<SignalEvent> decryptEvent({
    required String encryptedFingerprint,
    required String eventTypeStr,
    required String? encryptedActorId,
    required int timestampUtcMs,
    required double weight,
  }) async {
    final fingerprint = await decryptFingerprint(encryptedFingerprint);
    final actorId = await decryptActorId(encryptedActorId);
    return SignalEvent(
      trackFingerprint: fingerprint,
      eventType: SignalEventType.fromString(eventTypeStr),
      sourceActorId: actorId,
      timestampUtc: DateTime.fromMillisecondsSinceEpoch(
        timestampUtcMs,
        isUtc: true,
      ),
      weight: weight,
    );
  }
}
