import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/domain/tracking/gps_calibration.dart';
import 'package:runwild/features/run/application/gps_calibration.dart';
import 'package:runwild/features/run/presentation/gps_calibration_sheet.dart';
import 'package:runwild/l10n/generated/app_localizations.dart';

Widget _host(Widget child) => MaterialApp(
  theme: RwTheme.light,
  locale: const Locale('id'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: child,
    ),
  ),
);

class _Source implements GpsCalibrationSource {
  final controller = StreamController<GpsCalibrationSample>();

  @override
  Stream<GpsCalibrationSample> samples() => controller.stream;
}

class _Store implements GpsCalibrationStore {
  GpsCalibrationRecord? saved;
  int saves = 0;

  @override
  Future<GpsCalibrationRecord?> read() async => null;

  @override
  Future<void> save(GpsCalibrationRecord record) async {
    saved = record;
    saves++;
  }
}

void main() {
  testWidgets('good measurement shows the result and stores the record', (
    tester,
  ) async {
    final source = _Source();
    final store = _Store();
    addTearDown(source.controller.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gpsCalibrationSourceProvider.overrideWithValue(source),
          gpsCalibrationStoreProvider.overrideWithValue(store),
        ],
        child: _host(const GpsCalibrationSheet()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5));

    for (var i = 0; i < 13; i++) {
      source.controller.add((
        latitude: -6.2,
        longitude: 106.8,
        accuracyMeters: 5 + (i % 3).toDouble(),
        capturedAt: Duration(seconds: i),
      ));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();

    expect(find.text('Sinyal GPS bagus'), findsOneWidget);
    expect(find.textContaining('Akurasi ±'), findsOneWidget);
    expect(store.saves, 1);
    expect(store.saved?.grade, GpsCalibrationGrade.good);
  });

  testWidgets('disabled location service explains the next action', (
    tester,
  ) async {
    final source = _Source();
    addTearDown(source.controller.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gpsCalibrationSourceProvider.overrideWithValue(source),
          gpsCalibrationStoreProvider.overrideWithValue(_Store()),
        ],
        child: _host(const GpsCalibrationSheet()),
      ),
    );
    await tester.pump();

    source.controller.addError(const LocationServiceDisabledException());
    await tester.pumpAndSettle();

    expect(find.textContaining('Lokasi perangkat mati'), findsOneWidget);
    expect(find.text('Hidupkan lokasi'), findsOneWidget);
  });
}
