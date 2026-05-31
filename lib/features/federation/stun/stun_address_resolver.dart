import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:nightingale/core/logging/app_logger.dart';

const _tag = 'stun';

// STUN message type: Binding Request (RFC 5389 §6).
const _bindingRequest = 0x0001;
const _bindingResponse = 0x0101;

// STUN attribute types relevant to us.
const _attrMappedAddress = 0x0001;
const _attrXorMappedAddress = 0x0020;

// Magic cookie (fixed value in RFC 5389).
const _magicCookie = 0x2112A442;

/// Performs a STUN Binding Request to discover the device's public IP:port.
///
/// Returns a string like "203.0.113.5:7777" on success, null on failure or
/// timeout. Never throws — all errors result in a null return.
class StunAddressResolver {
  StunAddressResolver({
    required this.stunServer,
    this.timeout = const Duration(seconds: 5),
  });

  final String stunServer;
  final Duration timeout;

  Future<String?> resolve() async {
    try {
      return await _doResolve().timeout(timeout);
    } catch (e) {
      AppLogger.debug('STUN resolve failed: $e', tag: _tag);
      return null;
    }
  }

  Future<String?> _doResolve() async {
    // Parse host:port from stunServer string.
    final parts = stunServer.split(':');
    final host = parts[0];
    final port = parts.length > 1 ? int.tryParse(parts[1]) ?? 3478 : 3478;

    // Resolve host to an IP address.
    final addresses = await InternetAddress.lookup(host);
    if (addresses.isEmpty) return null;
    final serverAddr = addresses.first;

    // Build STUN Binding Request message.
    final transactionId = _randomTransactionId();
    final request = _buildBindingRequest(transactionId);

    // Send via UDP.
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      socket.send(request, serverAddr, port);

      // Wait for response.
      await for (final event in socket) {
        if (event != RawSocketEvent.read) continue;
        final datagram = socket.receive();
        if (datagram == null) continue;

        final result = _parseResponse(datagram.data, transactionId);
        if (result != null) return result;
      }
      return null;
    } finally {
      socket.close();
    }
  }

  Uint8List _buildBindingRequest(Uint8List transactionId) {
    // STUN header: type(2) + length(2) + magic(4) + txnId(12) = 20 bytes.
    final buf = ByteData(20);
    buf.setUint16(0, _bindingRequest);
    buf.setUint16(2, 0); // message length (no attributes)
    buf.setUint32(4, _magicCookie);
    final bytes = buf.buffer.asUint8List();
    // Copy transaction ID into bytes 8–19.
    for (var i = 0; i < 12; i++) {
      bytes[8 + i] = transactionId[i];
    }
    return bytes;
  }

  String? _parseResponse(Uint8List data, Uint8List transactionId) {
    if (data.length < 20) return null;

    final view = ByteData.sublistView(data);
    final msgType = view.getUint16(0);
    if (msgType != _bindingResponse) return null;

    final msgLength = view.getUint16(2);
    if (data.length < 20 + msgLength) return null;

    // Verify transaction ID.
    for (var i = 0; i < 12; i++) {
      if (data[8 + i] != transactionId[i]) return null;
    }

    // Parse attributes.
    var offset = 20;
    while (offset < 20 + msgLength) {
      if (offset + 4 > data.length) break;
      final attrType = view.getUint16(offset);
      final attrLen = view.getUint16(offset + 2);
      offset += 4;

      if (attrType == _attrXorMappedAddress) {
        final result = _parseXorMappedAddress(data, offset, attrLen);
        if (result != null) return result;
      } else if (attrType == _attrMappedAddress) {
        final result = _parseMappedAddress(data, offset, attrLen);
        if (result != null) return result;
      }

      // Attributes are padded to 4-byte boundaries.
      offset += (attrLen + 3) & ~3;
    }

    return null;
  }

  String? _parseXorMappedAddress(Uint8List data, int offset, int len) {
    if (len < 8) return null;
    final view = ByteData.sublistView(data);
    // offset+0: reserved, offset+1: family, offset+2: x-port, offset+4: x-addr
    final family = view.getUint8(offset + 1);
    if (family != 0x01) return null; // IPv4 only

    final xPort = view.getUint16(offset + 2);
    final xAddr = view.getUint32(offset + 4);

    final port = xPort ^ (_magicCookie >> 16);
    final addr = xAddr ^ _magicCookie;

    final ip = _uint32ToIp(addr);
    return '$ip:$port';
  }

  String? _parseMappedAddress(Uint8List data, int offset, int len) {
    if (len < 8) return null;
    final view = ByteData.sublistView(data);
    final family = view.getUint8(offset + 1);
    if (family != 0x01) return null;

    final port = view.getUint16(offset + 2);
    final addr = view.getUint32(offset + 4);

    final ip = _uint32ToIp(addr);
    return '$ip:$port';
  }

  String _uint32ToIp(int addr) {
    final a = (addr >> 24) & 0xFF;
    final b = (addr >> 16) & 0xFF;
    final c = (addr >> 8) & 0xFF;
    final d = addr & 0xFF;
    return '$a.$b.$c.$d';
  }

  Uint8List _randomTransactionId() {
    final rng = Random.secure();
    return Uint8List.fromList(List.generate(12, (_) => rng.nextInt(256)));
  }
}
