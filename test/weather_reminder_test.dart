import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/app_update_service.dart';
import 'package:runwild/core/utils/day_greeting.dart';
import 'package:runwild/domain/stats/stats_engine.dart';
import 'package:runwild/features/foundation/application/home_stats_provider.dart';
import 'package:runwild/features/foundation/application/run_reminder.dart';
import 'package:runwild/features/foundation/application/weather_kind.dart';
import 'package:runwild/features/foundation/application/weather_service.dart';
import 'package:runwild/features/foundation/presentation/home_dashboard.dart';
import 'package:runwild/features/foundation/presentation/run_reminders_screen.dart';
import 'package:runwild/features/foundation/presentation/weather_animation.dart';
import 'package:runwild/features/foundation/presentation/weather_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support.dart';

/// Penjadwal palsu: mencatat panggilan tanpa menyentuh plugin notifikasi.
class _FakeScheduler implements RunReminderScheduler {
  final scheduled = <int>[];
  final cancelled = <int>[];

  @override
  Future<void> schedule(
    RunReminder reminder, {
    required String title,
    required String body,
  }) async {
    scheduled.add(reminder.id);
  }

  @override
  Future<void> cancel(int notificationId) async {
    cancelled.add(notificationId);
  }
}

class _NoUpdates implements AppUpdateService {
  @override
  Future<AppUpdateInfo?> checkForUpdate({bool notify = true}) async => null;
}

String _forecastBody({int hours = 12}) => jsonEncode({
  'current': {'temperature_2m': 29.5, 'weather_code': 61},
  'hourly': {
    'time': [
      for (var i = 0; i < hours; i++)
        '2026-11-20T${i.toString().padLeft(2, '0')}:00',
    ],
    'weather_code': [for (var i = 0; i < hours; i++) i == 3 ? 61 : 1],
    'precipitation_probability': [
      for (var i = 0; i < hours; i++) i == 3 ? 80 : 5,
    ],
  },
});

WeekSummary _week({int sessions = 1, double meters = 5200}) => (
  weekStart: DateTime(2026, 11, 16),
  weekEnd: DateTime(2026, 11, 22),
  totalDistanceMeters: meters,
  totalMovingTime: const Duration(minutes: 34),
  totalCalories: 300,
  sessionCount: sessions,
  targetSessions: 3,
  streakWeeks: 2,
  dailyBars: [
    for (var i = 0; i < 7; i++)
      (
        dayOfWeek: i + 1,
        dayLabel: StatsEngine.dayLabels[i],
        distanceKm: i == 0 ? 5.2 : 0,
        isToday: i == 6,
      ),
  ],
);

