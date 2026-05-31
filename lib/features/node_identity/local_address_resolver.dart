import 'dart:io';

/// Resolves the device's current LAN IPv4 address by inspecting active
/// network interfaces. Never returns loopback addresses. Returns null if
/// no suitable interface is found (no WiFi, emulator-only loopback, etc.).
class LocalAddressResolver {
  Future<String?> resolve() async {
    String? candidate;

    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLinkLocal: false,
    );

    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        final ip = addr.address;

        // Prefer WiFi (wlan0, en0, wlp*) over other interfaces.
        final name = iface.name.toLowerCase();
        final isWifi = name.startsWith('wlan') ||
            name.startsWith('en') ||
            name.startsWith('wlp') ||
            name.startsWith('wifi');

        if (isWifi) return ip;
        candidate ??= ip;
      }
    }

    return candidate;
  }
}
