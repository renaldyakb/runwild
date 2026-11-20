import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Satu jadwal pengingat lari yang disimpan di perangkat.
class RunReminder {
  const RunReminder({required this.id, required this.time});

  /// ID notifikasi sistem; unik dan stabil supaya jadwal dapat diubah/dihapus.
  final int id;
  final DateTime time;

  Map<String, dynamic> toMap() => {
    'id': id,
    'time': time.millisecondsSinceEpoch,
  };

  static RunReminder? fromMap(Map<String, dynamic> map) {
    final id = (map['id'] as num?)?.toInt();
    final millis = (map['time'] as num?)?.toInt();
    if (id == null || millis == null) return null;
    return RunReminder(
      id: id,
      time: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }
}

/// Kelompok tampilan jadwal pada halaman pengelolaan.
enum ReminderGroup { today, tomorrow, later }

/// Mengelompokkan jadwal menjadi "Hari ini", "Besok", atau "Berikutnya".
ReminderGroup reminderGroupFor(DateTime time, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final difference = day.difference(today).inDays;
  if (difference <= 0) return ReminderGroup.today;
  if (difference == 1) return ReminderGroup.tomorrow;
  return ReminderGroup.later;
}

/// Penyimpanan jadwal lokal (SharedPreferences).
///
/// Kelas ini sengaja tidak menyentuh plugin notifikasi supaya seluruh aturan
/// jadwal (urutan, pemangkasan jadwal lewat waktu, ID unik) dapat diuji tanpa
/// perangkat.
class RunReminderStore {
  RunReminderStore({DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  static const storageKey = 'run_reminders_v1';
  static const _nextIdKey = 'run_reminder_next_id';

  /// ID notifikasi pertama; dinaikkan satu-satu untuk jadwal berikutnya.
  static const firstNotificationId = 2003;

  final DateTime Function() _now;

  Future<List<RunReminder>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final parsed = _decode(prefs.getString(storageKey));
    final now = _now();
    final upcoming = [
      for (final reminder in parsed)
        if (reminder.time.isAfter(now)) reminder,
    ]..sort((a, b) => a.time.compareTo(b.time));
    if (upcoming.length != parsed.length) await _save(upcoming);
    return upcoming;
  }

  Future<RunReminder> add(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_nextIdKey) ?? firstNotificationId;
    await prefs.setInt(_nextIdKey, id + 1);
    final reminder = RunReminder(id: id, time: time);
    final reminders = await load()
      ..add(reminder)
      ..sort((a, b) => a.time.compareTo(b.time));
    await _save(reminders);
    return reminder;
  }

  Future<void> remove(int id) async {
    final reminders = await load()
      ..removeWhere((r) => r.id == id);
    await _save(reminders);
  }

  List<RunReminder> _decode(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return [
      for (final item in decoded)
        if (item is Map<String, dynamic>) ?RunReminder.fromMap(item),
    ];
  }

  Future<void> _save(List<RunReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode([for (final reminder in reminders) reminder.toMap()]),
    );
  }
}

/// Jadwal ditolak karena izin notifikasi belum diberikan.
class ReminderPermissionDenied implements Exception {
  const ReminderPermissionDenied();
}

/// Penjadwalan notifikasi oleh sistem operasi.
abstract interface class RunReminderScheduler {
  Future<void> schedule(
    RunReminder reminder, {
    required String title,
    required String body,
  });

  Future<void> cancel(int notificationId);
}

final runReminderStoreProvider = Provider<RunReminderStore>(
  (ref) => RunReminderStore(),
);

final reminderSchedulerProvider = Provider<RunReminderScheduler>(
  (ref) => DeviceRunReminderScheduler(),
);

/// Menjadwalkan notifikasi lewat sistem operasi (AlarmManager di Android),
/// sehingga pengingat tetap muncul walau aplikasi sedang tertutup.
class DeviceRunReminderScheduler implements RunReminderScheduler {
  DeviceRunReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  /// Kanal baru: Android tidak mengubah suara kanal yang sudah pernah dibuat,
  /// jadi suara khusus butuh ID kanal baru.
  static const channelId = 'run_reminders_v2';
  static const soundResource = 'sound_effect';
  static const soundFile = 'Sound_effect.mp3';

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<void> schedule(
    RunReminder reminder, {
    required String title,
    required String body,
  }) async {
    if (!reminder.time.isAfter(DateTime.now())) {
      throw ArgumentError('Jadwal sudah lewat');
    }
    final status = await Permission.notification.request();
    if (!status.isGranted) throw const ReminderPermissionDenied();
    await _initialize();
    await _plugin.zonedSchedule(
      id: reminder.id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminder.time, tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Pengingat lari',
          channelDescription: 'Pengingat jadwal lari RUNWILD',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundResource),
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          sound: soundFile,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(int notificationId) async {
    await _initialize();
    await _plugin.cancel(id: notificationId);
  }
}

/// Daftar jadwal aktif beserta penjadwalan notifikasinya.
class RunRemindersNotifier extends AsyncNotifier<List<RunReminder>> {
  RunReminderStore get _store => ref.read(runReminderStoreProvider);
  RunReminderScheduler get _scheduler => ref.read(reminderSchedulerProvider);

  @override
  Future<List<RunReminder>> build() => _store.load();

  Future<void> add(
    DateTime time, {
    required String title,
    required String body,
  }) async {
    final reminder = await _store.add(time);
    try {
      await _scheduler.schedule(reminder, title: title, body: body);
    } catch (_) {
      // Tanpa notifikasi terjadwal, jadwal hanya akan menipu: buang lagi.
      await _store.remove(reminder.id);
      rethrow;
    }
    state = AsyncData(await _store.load());
  }

  Future<void> remove(int id) async {
    await _scheduler.cancel(id);
    await _store.remove(id);
    state = AsyncData(await _store.load());
  }
}

final runRemindersProvider =
    AsyncNotifierProvider.autoDispose<RunRemindersNotifier, List<RunReminder>>(
      RunRemindersNotifier.new,
    );
