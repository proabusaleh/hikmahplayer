enum MediaType { video, audio }

MediaType mediaTypeFromName(String name) =>
    MediaType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => MediaType.video,
    );
