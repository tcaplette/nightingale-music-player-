import 'dart:io';

import 'package:flutter/material.dart';

class ArtworkThumbnail extends StatelessWidget {
  const ArtworkThumbnail({super.key, required this.path, required this.size});

  final String? path;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (path != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(path!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, e, stack) => _placeholder(scheme),
        ),
      );
    }
    return _placeholder(scheme);
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        Icons.music_note,
        size: size * 0.5,
        color: scheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}
