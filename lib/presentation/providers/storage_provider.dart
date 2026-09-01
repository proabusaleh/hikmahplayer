import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Snapshot of the device's total/used/free storage.
class StorageInfo {
  const StorageInfo({
    required this.totalGB,
    required this.usedGB,
    required this.freeGB,
  });

  final double totalGB;
  final double usedGB;
  final double freeGB;

  /// Fraction `0.0..1.0` of how much storage is used.
  double get usedPercent => totalGB <= 0 ? 0 : (usedGB / totalGB).clamp(0.0, 1.0);
}

/// Current device storage, or `null` on desktop where it is irrelevant.
///
/// TODO: wire real device stats (e.g. the `disk_space` package) for Android &
/// iOS. Values are placeholders until then.
final storageInfoProvider = Provider<StorageInfo?>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    return const StorageInfo(totalGB: 128.0, usedGB: 82.5, freeGB: 45.5);
  }
  return null;
});