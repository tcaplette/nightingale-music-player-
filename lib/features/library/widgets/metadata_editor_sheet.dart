import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart' as mg;
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/database/tables/albums_table.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/features/library/models/track_model.dart';
import 'package:nightingale/features/library/services/metadata_lookup_service.dart';
import 'package:nightingale/features/library/services/metadata_validator.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';
import 'package:permission_handler/permission_handler.dart';

const _tag = 'metadata_editor';
const _lookup = MetadataLookupService();

void showMetadataEditorSheet(BuildContext context, TrackModel track) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _MetadataEditorSheet(track: track),
  );
}

class _MetadataEditorSheet extends StatefulWidget {
  const _MetadataEditorSheet({required this.track});
  final TrackModel track;

  @override
  State<_MetadataEditorSheet> createState() => _MetadataEditorSheetState();
}

class _MetadataEditorSheetState extends State<_MetadataEditorSheet> {
  static const _validator = MetadataValidator();

  late final Map<String, TextEditingController> _controllers;
  bool _saving = false;
  bool _populating = false;
  String? _errorMessage;
  MetadataLookupResult? _lookupResult;
  String? _pendingArtworkUrl;  // URL to download on save
  String? _previewArtworkPath; // local path of downloaded preview

  static const _fieldLabels = {
    'title': 'Title',
    'artist': 'Artist',
    'album': 'Album',
    'albumArtist': 'Album Artist',
    'genre': 'Genre',
    'releaseYear': 'Release Year',
  };

