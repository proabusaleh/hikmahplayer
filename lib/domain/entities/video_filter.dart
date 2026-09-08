enum VideoDurationFilter { short, medium, long }

enum VideoResolutionFilter { sd, hd, fullHd, fourK, unknown }

enum VideoTagFilter { favorite, noTag }

class VideoLibraryFilter {
  const VideoLibraryFilter({
    this.duration,
    this.resolution,
    this.tag,
  });

  final VideoDurationFilter? duration;
  final VideoResolutionFilter? resolution;
  final VideoTagFilter? tag;

  bool get isEmpty => duration == null && resolution == null && tag == null;

  VideoLibraryFilter copyWith({
    VideoDurationFilter? duration,
    VideoResolutionFilter? resolution,
    VideoTagFilter? tag,
    bool clearDuration = false,
    bool clearResolution = false,
    bool clearTag = false,
  }) {
    return VideoLibraryFilter(
      duration: clearDuration ? null : (duration ?? this.duration),
      resolution: clearResolution ? null : (resolution ?? this.resolution),
      tag: clearTag ? null : (tag ?? this.tag),
    );
  }

  String get label {
    final parts = <String>[];
    if (duration != null) {
      parts.add(switch (duration!) {
        VideoDurationFilter.short => '< 5 min',
        VideoDurationFilter.medium => '5-20 min',
        VideoDurationFilter.long => '> 20 min',
      });
    }
    if (resolution != null) {
      parts.add(switch (resolution!) {
        VideoResolutionFilter.sd => 'SD',
        VideoResolutionFilter.hd => 'HD',
        VideoResolutionFilter.fullHd => 'FHD',
        VideoResolutionFilter.fourK => '4K',
        VideoResolutionFilter.unknown => 'Unknown',
      });
    }
    if (tag != null) {
      parts.add(switch (tag!) {
        VideoTagFilter.favorite => 'Favorite',
        VideoTagFilter.noTag => 'No Tag',
      });
    }
    return parts.join(', ');
  }
}

/// Resolution bucket based on pixel height.
VideoResolutionFilter classifyResolution(int? height) {
  if (height == null || height <= 0) return VideoResolutionFilter.unknown;
  if (height <= 480) return VideoResolutionFilter.sd;
  if (height <= 720) return VideoResolutionFilter.hd;
  if (height <= 1080) return VideoResolutionFilter.fullHd;
  return VideoResolutionFilter.fourK;
}

/// Resolution rank for sort: higher is better.
int resolutionRank(int? height) {
  return switch (classifyResolution(height)) {
    VideoResolutionFilter.fourK => 4,
    VideoResolutionFilter.fullHd => 3,
    VideoResolutionFilter.hd => 2,
    VideoResolutionFilter.sd => 1,
    VideoResolutionFilter.unknown => 0,
  };
}
