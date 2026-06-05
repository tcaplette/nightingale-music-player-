import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

/// Persists crash entries to disk so they survive a process kill.
///
/// On the next launch call [reportAndClear] to dump any saved crash to the
/// console before the new session starts.
class CrashLogService {
  CrashLogService._();

  static File? _file;

  static Future<File> _logFile() async {
    if (_file != null) return _file!;
    final dir = await getApplicationSupportDirectory();
    _file = File('${dir.path}/nightingale_crash.log');
    return _file!;
  }

  /// Write a crash entry to disk synchronously where possible, async elsewhere.
  /// Sync write avoids losing the entry if the process dies immediately after.
  static void write(String label, Object error, StackTrace? stack) {
    final entry = _format(label, error, stack);
    try {
      // Synchronous write so we don't lose it in a race with process death.
      if (_file != null) {
        _file!.writeAsStringSync(entry, mode: FileMode.append, flush: true);
        return;
      }
    } catch (_) {}
    // Fallback: async path for the first write (before _file is cached).
    _writeAsync(entry);
  }

  static Future<void> _writeAsync(String entry) async {
    try {
      final f = await _logFile();
      await f.writeAsString(entry, mode: FileMode.append, flush: true);
    } catch (e) {
      // ignore: avoid_print
      print('CrashLogService: could not write crash log: $e');
    }
  }

  /// Call on startup: prints any crash log from the previous session then
  /// deletes the file so it doesn't repeat on subsequent launches.
  static Future<void> reportAndClear() async {
    try {
      final f = await _logFile();
      if (!f.existsSync()) return;
      final contents = f.readAsStringSync();
      if (contents.isEmpty) {
        f.deleteSync();
        return;
      }
      // Prime the file cache so subsequent sync writes work immediately.
      _file = f;

      const banner = '╔══════════════════════════════════════════════════════╗\n'
          '║        CRASH LOG FROM PREVIOUS SESSION               ║\n'
          '╚══════════════════════════════════════════════════════╝';
      // ignore: avoid_print
      print('\n$banner\n$contents\n════════════════════════════════════════════\n');
      developer.log(
        'Previous session crash log:\n$contents',
        name: 'nightingale.crash',
        level: 1200,
      );
      f.deleteSync();
    } catch (e) {
      // ignore: avoid_print
      print('CrashLogService: could not read crash log: $e');
    }
  }

  /// Attach an error listener to the current isolate. Errors that propagate to
  /// the isolate boundary and would kill it are captured here, written to disk,
  /// then re-thrown so the system can still generate its tombstone.
  static void attachIsolateListener() {
    final port = RawReceivePort((dynamic msg) {
      if (msg is List && msg.length == 2) {
        final error = msg[0];
        final stackString = msg[1] as String?;
        final stack =
            stackString != null ? StackTrace.fromString(stackString) : null;
        _isolateCrash(error, stack);
      }
    });
    Isolate.current.addErrorListener(port.sendPort);
  }

  static void _isolateCrash(Object error, StackTrace? stack) {
    final entry = _format('Isolate.addErrorListener', error, stack);
    // ignore: avoid_print
    print('\n$entry');
    developer.log(
      'Isolate error\n$error',
      name: 'nightingale.crash',
      error: error,
      stackTrace: stack,
      level: 1200,
    );
    // Write synchronously — the isolate may be dying.
    try {
      if (_file != null) {
        _file!.writeAsStringSync(entry, mode: FileMode.append, flush: true);
      }
    } catch (_) {}
  }

  static String _format(String label, Object error, StackTrace? stack) {
    final ts = DateTime.now().toIso8601String();
    return '[$ts] $label\n$error\n${stack ?? ''}\n---\n';
  }
}
