import 'package:flutter/services.dart';

abstract final class PlatformChannels {
  static const mediaScanner = MethodChannel('com.hikmahplayer/media_scanner');
  static const thumbnails = MethodChannel('com.hikmahplayer/thumbnails');
  static const metadataExtractor =
      MethodChannel('com.hikmahplayer/metadata_extractor');
}

abstract final class PlatformChannelMethods {
  static const scanVideos = 'scanVideos';
  static const scanAudio = 'scanAudio';
  static const cancelScan = 'cancelScan';

  static const generateThumbnail = 'generateThumbnail';
  static const extractArtwork = 'extractArtwork';

  static const getMetadata = 'getMetadata';
}
