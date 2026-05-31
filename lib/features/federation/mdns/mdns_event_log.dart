/// In-memory log of mDNS events for the debug panel.
class MdnsEventLog {
  static final MdnsEventLog instance = MdnsEventLog._();
  MdnsEventLog._();

  final List<String> events = [];

  void log(String message) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    events.add('[$ts] $message');
    if (events.length > 200) events.removeAt(0);
  }

  void clear() => events.clear();
}
