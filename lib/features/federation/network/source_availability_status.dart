/// Availability of this device as a music source for federation peers.
enum SourceAvailabilityStatus {
  /// Discovery in progress.
  checking,

  /// Bound to a publicly routable interface — fully available as a source.
  available,

  /// Bound to a cellular interface because WiFi is behind NAT. Functional
  /// but may increase cellular data usage.
  availableViaCellular,

  /// No publicly routable interface found. Inbound serving is disabled.
  consumerOnly,
}
