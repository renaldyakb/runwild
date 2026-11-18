import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_version.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.downloadUrl,
    this.publishedAt,
  });

  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String downloadUrl;
  final DateTime? publishedAt;
}

abstract interface class AppUpdateService {
  Future<AppUpdateInfo?> checkForUpdate({bool notify = true});
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return GitHubAppUpdateService();
});

class GitHubAppUpdateService implements AppUpdateService {
  GitHubAppUpdateService({
    FlutterLocalNotificationsPlugin? notifications,
    HttpClient? httpClient,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _httpClient = httpClient ?? HttpClient();

  final FlutterLocalNotificationsPlugin _notifications;
  final HttpClient _httpClient;

  static const String _lastNotifiedKey = 'last_notified_update_version';
  static const int _updateNotificationId = 2002;
  static const String _channelId = 'app_updates_channel';
  static const String _channelName = 'Pembaruan RUNWILD';
  static const String _channelDescription =
      'Notifikasi saat versi terbaru RUNWILD tersedia';

  static bool isNewerVersion(String latest, String current) {
    final cleanLatest = latest.replaceAll(RegExp(r'[^0-9.]'), '');
    final cleanCurrent = current.replaceAll(RegExp(r'[^0-9.]'), '');
    final lParts = cleanLatest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final cParts = cleanCurrent
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    while (lParts.length < 3) {
      lParts.add(0);
    }
    while (cParts.length < 3) {
      cParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (lParts[i] > cParts[i]) return true;
      if (lParts[i] < cParts[i]) return false;
    }
    return false;
  }

  @override
  Future<AppUpdateInfo?> checkForUpdate({bool notify = true}) async {
    try {
      final request = await _httpClient
          .getUrl(Uri.parse(AppVersion.latestReleaseApi))
          .timeout(const Duration(seconds: 5));
      request.headers.set('User-Agent', 'RUNWILD-App');
      request.headers.set('Accept', 'application/vnd.github.v3+json');

      final response = await request.close().timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != 200) {
        return null;
      }

      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final tagName = (data['tag_name'] as String? ?? '').replaceFirst('v', '');
      if (tagName.isEmpty) return null;

      final releaseNotes =
          data['body'] as String? ?? 'Pembaruan aplikasi siap diunduh.';
      final htmlUrl = data['html_url'] as String? ?? AppVersion.releasesPage;

      String downloadUrl = htmlUrl;
      final assets = data['assets'] as List<dynamic>?;
      if (assets != null && assets.isNotEmpty) {
        for (final asset in assets) {
          final assetMap = asset as Map<String, dynamic>;
          final name = assetMap['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            downloadUrl =
                assetMap['browser_download_url'] as String? ?? htmlUrl;
            break;
          }
        }
      }

      DateTime? publishedAt;
      final publishedStr = data['published_at'] as String?;
      if (publishedStr != null) {
        publishedAt = DateTime.tryParse(publishedStr);
      }

      final hasUpdate = isNewerVersion(tagName, AppVersion.current);
      final updateInfo = AppUpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: AppVersion.current,
        latestVersion: tagName,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        publishedAt: publishedAt,
      );

      if (hasUpdate && notify) {
        await _notifyIfNew(tagName);
      }

      return updateInfo;
    } catch (_) {
      return null;
    }
  }

  Future<void> _notifyIfNew(String latestVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastNotified = prefs.getString(_lastNotifiedKey);
      if (lastNotified == latestVersion) {
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _notifications.show(
        id: _updateNotificationId,
        title: 'Pembaruan RUNWILD v$latestVersion Tersedia! 🚀',
        body: 'Versi terbaru siap dipasang. Buka aplikasi untuk memperbarui.',
        notificationDetails: details,
      );

      await prefs.setString(_lastNotifiedKey, latestVersion);
    } catch (_) {
      // Best-effort notification
    }
  }
}
