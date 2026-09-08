import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor openDatabaseConnection() => LazyDatabase(() async {
  final dir = await getApplicationSupportDirectory();
  final dbFolder = p.join(dir.path, 'database');
  await Directory(dbFolder).create(recursive: true);
  final file = p.join(dbFolder, 'hikmah_player.db');
  return NativeDatabase.createInBackground(File(file));
});
