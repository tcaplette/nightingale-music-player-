import 'dart:io';

/// Prepends a minimal valid ID3v2.3 header to [filePath] so that
/// metadata_god can read-modify-write it. Call this when writeMetadata
/// throws because the file has no existing tag container.
///
/// ID3v2.3 header layout (10 bytes):
///   "ID3"        — magic
///   0x03 0x00    — version 2.3, revision 0
///   0x00         — flags (none)
///   0x00×4       — tag size: 0 bytes (syncsafe integer)
Future<void> stampId3Header(String filePath) async {
  const header = [
    0x49, 0x44, 0x33, // "ID3"
    0x03, 0x00,       // v2.3.0
    0x00,             // flags
    0x00, 0x00, 0x00, 0x00, // size = 0
  ];

  final file = File(filePath);
  final existing = await file.readAsBytes();

  // Guard: don't stamp if the file already starts with "ID3"
  if (existing.length >= 3 &&
      existing[0] == 0x49 &&
      existing[1] == 0x44 &&
      existing[2] == 0x33) {
    return;
  }

  await file.writeAsBytes([...header, ...existing]);
}
