import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';

class FederatedRadioState {
  const FederatedRadioState({
    required this.enabled,
    this.playedFingerprints = const {},
    this.seedArtist,
  });

  final bool enabled;
  final Set<String> playedFingerprints;
  final String? seedArtist;

  FederatedRadioState copyWith({
    bool? enabled,
    Set<String>? playedFingerprints,
    String? seedArtist,
    bool clearSeed = false,
  }) {
    return FederatedRadioState(
      enabled: enabled ?? this.enabled,
      playedFingerprints: playedFingerprints ?? this.playedFingerprints,
      seedArtist: clearSeed ? null : (seedArtist ?? this.seedArtist),
    );
  }
}

class FederatedRadioNotifier extends AsyncNotifier<FederatedRadioState> {
  @override
  Future<FederatedRadioState> build() async {
    final enabled = await sl<SettingsRepository>().getFederatedRadioEnabled();
    return FederatedRadioState(enabled: enabled);
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? const FederatedRadioState(enabled: false);
    final newEnabled = !current.enabled;
    await sl<SettingsRepository>().setFederatedRadioEnabled(newEnabled);
    state = AsyncData(
      newEnabled
          ? current.copyWith(enabled: true)
          : const FederatedRadioState(enabled: false),
    );
  }

  Future<void> startSeeded(String artistName) async {
    await sl<SettingsRepository>().setFederatedRadioEnabled(true);
    final current = state.valueOrNull ?? const FederatedRadioState(enabled: false);
    state = AsyncData(FederatedRadioState(
      enabled: true,
      playedFingerprints: current.playedFingerprints,
      seedArtist: artistName,
    ));
  }

  void markPlayed(String fingerprint) {
    final current = state.valueOrNull;
    if (current == null || !current.enabled) return;
    state = AsyncData(current.copyWith(
      playedFingerprints: {...current.playedFingerprints, fingerprint},
    ));
  }
}

final federatedRadioProvider =
    AsyncNotifierProvider<FederatedRadioNotifier, FederatedRadioState>(
  FederatedRadioNotifier.new,
);
