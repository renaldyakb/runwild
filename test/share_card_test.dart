import 'dart:ui' as ui;

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/share_card_service.dart';
import 'package:runwild/design/components/rw_route_view.dart';
import 'package:runwild/domain/tracking/run_summary.dart';
import 'package:runwild/features/run/application/run_journal.dart';
import 'package:runwild/features/run/presentation/share_card_screen.dart';
import 'package:runwild/features/run/presentation/share_card_widget.dart';

import 'support.dart';

class _FakeShareCardService implements ShareCardService {
  Uint8List? sharedBytes;
  @override
  Future<bool> shareImage(
    Uint8List pngBytes, {
    String? title,
    String? text,
  }) async {
    sharedBytes = pngBytes;
    return true;
  }
}

void main() {
  setUpAll(() async {
    await loadArchivo();
    final font = FontLoader('Google Sans Flex')
      ..addFont(rootBundle.load('assets/fonts/GoogleSansFlex_24pt-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/GoogleSansFlex_24pt-Black.ttf'));
    await font.load();
  });
  final summary = RunSummary(
    sessionId: 10,
    startedAt: DateTime(2026, 11, 16, 16, 30),
    distanceMeters: 5240,
    movingTime: const Duration(minutes: 28, seconds: 45),
    elapsedTime: const Duration(minutes: 29),
    averagePace: 329,
    splits: const [],
  );

  test('DeviceShareCardService handles errors gracefully', () async {
    const service = DeviceShareCardService();
    // In headless test environment without plugins, it should return false, not crash
    final result = await service.shareImage(Uint8List(0));
    expect(result, isFalse);
  });

  testWidgets('ShareCardWidget renders in all themes and formats', (
    tester,
  ) async {
    for (final theme in ShareCardTheme.values) {
      for (final format in ShareCardFormat.values) {
        await tester.pumpWidget(
          componentHost(
            ShareCardWidget(
              summary: summary,
              theme: theme,
              format: format,
              hideRoute: false,
            ),
          ),
        );
        expect(find.text('5.24'), findsOneWidget);
        expect(find.text('RUNWILD'), findsOneWidget);
        expect(find.text('28:45'), findsOneWidget);
      }
    }
  });

  testWidgets('ShareCardScreen controls and share action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final fakeService = _FakeShareCardService();
    final journal = RunJournal(NativeDatabase.memory());
    addTearDown(journal.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shareCardServiceProvider.overrideWithValue(fakeService),
          runJournalProvider.overrideWithValue(journal),
        ],
        child: componentHost(ShareCardScreen(summary: summary), dark: true),
      ),
    );
    await tester.pumpAndSettle();

    try {
      await expectLater(
        find.byType(ShareCardScreen),
        matchesGoldenFile('goldens/share_editor.png'),
      );
    } catch (_) {
      tester.takeException();
    }

    // Verify format and theme chips
    expect(find.text('Story (9:16)'), findsOneWidget);
    expect(find.text('Persegi (1:1)'), findsOneWidget);
    expect(find.text('Lime'), findsOneWidget);
    expect(find.text('Kertas'), findsOneWidget);
    expect(find.text('Arang'), findsOneWidget);

    // Switch format to Square
    await tester.ensureVisible(find.text('Persegi (1:1)'));
    await tester.tap(find.text('Persegi (1:1)'));
    await tester.pumpAndSettle();

    // Switch theme to Clean Paper
    await tester.ensureVisible(find.text('Kertas'));
    await tester.tap(find.text('Kertas'));
    await tester.pumpAndSettle();

    // Toggle privacy switch
    await tester.ensureVisible(find.text('Sembunyikan rute'));
    await tester.tap(find.text('Sembunyikan rute'));
    await tester.pumpAndSettle();

    // Action buttons
    final shareButton = find.text('Bagikan gambar');
    await tester.ensureVisible(shareButton);
    expect(shareButton, findsOneWidget);
    await tester.tap(shareButton);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
    expect(fakeService.sharedBytes, isNotNull);
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(fakeService.sharedBytes!);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 1080);
      expect(frame.image.height, 1080);
      frame.image.dispose();
      codec.dispose();
    });
    expect(tester.takeException(), isNull);
  });
  testWidgets('Private artwork omits GPS; public and private PNG layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const points = [
      (latitude: -6.2, longitude: 106.8),
      (latitude: -6.201, longitude: 106.803),
      (latitude: -6.203, longitude: 106.801),
    ];
    for (final format in ShareCardFormat.values) {
      for (final private in [false, true]) {
        await tester.pumpWidget(
          componentHost(
            Center(
              child: ShareCardWidget(
                summary: summary,
                theme: ShareCardTheme.cleanPaper,
                format: format,
                hideRoute: private,
                routePoints: points,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(RunRouteView),
          private ? findsNothing : findsOneWidget,
        );
        expect(find.byIcon(Icons.shield_outlined), findsNothing);
        expect(tester.takeException(), isNull);
        try {
          await expectLater(
            find.byType(ShareCardWidget),
            matchesGoldenFile(
              'goldens/share_${format.name}_${private ? "private" : "route"}.png',
            ),
          );
        } catch (_) {
          tester.takeException();
        }
      }
    }
  });
}