  @override
  void initState() {
    super.initState();
    _controllers = {
      'title': TextEditingController(text: widget.track.title),
      'artist': TextEditingController(text: widget.track.artist),
      'album': TextEditingController(text: widget.track.albumName ?? ''),
      'albumArtist': TextEditingController(
        text: widget.track.albumArtist ?? '',
      ),
      'genre': TextEditingController(text: widget.track.genre ?? ''),
      'releaseYear': TextEditingController(
        text: widget.track.releaseYear?.toString() ?? '',
      ),
    };
    if (widget.track.albumName == null && widget.track.albumId != null) {
      sl<AppDatabase>()
          .albumDao
          .getAlbumById(widget.track.albumId!)
          .then((album) {
        if (mounted && album != null) {
          _controllers['album']!.text = album.name;
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _missingFields {
    final result = _validator.validate(widget.track);
    return result is MetadataIncomplete ? result.missingFields : [];
  }

  Future<void> _populate() async {
    final title = _controllers['title']!.text.trim();
    final artist = _controllers['artist']!.text.trim();
    if (title.isEmpty || artist.isEmpty) {
      setState(() {
        _errorMessage = 'Enter at least a title and artist before populating.';
      });
      return;
    }

    setState(() {
      _populating = true;
      _errorMessage = null;
      _lookupResult = null;
      _pendingArtworkUrl = null;
      _previewArtworkPath = null;
    });

    final result = await _lookup.lookup(
      title: title,
      artist: artist,
      album: _controllers['album']!.text.trim().isEmpty
          ? null
          : _controllers['album']!.text.trim(),
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _populating = false;
        _errorMessage = 'No match found on MusicBrainz or iTunes.';
      });
      return;
    }

    // Apply found fields only if the current field is empty
    if (result.album != null && _controllers['album']!.text.trim().isEmpty) {
      _controllers['album']!.text = result.album!;
    }
    if (result.releaseYear != null &&
        _controllers['releaseYear']!.text.trim().isEmpty) {
      _controllers['releaseYear']!.text = result.releaseYear.toString();
    }
    if (result.genre != null && _controllers['genre']!.text.trim().isEmpty) {
      _controllers['genre']!.text = result.genre!;
    }

    // Download a preview of the artwork thumbnail
    String? previewPath;
    if (result.artworkUrl != null) {
      previewPath = await _lookup.downloadArtwork(
        result.artworkUrl!,
        widget.track.id,
      );
    }

    setState(() {
      _populating = false;
      _lookupResult = result;
      _pendingArtworkUrl = result.artworkUrl;
      _previewArtworkPath = previewPath;
    });
  }

  Future<bool> _ensureWritePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final result = await Permission.manageExternalStorage.request();
      if (result.isGranted) return true;
      final legacy = await Permission.storage.request();
      return legacy.isGranted;
    }
    return true;
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final hasPermission = await _ensureWritePermission();
    if (!hasPermission) {
      setState(() {
        _saving = false;
        _errorMessage =
            'Storage write permission denied. Grant "All files access" in '
            'Settings > Apps > Nightingale > Permissions.';
      });
      return;
    }

    final title = _controllers['title']!.text.trim();
    final artist = _controllers['artist']!.text.trim();
    final album = _controllers['album']!.text.trim();
    final albumArtist = _controllers['albumArtist']!.text.trim();
    final rawGenre = _controllers['genre']!.text.trim();
    final genre = rawGenre.isEmpty
        ? rawGenre
        : rawGenre[0].toUpperCase() + rawGenre.substring(1).toLowerCase();
    final year = int.tryParse(_controllers['releaseYear']!.text.trim());

    // Resolve artwork: use already-downloaded preview path if we have one
    String? artworkPath = _previewArtworkPath;
    if (artworkPath == null && _pendingArtworkUrl != null) {
      artworkPath = await _lookup.downloadArtwork(
        _pendingArtworkUrl!,
        widget.track.id,
      );
    }

    // Build artwork bytes for embedding into the file
    mg.Image? picture;
    if (artworkPath != null) {
      try {
        final bytes = await File(artworkPath).readAsBytes();
        picture = mg.Image(data: bytes, mimeType: 'image/jpeg');
      } catch (e) {
        AppLogger.warning('Could not read artwork for embedding: $e',
            tag: _tag);
      }
    }

    try {
      await mg.MetadataGod.writeMetadata(
        widget.track.filePath,
        mg.Metadata(
          title: title.isEmpty ? null : title,
          artist: artist.isEmpty ? null : artist,
          album: album.isEmpty ? null : album,
          albumArtist: albumArtist.isEmpty ? null : albumArtist,
          genre: genre.isEmpty ? null : genre,
          year: year,
          picture: picture,
        ),
      );
    } on FileSystemException catch (e) {
      AppLogger.warning('Tag write failed (filesystem): $e', tag: _tag);
      setState(() {
        _saving = false;
        _errorMessage = 'Cannot write to this file — check storage permissions.';
      });
      return;
    } catch (e) {
      AppLogger.warning('Tag write failed: $e', tag: _tag);
      setState(() {
        _saving = false;
        _errorMessage = 'Failed to write tags: $e';
      });
      return;
    }

    // File write succeeded — update the database
    try {
      final db = sl<AppDatabase>();
      final effectiveArtist = artist.isEmpty ? widget.track.artist : artist;

      int? resolvedAlbumId = widget.track.albumId;
      if (album.isNotEmpty) {
        final existing =
            await db.albumDao.getAlbumByNameAndArtist(album, effectiveArtist);
        if (existing != null) {
          resolvedAlbumId = existing.id;
        } else {
          resolvedAlbumId = await db.albumDao.upsertAlbum(
            AlbumsTableCompanion.insert(
              name: album,
              artist: Value(effectiveArtist),
            ),
          );
        }
      }

      final updated = widget.track.toUpdateCompanion().copyWith(
        title: Value(title.isEmpty ? widget.track.title : title),
        artist: Value(effectiveArtist),
        albumId: Value(resolvedAlbumId),
        albumArtist: Value(albumArtist.isEmpty ? null : albumArtist),
        genre: Value(genre.isEmpty ? null : genre),
        releaseYear: Value(year),
        artworkPath: artworkPath != null
            ? Value(artworkPath)
            : Value(widget.track.artworkPath),
      );
      await db.trackDao.updateTrack(updated);
      AppLogger.info('Metadata updated for track ${widget.track.id}',
          tag: _tag);
    } catch (e) {
      AppLogger.error('DB update after tag write failed: $e', tag: _tag);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final missing = _missingFields;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Header row with title and Populate button
            Row(
              children: [
                Expanded(
                  child: Text('Edit Track Metadata',
                      style: textTheme.titleMedium),
                ),
                FilledButton.tonalIcon(
                  onPressed: _populating || _saving ? null : _populate,
                  icon: _populating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_fix_high, size: 16),
                  label:
                      Text(_populating ? 'Searching…' : 'Populate'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),

            if (missing.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Required for sharing: ${missing.map(_fieldLabel).join(', ')}',
                style: textTheme.labelSmall
                    ?.copyWith(color: const Color(0xFFFF3B30)),
              ),
            ],

            // Lookup result preview
            if (_lookupResult != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _LookupPreviewCard(
                result: _lookupResult!,
                artworkPath: _previewArtworkPath,
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            ..._buildFields(missing),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _errorMessage!,
                style:
                    textTheme.labelSmall?.copyWith(color: scheme.error),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields(List<String> missingFields) {
    final fields = <Widget>[];

    for (final key in [
      'title',
      'artist',
      'album',
      'albumArtist',
      'genre',
      'releaseYear',
    ]) {
      final isMissing = missingFields.contains(key);
      final controller = _controllers[key];
      if (controller == null) continue;

      fields.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TextField(
            controller: controller,
            keyboardType: key == 'releaseYear'
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              labelText: _fieldLabel(key),
              labelStyle: isMissing
                  ? const TextStyle(color: Color(0xFFFF3B30))
                  : null,
              border: const OutlineInputBorder(),
            ),
          ),
        ),
      );
    }

    // Artwork row — shows preview if available, otherwise note
    fields.add(_ArtworkRow(
      isMissing: missingFields.contains('artworkPath'),
      localPath: _previewArtworkPath ?? widget.track.artworkPath,
      pendingUrl: _pendingArtworkUrl,
    ));

    return fields;
  }

  String _fieldLabel(String key) => _fieldLabels[key] ?? key;
}

// ── Lookup preview card ───────────────────────────────────────────────────────

class _LookupPreviewCard extends StatelessWidget {
  const _LookupPreviewCard({
    required this.result,
    required this.artworkPath,
  });

  final MetadataLookupResult result;
  final String? artworkPath;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final found = <String>[];
    if (result.album != null) found.add('album');
    if (result.releaseYear != null) found.add('year');
    if (result.genre != null) found.add('genre');
    if (result.artworkUrl != null) found.add('artwork');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (artworkPath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(artworkPath!),
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 48,
                  height: 48,
                ),
              ),
            )
          else
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(Icons.image_not_supported_outlined,
                  size: 20, color: scheme.onSurfaceVariant),
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Found via ${result.source}',
                  style: textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF34C759),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  found.isEmpty
                      ? 'No new fields found'
                      : 'Applied: ${found.join(', ')}',
                  style: textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Artwork row ───────────────────────────────────────────────────────────────

class _ArtworkRow extends StatelessWidget {
  const _ArtworkRow({
    required this.isMissing,
    required this.localPath,
    required this.pendingUrl,
  });

  final bool isMissing;
  final String? localPath;
  final String? pendingUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (localPath != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.file(
                File(localPath!),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image_outlined, size: 40),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Artwork ready', style: textTheme.bodySmall),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 16,
            color: isMissing
                ? const Color(0xFFFF3B30)
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              isMissing
                  ? 'Artwork missing — tap Populate to fetch it automatically'
                  : 'No artwork',
              style: textTheme.labelSmall?.copyWith(
                color: isMissing ? const Color(0xFFFF3B30) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