void main() {
  setUpAll(() async {
    await loadArchivo();
    await (FontLoader('Google Sans Flex')
          ..addFont(
            rootBundle.load('assets/fonts/GoogleSansFlex_24pt-Regular.ttf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/GoogleSansFlex_24pt-Black.ttf'),
          ))
        .load();
  });
  test('Nama kota memakai fallback kota dan kabupaten tanpa data rekaan', () {
    expect(
      cityFromReverseJson(
        '{"address":{"city":"Bandung","county":"Bandung Raya"}}',
      ),
      'Bandung',
    );
    expect(
      cityFromReverseJson('{"address":{"county":"Kabupaten Bogor"}}'),
      'Kabupaten Bogor',
    );
    expect(
      cityFromReverseJson('{"address":{"state_district":"Kota Bekasi"}}'),
      'Kota Bekasi',
    );
    expect(
      cityFromReverseJson('{"address":{"regency":"Aceh Utara"}}'),
      'Aceh Utara',
    );
    expect(cityFromReverseJson('{"address":{}}'), isNull);
  });

  test(
    'Parser BigDataCloud mendeteksi Lhokseumawe dan daerah kecamatan/kabupaten',
    () {
      expect(
        cityFromBigDataCloudJson(
          '{"city":"Lhokseumawe","locality":"Banda Sakti","principalSubdivision":"Aceh"}',
        ),
        'Lhokseumawe',
      );
      expect(
        cityFromBigDataCloudJson(
          '{"city":"","locality":"Dewantara","principalSubdivision":"Aceh","localityInfo":{"administrative":[{"adminLevel":4,"name":"Aceh"},{"adminLevel":5,"name":"Kabupaten Aceh Utara"}]}}',
        ),
        'Kabupaten Aceh Utara',
      );
      expect(
        cityFromBigDataCloudJson(
          '{"city":"","locality":"Banda Sakti","principalSubdivision":"Aceh"}',
        ),
        'Banda Sakti',
      );
      expect(cityFromBigDataCloudJson('{"city":""}'), isNull);
    },
  );
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Setiap animasi cuaca Meteocons dapat dibaca sebagai Lottie', () async {
    for (final kind in WeatherKind.values) {
      final bytes = await rootBundle.load(weatherAnimationAsset(kind));
      final composition = await LottieComposition.fromByteData(bytes);
      expect(composition.layers, isNotEmpty, reason: kind.name);
    }
  });

  test('Kode cuaca WMO dipetakan ke enam tampilan cuaca', () {
    expect(weatherKindFor(0), WeatherKind.clear);
    expect(weatherKindFor(1), WeatherKind.partlyCloudy);
    expect(weatherKindFor(2), WeatherKind.partlyCloudy);
    expect(weatherKindFor(3), WeatherKind.cloudy);
    expect(weatherKindFor(45), WeatherKind.cloudy);
    expect(weatherKindFor(48), WeatherKind.cloudy);
    expect(weatherKindFor(51), WeatherKind.rain);
    expect(weatherKindFor(65), WeatherKind.rain);
    expect(weatherKindFor(80), WeatherKind.rain);
    expect(weatherKindFor(75), WeatherKind.snow);
    expect(weatherKindFor(86), WeatherKind.snow);
    expect(weatherKindFor(95), WeatherKind.thunderstorm);
    expect(weatherKindFor(99), WeatherKind.thunderstorm);
    expect(weatherKindFor(999), WeatherKind.cloudy);
  });

  test('Jam basah ditandai oleh kode cuaca atau peluang hujan tinggi', () {
    expect(isWetHour(0, 5), isFalse);
    expect(isWetHour(1, 49), isFalse);
    expect(isWetHour(3, 80), isTrue);
    expect(isWetHour(61, 10), isTrue);
    expect(isWetHour(95, 0), isTrue);
  });

  test('Forecast 12 jam diterima dan data tidak lengkap ditolak', () {
    final forecast = parseWeatherForecast(_forecastBody());
    expect(forecast.temperature, 29.5);
    expect(forecast.hourly, hasLength(weatherForecastHours));
    expect(forecast.hourly[3].code, 61);
    expect(forecast.hourly[3].probability, 80);
    expect(
      () => parseWeatherForecast(_forecastBody(hours: 8)),
      throwsFormatException,
    );
  });

  test(
    'Salam mengikuti jam lokal dan nama depan diambil dari nama lengkap',
    () {
      expect(dayGreetingFor(6), DayGreeting.morning);
      expect(dayGreetingFor(13), DayGreeting.afternoon);
      expect(dayGreetingFor(17), DayGreeting.evening);
      expect(dayGreetingFor(22), DayGreeting.night);
      expect(firstNameOf('Renal Saputra'), 'Renal');
      expect(firstNameOf(''), '');
    },
  );

  test(
    'Jadwal ganda tersimpan terurut, punya ID unik, dan bisa dihapus',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = RunReminderStore(clock: () => DateTime(2026, 11, 20, 8));
      final first = await store.add(DateTime(2026, 11, 21, 6));
      final second = await store.add(DateTime(2026, 11, 20, 18));
      final third = await store.add(DateTime(2026, 11, 25, 6));
      expect({first.id, second.id, third.id}, hasLength(3));

      final loaded = await store.load();
      expect(
        [for (final reminder in loaded) reminder.time],
        [
          DateTime(2026, 11, 20, 18),
          DateTime(2026, 11, 21, 6),
          DateTime(2026, 11, 25, 6),
        ],
      );

      await store.remove(second.id);
      expect(
        [for (final reminder in await store.load()) reminder.id],
        [first.id, third.id],
      );

      final later = RunReminderStore(clock: () => DateTime(2026, 11, 26));
      expect(await later.load(), isEmpty);
    },
  );

  test('Jadwal dikelompokkan hari ini, besok, dan berikutnya', () {
    final now = DateTime(2026, 11, 20, 8);
    expect(
      reminderGroupFor(DateTime(2026, 11, 20, 20), now),
      ReminderGroup.today,
    );
    expect(
      reminderGroupFor(DateTime(2026, 11, 21, 6), now),
      ReminderGroup.tomorrow,
    );
    expect(
      reminderGroupFor(DateTime(2026, 11, 24, 6), now),
      ReminderGroup.later,
    );
  });

  testWidgets('Beranda menampilkan sapaan, piktogram cuaca, dan masuk jadwal', (
    tester,
  ) async {
    // Animasi dimatikan agar Lottie tidak berputar selamanya selama tes.
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
    );
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var started = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeClockProvider.overrideWithValue(() => DateTime(2026, 11, 20, 12)),
          weatherProvider.overrideWith(
            (ref) async => parseWeatherForecast(_forecastBody()),
          ),
          weekSummaryProvider.overrideWith((ref) async => _week()),
          latestRoutePointsProvider.overrideWith(
            (ref) async => const [
              (latitude: -6.2, longitude: 106.8),
              (latitude: -6.201, longitude: 106.802),
            ],
          ),
          recommendedSessionProvider.overrideWith(
            (ref) async => (
              title: 'Coba Pemula Santai',
              description: '20 menit interval ramah sendi.',
              preset: null,
              isFree: true,
            ),
          ),
          runReminderStoreProvider.overrideWithValue(RunReminderStore()),
          reminderSchedulerProvider.overrideWithValue(_FakeScheduler()),
          appUpdateServiceProvider.overrideWithValue(_NoUpdates()),
        ],
        child: componentHost(HomeDashboard(onStart: () => started = true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Selamat'), findsOneWidget);
    expect(find.textContaining('30°C'), findsOneWidget);
    expect(find.textContaining('Hujan'), findsOneWidget);
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/hero_weather_current.png'),
    );
    expect(find.text('Cek cuaca 12 jam ke depan'), findsNothing);
    expect(find.text('Rute terakhir'), findsNothing);
    expect(find.text('12 jam ke depan'), findsNothing);
    expect(find.byType(WeatherAnimation), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Cek cuaca 12 jam ke depan'));
    await tester.tap(find.byTooltip('Cek cuaca 12 jam ke depan'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold).last,
      matchesGoldenFile('goldens/weather_detail.png'),
    );
    expect(find.text('Kondisi cuaca'), findsOneWidget);
    expect(find.text('12 jam ke depan'), findsOneWidget);
    expect(find.text('Peluang hujan: 5%'), findsWidgets);
    Navigator.of(tester.element(find.byType(WeatherDetailScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Pengingat lari'), findsOneWidget);
    expect(find.text('Belum ada jadwal lari'), findsOneWidget);
    expect(find.text('1 dari 7 hari ada lari'), findsOneWidget);
    expect(find.text('Mulai berlari'), findsOneWidget);
    expect(find.text('Atur sesi ini'), findsOneWidget);

    await tester.ensureVisible(find.text('Mulai berlari'));
    await tester.tap(find.text('Mulai berlari'));
    expect(started, isTrue);
    expect(find.text('Jadwal lari terdekat'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(HomeDashboard)),
    );
    await container
        .read(runReminderStoreProvider)
        .add(DateTime.now().add(const Duration(days: 2)));
    await container
        .read(runReminderStoreProvider)
        .add(DateTime.now().add(const Duration(hours: 2)));
    container.invalidate(runRemindersProvider);
    await tester.pumpAndSettle();
    expect(find.text('Jadwal lari terdekat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Halaman jadwal menampilkan daftar dan bisa menghapus jadwal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final scheduler = _FakeScheduler();
    final now = DateTime.now();
    final store = RunReminderStore();
    await store.add(
      DateTime(now.year, now.month, now.day, 8).add(const Duration(days: 1)),
    );
    await store.add(
      DateTime(now.year, now.month, now.day, 8).add(const Duration(days: 5)),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeClockProvider.overrideWithValue(() => DateTime(2026, 11, 20, 12)),
          runReminderStoreProvider.overrideWithValue(store),
          reminderSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: componentHost(const RunRemindersScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Besok'), findsOneWidget);
    expect(find.text('Berikutnya'), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(scheduler.cancelled, hasLength(1));
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    expect(find.text('Jadwal dihapus.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Beranda tahan teks sistem 200% tanpa overflow', (tester) async {
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(() {
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue();
      tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue();
    });
    SharedPreferences.setMockInitialValues({});
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeClockProvider.overrideWithValue(() => DateTime(2026, 11, 20, 12)),
          weatherProvider.overrideWith(
            (ref) async => parseWeatherForecast(_forecastBody()),
          ),
          weekSummaryProvider.overrideWith(
            (ref) async => _week(sessions: 4, meters: 21300),
          ),
          latestRoutePointsProvider.overrideWith(
            (ref) async => const [
              (latitude: -6.2, longitude: 106.8),
              (latitude: -6.21, longitude: 106.81),
            ],
          ),
          recommendedSessionProvider.overrideWith(
            (ref) async => (
              title: 'Coba Pemula Santai',
              description: '20 menit interval ramah sendi.',
              preset: null,
              isFree: true,
            ),
          ),
          runReminderStoreProvider.overrideWithValue(RunReminderStore()),
          reminderSchedulerProvider.overrideWithValue(_FakeScheduler()),
          appUpdateServiceProvider.overrideWithValue(_NoUpdates()),
        ],
        child: componentHost(HomeDashboard(onStart: () {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Target minggu ini tuntas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
