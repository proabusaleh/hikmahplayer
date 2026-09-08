import 'dart:io';

import 'package:flutter/material.dart';

/// Renders a media thumbnail/album art when a local file path is available,
/// otherwise a branded placeholder. Uses [Image.file] with an [errorBuilder]
/// so missing files degrade gracefully without touching the file system.
class LibraryThumbnail extends StatelessWidget {
  const LibraryThumbnail({
    super.key,
    this.path,
    required this.placeholderIcon,
    this.backgroundColor,
    this.foregroundColor,
    this.fit = BoxFit.cover,
  });

  /// Local file path of the thumbnail/artwork, if one was persisted.
  final String? path;

  /// Icon drawn on the placeholder when there's no artwork to show.
  final IconData placeholderIcon;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg =
        backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final fg = foregroundColor ?? theme.colorScheme.onSurfaceVariant;

    Widget placeholder = Container(
      color: bg,
      child: Center(
        child: Icon(placeholderIcon, color: fg.withValues(alpha: 0.35)),
      ),
    );

    final artwork = path;
    if (artwork == null || artwork.isEmpty) return placeholder;

    return Image.file(
      File(artwork),
      fit: fit,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}