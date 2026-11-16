import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/map_service.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';
import 'package:runwild/features/run/application/run_location.dart';

import 'support.dart';

class _Location implements RunLocation {
  final fixes = StreamController<GpsSample>();
  @override
  Stream<GpsSample> samples({
    required Duration Function() clock,
    required String notificationTitle,
    required String notificationText,
  }) => fixes.stream;
}

class _Tiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

Future<void> tap(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadArchivo);
  for (final scale in [1.0, 2.0]) {
    testWidgets('Live, route, history and controls reflow at $scale', (
      tester,
    ) async {
      final source = _Location();
      var now = Duration.zero;
      await pumpRunwild(
        tester,
        path: '/run/active',
        scale: scale,
        countdownClock: () => now,
        sessionClock: () => now,
        runLocation: source,
        mapService: OpenStreetMapService(tileProviderFactory: _Tiles.new),
      );
      now = const Duration(seconds: 3);
      await tester.pump(now);
      await tap(tester, 'Rute');
      expect(find.textContaining('Menunggu posisi GPS'), findsOneWidget);
      await tap(tester, 'Live');
      expect(tester.takeException(), isNull);
      if (scale == 1) {
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile('goldens/run_live.png'),
        );
      }
      await tap(tester, 'Riwayat');
      expect(find.text('Rekap sesi berjalan'), findsOneWidget);
      expect(
        find.text('Split muncul setelah ada jarak yang tercatat.'),
        findsOneWidget,
      );
      await tap(tester, 'Jeda');
      expect(find.text('Lanjut'), findsOneWidget);
      await tap(tester, 'Kunci kontrol');
      expect(find.text('Lanjut'), findsNothing);
      final hold = await tester.startGesture(
        tester.getCenter(find.text('Tahan 1 detik untuk membuka kunci')),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      await hold.up();
      await tester.pumpAndSettle();
      expect(find.text('Lanjut'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.fixes.close);
    });
  }

  testWidgets(
    'Map follows real fixes, pan stops following, recenter and lock work',
    (tester) async {
      final source = _Location();
      var now = Duration.zero;
      await pumpRunwild(
        tester,
        path: '/run/active',
        size: const Size(430, 932),
        countdownClock: () => now,
        sessionClock: () => now,
        runLocation: source,
        mapService: OpenStreetMapService(tileProviderFactory: _Tiles.new),
      );
      now = const Duration(seconds: 3);
      await tester.pump(now);
      source.fixes.add(
        GpsSample(
          latitude: -6.2,
          longitude: 106.8,
          accuracyMeters: 5,
          capturedAt: now,
        ),
      );
      await tester.pump();
      await tap(tester, 'Rute');
      expect(find.text('Akurasi GPS ±5 m'), findsOneWidget);
      expect(find.text('© OpenStreetMap contributors'), findsOneWidget);
      final controller = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController;
      if (controller == null) fail('Missing map controller');
      expect(controller.camera.center.latitude, closeTo(-6.2, 0.000001));
      now = const Duration(seconds: 5);
      source.fixes.add(
        GpsSample(
          latitude: -6.1999,
          longitude: 106.8,
          accuracyMeters: 5,
          capturedAt: now,
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.camera.center.latitude, closeTo(-6.1999, 0.000001));
      expect(
        tester
            .widget<PolylineLayer>(find.byType(PolylineLayer))
            .polylines
            .length,
        1,
      );
      await tester.ensureVisible(find.byType(FlutterMap));
      await tester.drag(find.byType(FlutterMap), const Offset(-60, 0));
      await tester.pumpAndSettle();
      expect(find.text('Pusatkan posisi'), findsOneWidget);
      await tap(tester, 'Pusatkan posisi');
      expect(controller.camera.center.latitude, closeTo(-6.1999, 0.000001));
      now = const Duration(seconds: 20);
      await tester.pump(const Duration(seconds: 1));
      expect(
        find.textContaining('Posisi terakhir belum diperbarui'),
        findsOneWidget,
      );
      await tap(tester, 'Kunci kontrol');
      expect(
        tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .options
            .interactionOptions
            .flags,
        InteractiveFlag.none,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.fixes.close);
    },
  );

  testWidgets(
    'Default OpenStreetMapService builds TileLayer without headers error',
    (tester) async {
      final source = _Location();
      var now = Duration.zero;
      await pumpRunwild(
        tester,
        path: '/run/active',
        countdownClock: () => now,
        sessionClock: () => now,
        runLocation: source,
      );
      now = const Duration(seconds: 3);
      await tester.pump(now);
      source.fixes.add(
        GpsSample(
          latitude: -6.2,
          longitude: 106.8,
          accuracyMeters: 5,
          capturedAt: now,
        ),
      );
      await tester.pump();
      await tap(tester, 'Rute');
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(source.fixes.close);
    },
  );
}
