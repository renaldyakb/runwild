import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/app/providers.dart';
import 'package:runwild/core/services/firebase_bootstrap.dart';
import 'package:runwild/features/foundation/presentation/backend_panel.dart';

import 'support.dart';

class ControlledBackend implements BackendInitializer {
  Completer<BackendStatus> result = Completer<BackendStatus>();
  int calls = 0;

  @override
  Future<BackendStatus> initialize() {
    calls++;
    return result.future;
  }
}

void main() {
  test(
    'No configuration stays local without calling native Firebase',
    () async {
      expect(await const FirebaseBootstrap().initialize(), BackendStatus.local);
    },
  );

  testWidgets('Bootstrap loading, failure and retry are visible and recover', (
    tester,
  ) async {
    final backend = ControlledBackend();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendInitializerProvider.overrideWithValue(backend)],
        child: componentHost(const BackendPanel()),
      ),
    );
    expect(find.text('Menghubungkan Firebase…'), findsOneWidget);
    backend.result.complete(BackendStatus.failed);
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Firebase belum bisa dihubungkan'),
      findsOneWidget,
    );
    backend.result = Completer<BackendStatus>();
    await tester.tap(find.text('Coba lagi'));
    await tester.pump();
    backend.result.complete(BackendStatus.ready);
    await tester.pumpAndSettle();
    expect(backend.calls, 2);
    expect(find.text('Firebase berhasil diinisialisasi.'), findsOneWidget);
  });

  testWidgets('Incomplete configuration has an actionable explanation', (
    tester,
  ) async {
    final backend = ControlledBackend()..result.complete(BackendStatus.invalid);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [backendInitializerProvider.overrideWithValue(backend)],
        child: componentHost(const BackendPanel()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Konfigurasi Firebase belum lengkap'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });
}
