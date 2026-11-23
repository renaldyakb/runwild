import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/features/onboarding/application/intro_preferences.dart';
import 'package:runwild/features/onboarding/presentation/startup_screen.dart';

import 'support.dart';

class _IntroStore implements IntroPreferences {
  bool completed = false;
  bool failRead = false;
  bool failWrite = false;

  @override
  Future<bool> isComplete() async {
    if (failRead) throw Exception('read failed');
    return completed;
  }

  @override
  Future<void> complete() async {
    if (failWrite) throw Exception('write failed');
    completed = true;
  }
}

void main() {
  testWidgets('Startup pertama menampilkan intro lalu layar mulai', (
    tester,
  ) async {
    final store = _IntroStore();
    await pumpRunwild(tester, path: '/splash', introPreferences: store);
    expect(find.text('LARI'), findsOneWidget);
    expect(find.text('Langkah 1 dari 3'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('LACAK'), findsOneWidget);
    expect(find.text('Langkah 2 dari 3'), findsOneWidget);
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('BERKEMBANG'), findsOneWidget);
    expect(find.text('Langkah 3 dari 3'), findsOneWidget);
    await tester.tap(find.text('Lanjut ke layar mulai'));
    await tester.pumpAndSettle();
    expect(store.completed, isTrue);
    expect(find.text('SIAP BERGERAK?'), findsOneWidget);
    await tester.tap(find.text('Mulai Sekarang'));
    await tester.pumpAndSettle();
    expect(find.text('Daftar'), findsOneWidget);
  });

  testWidgets('Lewati tetap bisa dijangkau pada teks 200%', (tester) async {
    final store = _IntroStore();
    await pumpRunwild(
      tester,
      path: '/intro',
      scale: 2,
      dark: true,
      introPreferences: store,
    );
    final skip = find.text('Lewati');
    await tester.ensureVisible(skip);
    await tester.tap(skip);
    await tester.pumpAndSettle();
    expect(store.completed, isTrue);
    expect(find.text('SIAP BERGERAK?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpRunwild(tester, path: '/splash', introPreferences: store);
    await tester.pumpAndSettle();
    expect(find.text('SIAP BERGERAK?'), findsOneWidget);
    expect(find.text('LARI'), findsNothing);
  });

  testWidgets('Kesalahan penyimpanan bisa dicoba ulang', (tester) async {
    final store = _IntroStore()..failRead = true;
    await pumpRunwild(tester, path: '/splash', introPreferences: store);
    expect(find.text('Status pengenalan belum bisa dibaca.'), findsOneWidget);
    store.failRead = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    store.failWrite = true;
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(
      find.text('Progres pengenalan belum tersimpan. Coba lagi.'),
      findsOneWidget,
    );
    expect(store.completed, isFalse);
    store.failWrite = false;
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    expect(find.text('SIAP BERGERAK?'), findsOneWidget);
  });

  test('Aset Lottie Splash valid dan dapat di-parse', () async {
    final bytes = await File(splashLottieAsset).readAsBytes();
    final composition = await LottieComposition.fromBytes(bytes);
    expect(composition.duration, greaterThan(Duration.zero));
    expect(composition.bounds.width, 240);
  });
}
