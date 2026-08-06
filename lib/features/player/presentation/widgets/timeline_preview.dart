import 'package:flutter/material.dart';

import '../../../../core/services/playback_service.dart';
import '../../../../shared/utils/format.dart';

/// Slim horizontal strip shown while scrubbing, with chapter/key-moment
/// markers and a live readout of the preview position.
class TimelinePreview extends StatelessWidget {
  const TimelinePreview({
    super.key,
    required this.playback,
    required this.previewPosition,
  });

  final PlaybackService playback;
  final Duration? previewPosition;

  @override
  Widget build(BuildContext context) {
    final duration = playback.duration.value;
    final chapters = playback.currentItem?.chapters ?? const [];
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (previewPosition != null)
            Text(
              Fmt.duration(previewPosition),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.primary),
            ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return SizedBox(
                height: 6,
                child: Stack(
                  children: [
                    Container(
                      width: width,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    if (duration != Duration.zero && previewPosition != null)
                      Container(
                        width: width *
                            (previewPosition!.inMilliseconds /
                                    duration.inMilliseconds)
                                .clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    for (final chapter in chapters)
                      if (duration != Duration.zero)
                        Positioned(
                          left: width *
                              (chapter.start.inMilliseconds /
                                      duration.inMilliseconds)
                                  .clamp(0.0, 1.0),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 2,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
