import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/app/providers.dart';
import 'package:runwild/app/router.dart';
import 'package:runwild/app/runwild_app.dart';
import 'package:runwild/core/services/firebase_bootstrap.dart';
import 'package:runwild/core/services/map_service.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/domain/tracking/gps_calibration.dart';
import 'package:runwild/features/auth/application/auth_session.dart';
import 'package:runwild/features/foundation/application/weather_service.dart';
import 'package:runwild/features/onboarding/application/intro_preferences.dart';
import 'package:runwild/features/onboarding/presentation/startup_screen.dart';
import 'package:runwild/features/profile/application/initial_profile.dart';
import 'package:runwild/features/run/application/gps_calibration.dart';
import 'package:runwild/features/run/application/run_gps_probe.dart';
import 'package:runwild/features/run/application/run_journal.dart';
import 'package:runwild/features/run/application/run_location.dart';
import 'package:runwild/features/run/application/run_permissions.dart';
import 'package:runwild/features/run/presentation/run_active_screen.dart';
import 'package:runwild/features/run/presentation/run_recovery_screen.dart';
import 'package:runwild/l10n/generated/app_localizations.dart';

Future<void> loadArchivo() async {
  final loader = FontLoader('Archivo')
    ..addFont(rootBundle.load('assets/fonts/Archivo-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Archivo-Italic.ttf'));
  await loader.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

class LocalBackend implements BackendInitializer {
  @override
  Future<BackendStatus> initialize() async => BackendStatus.local;
}

Future<void> pumpRunwild(
  WidgetTester tester, {
  String path = '/',
  Size size = const Size(360, 640),
  double scale = 1,
  bool dark = false,
  IntroPreferences? introPreferences,
  AuthService? authService,
  InitialProfileRepository? profileRepository,
  RunPermissions? runPermissions,
  RunLocation? runLocation,
  Duration Function()? countdownClock,
  Duration Function()? sessionClock,
  MapService? mapService,
  String? runOwner,
  Future<RunCheckpoint?> Function()? pendingRun,
  GpsCalibrationStore? calibrationStore,
  GpsCalibrationSource? calibrationSource,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  tester.platformDispatcher.platformBrightnessTestValue = dark
      ? Brightness.dark
      : Brightness.light;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  final journal = RunJournal(NativeDatabase.memory());
  addTearDown(journal.close);
  final router = createRouter(initialLocation: path);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        runJournalProvider.overrideWithValue(journal),
        weatherProvider.overrideWith((ref) async => null),
        splashMinimumDurationProvider.overrideWithValue(Duration.zero),
        if (sessionClock != null)
          runClockFactoryProvider.overrideWithValue(() => sessionClock),
        if (mapService != null)
          mapServiceProvider.overrideWithValue(mapService),
        if (runOwner != null)
          runOwnerProvider.overrideWithValue(() => runOwner),
        if (pendingRun != null)
          pendingRunProvider.overrideWith((ref) => pendingRun()),
        if (runLocation != null)
          runLocationProvider.overrideWithValue(runLocation),
        if (countdownClock != null)
          runCountdownClockProvider.overrideWithValue(countdownClock),
        routerProvider.overrideWithValue(router),
        backendInitializerProvider.overrideWithValue(LocalBackend()),
        if (introPreferences != null)
          introPreferencesProvider.overrideWithValue(introPreferences),
        if (authService != null)
          authServiceProvider.overrideWith((ref) async => authService),
        initialProfileRepositoryProvider.overrideWithValue(
          profileRepository ?? _ExistingProfile(),
        ),
        if (runPermissions != null)
          runPermissionsProvider.overrideWithValue(runPermissions)
        else
          runPermissionsProvider.overrideWithValue(const _GrantedPermissions()),
        gpsCalibrationStoreProvider.overrideWithValue(
          calibrationStore ?? _RecentCalibrationStore(),
        ),
        gpsCalibrationSourceProvider.overrideWithValue(
          calibrationSource ?? const _IdleCalibrationSource(),
        ),
      ],
      child: const RunwildApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _ExistingProfile implements InitialProfileRepository {
  @override
  Future<bool> exists() async => true;

  @override
  Future<void> save({
    required String name,
    required ProfileGoal goal,
    required ProfileLevel level,
    required int sessions,
  }) async {}
}

class _RecentCalibrationStore implements GpsCalibrationStore {
  @override
  Future<GpsCalibrationRecord?> read() async => (
    calibratedAt: DateTime.now(),
    grade: GpsCalibrationGrade.good,
    medianAccuracyMeters: 6.0,
  );

  @override
  Future<void> save(GpsCalibrationRecord record) async {}
}

class _IdleCalibrationSource implements GpsCalibrationSource {
  const _IdleCalibrationSource();

  @override
  Stream<GpsCalibrationSample> samples() =>
      Stream<GpsCalibrationSample>.empty();
}

class _GrantedPermissions implements RunPermissions {
  const _GrantedPermissions();

  @override
  Future<RunPermissionStatus> status(RunPermission permission) async =>
      RunPermissionStatus.granted;

  @override
  Future<RunPermissionStatus> request(RunPermission permission) async =>
      RunPermissionStatus.granted;

  @override
  Future<bool> openSettings() async => true;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}

Widget componentHost(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? RwTheme.dark : RwTheme.light,
  locale: const Locale('id'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);
