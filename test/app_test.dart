import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/components/rw_chip.dart';
import 'package:runwild/design/components/rw_state_view.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadArchivo);

  for (final size in [const Size(360, 640), const Size(430, 932)]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets('Shell and catalog ${size.width} $scale dark=$dark', (
          tester,
        ) async {
          await pumpRunwild(tester, size: size, scale: scale, dark: dark);
          expect(find.text('Kejar jarakmu.'), findsOneWidget);
          expect(tester.takeException(), isNull);
          for (final (label, heading) in [
            ('Aktivitas', 'Riwayat aktivitas'),
            ('Profil', 'Profil belum tersedia'),
          ]) {
            await tester.tap(find.text(label));
            await tester.pumpAndSettle();
            expect(find.text(heading), findsOneWidget);
            expect(tester.takeException(), isNull);
          }
          await tester.tap(find.text('Lari'));
          await tester.pumpAndSettle();
          expect(find.text('Persiapan lari'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.text('Tutup'));
          await tester.tap(find.text('Tutup'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Home'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Profil'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Buka katalog komponen'));
          await tester.tap(find.text('Buka katalog komponen'));
          await tester.pumpAndSettle();
          expect(find.text('Katalog komponen'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await tester.ensureVisible(find.byType(RwStateView));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Home'));
          await tester.pumpAndSettle();
          expect(find.text('Kejar jarakmu.'), findsOneWidget);
        });
      }
    }
  }

  testWidgets(
    'Catalog click-through: light-only app, feedback, dialog, choices and states',
    (tester) async {
      await pumpRunwild(tester, path: '/catalog');
      for (final theme in ['Gelap', 'Terang', 'Sistem']) {
        await tester.ensureVisible(find.text(theme));
        await tester.tap(find.text(theme));
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(Scaffold).first);
        expect(Theme.of(context).brightness, Brightness.light);
      }
      await tester.ensureVisible(find.text('Coba tombol utama'));
      await tester.tap(find.text('Coba tombol utama'));
      await tester.pumpAndSettle();
      expect(find.text('Tombol utama berfungsi.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.ensureVisible(find.text('Buka contoh dialog'));
      await tester.tap(find.text('Buka contoh dialog'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      for (final label in ['Interval', 'Bebas']) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        final chip = tester.widget<ChoiceChip>(
          find.descendant(
            of: find.widgetWithText(RwChip, label),
            matching: find.byType(ChoiceChip),
          ),
        );
        expect(chip.selected, isTrue);
      }
      for (final (label, content) in [
        ('Memuat', 'Memuat aktivitas…'),
        ('Gagal', 'Aktivitas belum bisa dimuat'),
        ('Offline', 'Kamu sedang offline'),
        ('Konten', 'Komponen siap diperiksa'),
        ('Kosong', 'Belum ada aktivitas'),
      ]) {
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(find.text(content), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (label == 'Gagal' || label == 'Offline') {
          await tester.ensureVisible(find.text('Coba lagi'));
          await tester.tap(find.text('Coba lagi'));
          await tester.pumpAndSettle();
          expect(find.text('Komponen siap diperiksa'), findsOneWidget);
        }
      }
      await tester.ensureVisible(find.text('Persiapan lari'));
      await tester.tap(find.text('Persiapan lari'));
      await tester.pumpAndSettle();
      expect(find.text('Pelacakan belum tersedia'), findsOneWidget);
      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Pelacakan belum tersedia'), findsNothing);
    },
  );

  testWidgets('Unknown route recovers to Home', (tester) async {
    await pumpRunwild(tester, path: '/missing');
    expect(find.text('Layar tidak ditemukan'), findsOneWidget);
    await tester.tap(find.text('Kembali ke Home'));
    await tester.pumpAndSettle();
    expect(find.text('Kejar jarakmu.'), findsOneWidget);
  });
}
