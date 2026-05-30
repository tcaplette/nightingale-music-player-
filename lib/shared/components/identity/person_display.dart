import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class PersonDisplay extends StatelessWidget {
  const PersonDisplay({
    super.key,
    required this.displayName,
    this.avatarUrl,
    this.handle,
    this.showHandle = false,
    this.avatarSize = 40,
  });

  final String displayName;
  final String? avatarUrl;

  // The raw @user@node handle — never rendered unless showHandle is true.
  final String? handle;

  // Only set true in settings, advanced profile, or diagnostic contexts.
  final bool showHandle;

  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Avatar(
          displayName: displayName,
          avatarUrl: avatarUrl,
          size: avatarSize,
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                displayName,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
              if (showHandle && handle != null)
                Text(
                  handle!,
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.displayName,
    required this.size,
    this.avatarUrl,
  });

  final String displayName;
  final String? avatarUrl;
  final double size;

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final monogram = CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primary.withValues(alpha: 0.15),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.35,
        ),
      ),
    );

    final url = avatarUrl;
    if (url == null) return monogram;

    return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (_, image) =>
          CircleAvatar(radius: size / 2, backgroundImage: image),
      placeholder: (_, _) => monogram,
      errorWidget: (_, _, _) => monogram,
    );
  }
}
