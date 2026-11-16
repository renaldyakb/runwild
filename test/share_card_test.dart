import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/share_card_service.dart';
import 'package:runwild/domain/tracking/run_summary.dart';
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
          Directionality(
            textDirection: TextDirection.ltr,
            child: ShareCardWidget(
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
    final fakeService = _FakeShareCardService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [shareCardServiceProvider.overrideWithValue(fakeService)],
        child: componentHost(ShareCardScreen(summary: summary), dark: true),
      ),
    );
    await tester.pumpAndSettle();

    // Verify format and theme chips
    expect(find.text('Story (9:16)'), findsOneWidget);
    expect(find.text('Persegi (1:1)'), findsOneWidget);
    expect(find.text('⚡ Prime Lime'), findsOneWidget);
    expect(find.text('📄 Kertas Bersih'), findsOneWidget);
    expect(find.text('⬛ Bold Charcoal'), findsOneWidget);

    // Switch format to Square
    await tester.tap(find.text('Persegi (1:1)'));
    await tester.pumpAndSettle();

    // Switch theme to Clean Paper
    await tester.tap(find.text('📄 Kertas Bersih'));
    await tester.pumpAndSettle();

    // Toggle privacy switch
    await tester.tap(find.text('Sembunyikan privasi rute'));
    await tester.pumpAndSettle();

    // Action buttons
    final shareButton = find.text('Bagikan Gambar');
    await tester.ensureVisible(shareButton);
    expect(shareButton, findsOneWidget);
    expect(find.text('Tutup'), findsOneWidget);
  });
}
