import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/features/profile/application/initial_profile.dart';

import 'support.dart';

class _NewProfile implements InitialProfileRepository {
  bool failRead = false;
  bool failSave = false;
  (String, ProfileGoal, ProfileLevel, int)? saved;

  @override
  Future<bool> exists() async {
    if (failRead) throw Exception('offline');
    return saved != null;
  }

  @override
  Future<void> save({
    required String name,
    required ProfileGoal goal,
    required ProfileLevel level,
    required int sessions,
  }) async {
    if (failSave) throw Exception('offline');
    saved = (name, goal, level, sessions);
  }
}

void main() {
  testWidgets('Profil baru wajib bernama dan menyimpan pilihan pengguna', (
    tester,
  ) async {
    final profile = _NewProfile();
    await pumpRunwild(
      tester,
      path: '/profile/setup',
      profileRepository: profile,
      dark: true,
      scale: 2,
    );
    final save = find.text('Simpan profil');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(profile.saved, isNull);
    final name = find.byType(TextFormField);
    await tester.ensureVisible(name);
    expect(find.text('Masukkan nama panggilan.'), findsOneWidget);
    await tester.enterText(name, '  Rena  ');
    for (final item in [
      find.text('Lari 5 km'),
      find.text('Mulai lagi'),
      find.byTooltip('Tambah sesi'),
    ]) {
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(profile.saved, (
      'Rena',
      ProfileGoal.lari5k,
      ProfileLevel.kembali,
      4,
    ));
    expect(find.text('Kejar jarakmu.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Baca dan simpan bisa dicoba lagi tanpa kehilangan isian', (
    tester,
  ) async {
    final profile = _NewProfile()..failRead = true;
    await pumpRunwild(
      tester,
      path: '/profile/setup',
      profileRepository: profile,
    );
    expect(find.textContaining('Profil belum bisa diperiksa'), findsOneWidget);
    profile.failRead = false;
    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Rena');
    profile.failSave = true;
    final save = find.text('Simpan profil');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.textContaining('Profil belum tersimpan'), findsOneWidget);
    expect(find.text('Rena'), findsOneWidget);
    profile.failSave = false;
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Kejar jarakmu.'), findsOneWidget);
  });
}
