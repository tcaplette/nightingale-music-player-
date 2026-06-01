import 'package:flutter/material.dart';
import 'package:nightingale/features/federation/guards/metadata_gate_rejection_sheet.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/services/metadata_validator.dart';

class MetadataGate {
  const MetadataGate();

  static const _validator = MetadataValidator();

  /// Throws [MetadataIncompleteException] if the track is missing required fields.
  void check(TrackModel track) {
    final result = _validator.validate(track);
    if (result is MetadataIncomplete) {
      throw MetadataIncompleteException(result.missingFields);
    }
  }

  /// Returns true if the track passes all required metadata checks.
  bool passes(TrackModel track) {
    return _validator.validate(track) is MetadataComplete;
  }

  /// Runs [action] if the track passes validation; otherwise shows the
  /// rejection sheet. Use this from any UI that shares or federates a track.
  Future<void> guardShare({
    required BuildContext context,
    required TrackModel track,
    required Future<void> Function() action,
  }) async {
    final result = _validator.validate(track);
    if (result is MetadataIncomplete) {
      final error = MetadataIncompleteException(result.missingFields);
      if (context.mounted) {
        await showMetadataGateRejectionSheet(context, track, error);
      }
      return;
    }
    await action();
  }
}
