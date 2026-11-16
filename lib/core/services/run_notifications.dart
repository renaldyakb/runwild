import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract interface class RunNotifications {
  Future<void> initialize();
  Future<void> update({required String title, required String body});
  Future<void> cancel();
}

final runNotificationsProvider = Provider<RunNotifications>((ref) {
  final service = DeviceRunNotifications();
  ref.onDispose(() => unawaited(service.cancel()));
  return service;
});

class DeviceRunNotifications implements RunNotifications {
  DeviceRunNotifications({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _supported = true;
  static const int _notificationId = 1001;
  static const String _channelId = 'run_tracking_channel';
  static const String _channelName = 'Aktivitas Lari RUNWILD';
  static const String _channelDescription =
      'Status pelacakan dan fase interval saat berlari';

  @override
  Future<void> initialize() async {
    if (_initialized || !_supported) return;
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    try {
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (_) {
      _supported = false;
    }
  }

  @override
  Future<void> update({required String title, required String body}) async {
    if (!_supported) return;
    if (!_initialized) {
      await initialize();
    }
    if (!_supported) return;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );
    try {
      await _plugin.show(
        id: _notificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {
      _supported = false;
    }
  }

  @override
  Future<void> cancel() async {
    if (!_supported) return;
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (_) {
      // Safe ignore on dispose
    }
  }
}
