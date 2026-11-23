import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/components/rw_chip.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';
import 'package:runwild/features/run/application/run_gps_probe.dart';
import 'package:runwild/features/run/application/run_location.dart';
import 'package:runwild/features/run/application/run_permissions.dart';

import 'support.dart';

class _Location implements RunLocation {
  final fixes = StreamController<GpsSample>();
  late Duration Function() clock;

  @override
  Stream<GpsSample> samples({
    required Duration Function() clock,
    required String notificationTitle,
    required String notificationText,
  }) {
    this.clock = clock;
    return fixes.stream;
  }
}

class _Permissions implements RunPermissions {
  final requests = <RunPermission>[];
  var location = RunPermissionStatus.denied;
  var nextLocation = RunPermissionStatus.granted;
  var notifications = RunPermissionStatus.granted;
  var nextNotifications = RunPermissionStatus.granted;
  var serviceEnabled = true;
  int settingsOpened = 0;
  int locationSettingsOpened = 0;
  bool fail = false;

  @override
  Future<RunPermissionStatus> status(RunPermission permission) async {
    if (fail) throw Exception('Permission service unavailable');
    return permission == RunPermission.location ? location : notifications;
  }

  @override
  Future<RunPermissionStatus> request(RunPermission permission) async {
    requests.add(permission);
    if (fail) throw Exception('Permission service unavailable');
    return permission == RunPermission.location
        ? location = nextLocation
        : notifications = nextNotifications;
  }

  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<bool> openLocationSettings() async {
    locationSettingsOpened++;
    return true;
  }
}

