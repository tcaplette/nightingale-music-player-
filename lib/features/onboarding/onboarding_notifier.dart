import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';

sealed class OnboardingState {}

class OnboardingChecking extends OnboardingState {}

/// Onboarding has been completed by the user.
class OnboardingComplete extends OnboardingState {}

/// First-launch: the user must go through the onboarding flow.
class OnboardingRequired extends OnboardingState {}

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    _check();
    return OnboardingChecking();
  }

  Future<void> _check() async {
    final storage = sl<SecureStorageService>();
    final done = await storage.getOnboardingComplete();
    state = done ? OnboardingComplete() : OnboardingRequired();
  }

  Future<void> completeOnboarding() async {
    final storage = sl<SecureStorageService>();
    await storage.setOnboardingComplete(true);
    state = OnboardingComplete();
  }

  Future<void> signOut() async {
    final storage = sl<SecureStorageService>();
    await storage.setOnboardingComplete(false);
    state = OnboardingRequired();
  }
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingState>(
  OnboardingNotifier.new,
);
