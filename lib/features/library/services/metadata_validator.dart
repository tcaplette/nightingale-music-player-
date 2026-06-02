import 'package:nightingale/features/library/models/track_model.dart';

sealed class MetadataValidationResult {
  const MetadataValidationResult();
}

class MetadataComplete extends MetadataValidationResult {
  const MetadataComplete();
}

class MetadataIncomplete extends MetadataValidationResult {
  const MetadataIncomplete(this.missingFields);
  final List<String> missingFields;
}

class MetadataIncompleteException implements Exception {
  const MetadataIncompleteException(this.missingFields);
  final List<String> missingFields;

  @override
  String toString() =>
      'MetadataIncompleteException: missing ${missingFields.join(', ')}';
}

class MetadataValidator {
  const MetadataValidator();

  static const List<String> requiredFields = [
    'title',
    'artist',
    'album',
    'genre',
    'releaseYear',
  ];

  MetadataValidationResult validate(TrackModel track) {
    final missing = <String>[];

    if (_isEmpty(track.title)) missing.add('title');
    if (_isEmpty(track.artist)) missing.add('artist');
    // albumName may be null if the query didn't join; fall back to albumId
    if (_isEmpty(track.albumName) && track.albumId == null) missing.add('album');
    if (_isEmpty(track.genre)) missing.add('genre');
    if (track.releaseYear == null) missing.add('releaseYear');

    if (missing.isEmpty) return const MetadataComplete();
    return MetadataIncomplete(missing);
  }

  bool _isEmpty(String? value) => value == null || value.trim().isEmpty;
}