Future<void> _tap(WidgetTester tester, String label) async {
  final button = find.text(label);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Interval kustom validates and starts the selected walking phase',
    (tester) async {
      var now = Duration.zero;
      final source = _Location();
      await pumpRunwild(
        tester,
        runPermissions: _Permissions(),
        runLocation: source,
        countdownClock: () => now,
      );
      await _tap(tester, 'Lari');
      await tester.ensureVisible(find.widgetWithText(RwChip, 'Interval'));
      await tester.tap(find.widgetWithText(RwChip, 'Interval'));
      await tester.pumpAndSettle();
      await _tap(tester, 'Atur interval');
      await _tap(tester, '5 : 1');
      for (final (label, value) in [
        ('Pemanasan (detik)', '0'),
        ('Lari (detik)', '9'),
        ('Jalan (detik)', '10'),
        ('Jumlah putaran', '1'),
        ('Pendinginan (detik)', '0'),
      ]) {
        final field = find.widgetWithText(TextFormField, label);
        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }
      expect(
        find.text('Lengkapi durasi dan putaran sesuai batas.'),
        findsOneWidget,
      );
      final run = find.widgetWithText(TextFormField, 'Lari (detik)');
      await tester.ensureVisible(run);
      await tester.enterText(run, '10');
      await tester.pumpAndSettle();
      await _tap(tester, 'Gunakan interval');
      await _tap(tester, 'Aktifkan lokasi');
      await _tap(tester, 'Mulai sesi lari');
      now = const Duration(seconds: 3);
      await tester.pump(now);
      expect(find.text('Jalan'), findsOneWidget);
      expect(find.text('Putaran 1/1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.fixes.close);
    },
  );

  testWidgets(
    'Tombol beranda membuka countdown untuk akun tanpa sesi tersimpan',
    (tester) async {
      await pumpRunwild(
        tester,
        runPermissions: _Permissions(),
        runOwner: 'runner',
        pendingRun: () async => null,
        countdownClock: () => Duration.zero,
      );
      await _tap(tester, 'Mulai berlari');
      await _tap(tester, 'Aktifkan lokasi');
      await _tap(tester, 'Mulai sesi lari');
      expect(find.text('Bersiap'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('Akun dengan sesi tersimpan melihat pilihan pemulihan', (
    tester,
  ) async {
    await pumpRunwild(
      tester,
      runPermissions: _Permissions(),
      runOwner: 'runner',
      pendingRun: () async => (
        id: 1,
        startedAt: DateTime(2026, 11, 14, 6),
        meters: 320.0,
        moving: const Duration(minutes: 2),
        elapsed: const Duration(minutes: 2),
        points: 20,
      ),
    );
    await _tap(tester, 'Lari');
    await _tap(tester, 'Aktifkan lokasi');
    await _tap(tester, 'Mulai sesi lari');
    expect(find.text('Lanjutkan sesi'), findsOneWidget);
    expect(find.text('Bersiap'), findsNothing);
  });

  testWidgets(
    'Sesi mulai setelah countdown, bisa dijeda, dikunci dan diakhiri',
    (tester) async {
      final permissions = _Permissions();
      final source = _Location();
      var now = Duration.zero;
      await pumpRunwild(
        tester,
        runPermissions: permissions,
        runLocation: source,
        countdownClock: () => now,
      );
      await _tap(tester, 'Lari');
      await _tap(tester, 'Aktifkan lokasi');
      await _tap(tester, 'Mulai sesi lari');
      expect(find.text('3'), findsOneWidget);
      expect(source.fixes.hasListener, isFalse);
      now = const Duration(seconds: 3);
      await tester.pump(now);
      expect(source.fixes.hasListener, isTrue);
      await _tap(tester, 'Jeda');
      expect(find.text('Lanjut'), findsOneWidget);
      await _tap(tester, 'Kunci kontrol');
      expect(find.text('Lanjut'), findsNothing);
      final unlock = find.text('Tahan 1 detik untuk membuka kunci');
      await tester.ensureVisible(unlock);
      final hold = await tester.startGesture(tester.getCenter(unlock));
      await tester.pump(const Duration(milliseconds: 900));
      expect(find.text('Kontrol terkunci'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await hold.up();
      await tester.pump();
      expect(find.text('Lanjut'), findsOneWidget);
      await _tap(tester, 'Lanjut');
      await _tap(tester, 'Selesai');
      await tester.tap(find.widgetWithText(TextButton, 'Selesai'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      if (find.text('Simpan Sesi').evaluate().isNotEmpty) {
        await _tap(tester, 'Simpan Sesi');
      }
      expect(source.fixes.hasListener, isFalse);
      expect(find.text('Run Free,'), findsOneWidget);
    },
  );

  test('GPS probe counts accepted fixes and releases GPS on stop', () async {
    final source = _Location();
    final container = ProviderContainer(
      overrides: [runLocationProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    addTearDown(source.fixes.close);
    final subscription = container.listen(runGpsProbeProvider, (_, _) {});
    addTearDown(subscription.close);
    final probe = container.read(runGpsProbeProvider.notifier);
    await probe.start(notificationTitle: 'RUNWILD', notificationText: 'GPS');
    for (final accuracy in [99.0, 5.0]) {
      source.fixes.add(
        GpsSample(
          latitude: 0,
          longitude: 0,
          accuracyMeters: accuracy,
          capturedAt: source.clock(),
        ),
      );
    }
    await Future<void>.delayed(Duration.zero);
    expect(subscription.read().status, GpsProbeStatus.recording);
    expect(subscription.read().points, 1);
    await probe.stop();
    expect(source.fixes.hasListener, isFalse);
    expect(subscription.read().status, GpsProbeStatus.stopped);
  });

  test('Source failure ends the probe and releases the subscription', () async {
    final source = _Location();
    final container = ProviderContainer(
      overrides: [runLocationProvider.overrideWithValue(source)],
    );
    addTearDown(container.dispose);
    addTearDown(source.fixes.close);
    final subscription = container.listen(runGpsProbeProvider, (_, _) {});
    addTearDown(subscription.close);
    await container
        .read(runGpsProbeProvider.notifier)
        .start(notificationTitle: 'RUNWILD', notificationText: 'GPS');
    source.fixes.addError(Exception('GPS disabled'));
    await Future<void>.delayed(Duration.zero);
    expect(subscription.read().status, GpsProbeStatus.failed);
    expect(source.fixes.hasListener, isFalse);
  });
  testWidgets(
    'Izin aktif disembunyikan dan peringatan hanya untuk yang belum aktif',
    (tester) async {
      final permissions = _Permissions()
        ..notifications = RunPermissionStatus.denied;
      await pumpRunwild(
        tester,
        runPermissions: permissions,
        dark: true,
        scale: 2,
      );
      expect(permissions.requests, isEmpty);
      await _tap(tester, 'Lari');
      expect(find.text('Lokasi dan notifikasi perlu aktif'), findsOneWidget);
      expect(
        find.textContaining('Izin lokasi belum diberikan'),
        findsOneWidget,
      );
      expect(find.textContaining('Notifikasi belum diizinkan'), findsOneWidget);
      expect(permissions.requests, isEmpty);

      await _tap(tester, 'Aktifkan lokasi');
      expect(permissions.requests, [RunPermission.location]);
      expect(find.textContaining('Izin lokasi belum diberikan'), findsNothing);
      expect(find.textContaining('Notifikasi belum diizinkan'), findsOneWidget);

      await _tap(tester, 'Izinkan notifikasi');
      expect(permissions.requests, [
        RunPermission.location,
        RunPermission.notifications,
      ]);
      expect(find.text('Lokasi dan notifikasi perlu aktif'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Izin diblokir membuka pengaturan dan dicek saat kembali', (
    tester,
  ) async {
    final permissions = _Permissions()
      ..nextLocation = RunPermissionStatus.blocked;
    await pumpRunwild(tester, runPermissions: permissions);
    await _tap(tester, 'Lari');
    await _tap(tester, 'Aktifkan lokasi');
    expect(find.textContaining('lewat pengaturan perangkat'), findsOneWidget);
    await _tap(tester, 'Buka pengaturan');
    expect(permissions.settingsOpened, 1);
    permissions.location = RunPermissionStatus.granted;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.textContaining('Izin lokasi belum diberikan'), findsNothing);
    expect(find.text('Buka pengaturan'), findsNothing);
    expect(permissions.requests, [RunPermission.location]);
  });

  testWidgets('Kegagalan layanan izin dapat dicoba ulang', (tester) async {
    final permissions = _Permissions()..fail = true;
    await pumpRunwild(tester, runPermissions: permissions);
    await _tap(tester, 'Lari');
    expect(find.text('Izin belum bisa diperiksa. Coba lagi.'), findsOneWidget);
    permissions.fail = false;
    await _tap(tester, 'Periksa izin lagi');
    await _tap(tester, 'Aktifkan lokasi');
    expect(find.textContaining('Izin lokasi belum diberikan'), findsNothing);
  });
}
