import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../services/notification_service.dart';

class NotificationBridge extends Notifier<void> {
  NotificationBridge();

  @override
  void build() {}

  Future<void> init() async {
    await NotificationService.instance.init(
      onTap: (response) {
        _handleResponse(response);
      },
    );
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    final action = response.actionId;
    final payload = response.payload ?? '';
    debugPrint('Notification tap: action=$action payload=$payload');
  }
}

final notificationBridgeProvider =
    NotifierProvider<NotificationBridge, void>(NotificationBridge.new);
