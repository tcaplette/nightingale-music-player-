import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/onboarding/secure_storage_service.dart';

/// Provides the stored Mastodon handle, or null if none has been saved.
///
/// Invalidate this provider after calling [SecureStorageService.setMastodonHandle]
/// to reflect the updated value in all consumers.
final mastodonAccountProvider = FutureProvider<String?>((ref) async {
  return sl<SecureStorageService>().getMastodonHandle();
});
