import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class ThumbnailGenerator {
  const ThumbnailGenerator();

  Future<String?> generateVideoThumbnail(
    String videoPath, {
    String? cacheDirectory,
    int maxWidth = 512,
  }) async {
    throw UnimplementedError();
  }

  Future<String?> generateAudioArtwork(
    String audioPath, {
    String? cacheDirectory,
  }) async {
    throw UnimplementedError();
  }

  ImageProvider? thumbnailProvider(String? thumbnailPath) {
    if (thumbnailPath == null || thumbnailPath.isEmpty) return null;
    final file = File(thumbnailPath);
    if (!file.existsSync()) return null;
    return FileImage(file);
  }

  String cachePathFor(String mediaPath, {required String cacheDirectory}) {
    final hash = p.basenameWithoutExtension(mediaPath).hashCode
        .toRadixString(16)
        .padLeft(8, '0');
    return p.join(cacheDirectory, '$hash.jpg');
  }
}
