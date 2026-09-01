import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/media_scanner.dart';

sealed class PermissionStatusState {
  const PermissionStatusState();
}

class PermissionUnknown extends PermissionStatusState {
  const PermissionUnknown();
}

class PermissionGranted extends PermissionStatusState {
  const PermissionGranted();
}

class PermissionDenied extends PermissionStatusState {
  const PermissionDenied({this.isPermanentlyDenied = false});
  final bool isPermanentlyDenied;
}

class PermissionController extends Notifier<PermissionStatusState> {
  @override
  PermissionStatusState build() => const PermissionUnknown();

  Future<void> requestStoragePermission() async {
    final permissions = await _getPermissionsToRequest();
    final statuses = await permissions.request();
    
    bool allGranted = true;
    bool permanentlyDenied = false;

    for (final status in statuses.values) {
      if (!status.isGranted) {
        allGranted = false;
        if (status.isPermanentlyDenied) {
          permanentlyDenied = true;
        }
      }
    }

    if (allGranted) {
      state = const PermissionGranted();
    } else {
      state = PermissionDenied(isPermanentlyDenied: permanentlyDenied);
    }
  }

  Future<void> checkStatus() async {
    final permissions = await _getPermissionsToRequest();
    bool allGranted = true;
    bool permanentlyDenied = false;

    for (final permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        allGranted = false;
        if (status.isPermanentlyDenied) {
          permanentlyDenied = true;
        }
      }
    }

    if (allGranted) {
      state = const PermissionGranted();
    } else {
      state = PermissionDenied(isPermanentlyDenied: permanentlyDenied);
    }
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<List<Permission>> _getPermissionsToRequest() async {
    if (!Platform.isAndroid) {
      return [Permission.storage];
    }
    
    final sdkInt = await MediaScanner.sdkInt();
    if (sdkInt >= 33) {
      return [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ];
    } else {
      return [Permission.storage];
    }
  }
}

final permissionProvider =
    NotifierProvider<PermissionController, PermissionStatusState>(
  PermissionController.new,
);
