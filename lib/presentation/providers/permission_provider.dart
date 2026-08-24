import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    throw UnimplementedError();
  }

  Future<void> checkStatus() async {
    throw UnimplementedError();
  }

  void openAppSettings() => throw UnimplementedError();
}

final permissionProvider =
    NotifierProvider<PermissionController, PermissionStatusState>(
  PermissionController.new,
);
