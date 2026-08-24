import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class StorageLocations {
  StorageLocations._();

  static const int maxThumbnailCacheBytes = 200 * 1024 * 1024;

  static Future<Directory> _ensure(String path) async {
    final dir = Directory(path);
    await dir.create(recursive: true);
    return dir;
  }

  static Future<String> databaseDir() async {
    final support = await getApplicationSupportDirectory();
    return _ensure(p.join(support.path, 'database')).then((d) => d.path);
  }

  static Future<String> cacheRoot() async =>
      (await getTemporaryDirectory()).path;

  static Future<String> videoThumbnails({String size = 'medium'}) async {
    final root = await cacheRoot();
    return _ensure(p.join(root, 'thumbnails', 'videos', size))
        .then((d) => d.path);
  }

  static Future<String> audioThumbnails({String size = 'medium'}) async {
    final root = await cacheRoot();
    return _ensure(p.join(root, 'thumbnails', 'audio', size))
        .then((d) => d.path);
  }

  static Future<String> waveforms() async {
    final root = await cacheRoot();
    return _ensure(p.join(root, 'waveforms')).then((d) => d.path);
  }

  static Future<String> temp() async {
    final root = await cacheRoot();
    return _ensure(p.join(root, 'temp')).then((d) => d.path);
  }

  static Future<void> clearTemp() async {
    final path = await temp();
    final dir = Directory(path);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }

  static Future<int> thumbnailCacheSize() async {
    final root = await cacheRoot();
    final dir = Directory(p.join(root, 'thumbnails'));
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final entity
        in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
