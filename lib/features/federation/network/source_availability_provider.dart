import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/network/network_binding_service.dart';
import 'package:nightingale/features/federation/network/source_availability_status.dart';

/// Exposes the current [SourceAvailabilityStatus] from [NetworkBindingService].
///
/// Emits the service's current status immediately, then updates on every call
/// to [NetworkBindingService.evaluateAndBind].
final sourceAvailabilityProvider =
    StreamProvider<SourceAvailabilityStatus>((ref) async* {
  final service = sl<NetworkBindingService>();
  yield service.currentStatus;
  yield* service.statusStream;
});
