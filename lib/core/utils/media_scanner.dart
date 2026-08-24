import '../errors/exceptions.dart';

class MediaScanner {
  const MediaScanner._();

  static const _scanChannelName =
      'com.hikmahplayer/media_scanner';

  Future<List<String>> scanForVideos({String? directoryPath}) async {
    throw UnimplementedError();
  }

  Future<List<String>> scanForAudio({String? directoryPath}) async {
    throw UnimplementedError();
  }

  Future<bool> requestStoragePermission() {
    throw const PermissionDeniedException('MediaScanner is not wired up yet');
  }

  static const scanChannel = _scanChannelName;
}
