import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/node_identity/node_identity_notifier.dart';
import 'package:nightingale/features/onboarding/onboarding_notifier.dart';

/// Bridges Riverpod provider state changes into a [ChangeNotifier] so that
/// [GoRouter] re-evaluates its redirect whenever onboarding or identity state
/// changes asynchronously after startup.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(ProviderContainer container) {
    _onboardingSub = container.listen<OnboardingState>(
      onboardingProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
    _identitySub = container.listen<NodeIdentityState>(
      nodeIdentityProvider,
      (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }

  late final ProviderSubscription<OnboardingState> _onboardingSub;
  late final ProviderSubscription<NodeIdentityState> _identitySub;

  @override
  void dispose() {
    _onboardingSub.close();
    _identitySub.close();
    super.dispose();
  }
}
