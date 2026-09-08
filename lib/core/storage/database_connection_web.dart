import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

/// Uses browser storage for the media index when the app runs on the web.
QueryExecutor openDatabaseConnection() => WebDatabase('hikmah_player');
