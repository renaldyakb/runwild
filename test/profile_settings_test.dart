import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/components/rw_button.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/features/profile/application/initial_profile.dart';
import 'package:runwild/features/profile/application/profile_service.dart';
import 'package:runwild/features/profile/domain/user_profile.dart';
import 'package:runwild/features/profile/presentation/profile_screen.dart';
import 'package:runwild/features/run/application/run_journal.dart';
import 'package:runwild/l10n/generated/app_localizations.dart';

Widget _testHost(Widget child) => MaterialApp(
  theme: RwTheme.light,
  locale: const Locale('id'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: child,
);

class _FakeProfileRepository implements ProfileRepository {
  UserProfile? profile = const UserProfile(
    displayName: 'Budi Santoso',
    email: 'budi@example.com',
    level: ProfileLevel.pemula,
    goal: ProfileGoal.sehat,
    units: 'km',
    weeklyGoalSessions: 3,
  );

  bool updateCalled = false;
  bool deleteCalled = false;
  UserProfile? lastUpdatedProfile;

  @override
  Future<UserProfile?> fetchProfile(String uid) async => profile;

  @override
  Future<void> updateProfile(String uid, UserProfile updated) async {
    updateCalled = true;
    lastUpdatedProfile = updated;
    profile = updated;
  }

  @override
  Future<void> deleteAccount(String uid) async {
    deleteCalled = true;
    profile = null;
  }
}

void main() {
  group('UserProfile model tests', () {
    test('serializes to and from Firestore map accurately', () {
      const profile = UserProfile(
        displayName: 'Ahmad Pelari',
        email: 'ahmad@example.com',
        level: ProfileLevel.rutin,
        goal: ProfileGoal.lari5k,
        units: 'km',
        weeklyGoalSessions: 4,
        privacy: UserPrivacySettings(
          hideStartEnd: true,
          trimMeters: 200,
          defaultVisibility: 'private',
        ),
        voice: UserVoiceSettings(
          enabled: true,
          volume: 0.9,
          haptics: true,
          countdownCue: true,
          roundCue: true,
        ),
        autoPause: true,
      );

      final map = profile.toFirestoreMap();
      expect(map['displayName'], 'Ahmad Pelari');
      expect(map['email'], 'ahmad@example.com');
      expect(map['level'], 'rutin');
      expect(map['goal'], 'lari_5k');
      expect(map['units'], 'km');
      expect(map['weeklyGoal']['target'], 4);
      expect(map['privacy']['hideStartEnd'], isTrue);
      expect(map['voice']['volume'], 0.9);
      expect(map['autoPause'], isTrue);

      final reconstructed = UserProfile.fromFirestore(map);
      expect(reconstructed.displayName, 'Ahmad Pelari');
      expect(reconstructed.level, ProfileLevel.rutin);
      expect(reconstructed.goal, ProfileGoal.lari5k);
      expect(reconstructed.weeklyGoalSessions, 4);
      expect(reconstructed.voice.volume, 0.9);
    });

    test('copyWith modifies individual fields properly', () {
      const base = UserProfile(
        displayName: 'Base',
        email: 'base@test.com',
        level: ProfileLevel.pemula,
        goal: ProfileGoal.sehat,
      );

      final updated = base.copyWith(
        displayName: 'Updated Name',
        weeklyGoalSessions: 5,
        autoPause: false,
      );

      expect(updated.displayName, 'Updated Name');
      expect(updated.email, 'base@test.com');
      expect(updated.weeklyGoalSessions, 5);
      expect(updated.autoPause, isFalse);
    });
  });

  group('RunJournal purgeUserData test', () {
    late RunJournal journal;

    setUp(() {
      journal = RunJournal(NativeDatabase.memory());
    });

    tearDown(() async {
      await journal.close();
    });

    test(
      'purgeUserData purges sessions, points and presets of target user',
      () async {
        const owner = 'user-to-delete';
        const otherUser = 'user-keep';

        // Insert session & preset for target user
        final sessionId = await journal.customInsert(
          'INSERT INTO run_sessions (owner, started_ms, meters, moving_us, elapsed_us, points, finished, synced) '
          'VALUES (?, 1000, 1000, 60000, 60000, 1, 1, 1)',
          variables: [Variable(owner)],
        );
        await journal.customInsert(
          'INSERT INTO run_points (session_id, seq, captured_us, latitude, longitude, accuracy, segment_start) '
          'VALUES (?, 1, 1000, -6.2, 106.8, 5.0, 1)',
          variables: [Variable(sessionId)],
        );
        await journal.customInsert(
          'INSERT INTO interval_presets (owner, name, config) VALUES (?, ?, ?)',
          variables: [Variable(owner), Variable('Preset 1'), Variable('{}')],
        );

        // Insert session for other user
        await journal.customInsert(
          'INSERT INTO run_sessions (owner, started_ms, meters, moving_us, elapsed_us, points, finished, synced) '
          'VALUES (?, 2000, 2000, 120000, 120000, 1, 1, 1)',
          variables: [Variable(otherUser)],
        );

        // Purge target user
        await journal.purgeUserData(owner);

        // Verify target user data is empty
        final targetSessions = await journal.allFinishedSessions(owner);
        expect(targetSessions, isEmpty);

        final targetPoints = await journal.sessionPoints(
          sessionId,
          owner: owner,
        );
        expect(targetPoints, isEmpty);

        // Verify other user data is preserved
        final otherSessions = await journal.allFinishedSessions(otherUser);
        expect(otherSessions.length, 1);
      },
    );
  });

  group('ProfileScreen widget tests', () {
    late _FakeProfileRepository fakeRepo;

    setUp(() {
      fakeRepo = _FakeProfileRepository();
    });

    testWidgets('Renders all profile sections and updates displayName', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileUserProvider.overrideWithValue((
              uid: 'uid-1',
              email: 'budi@example.com',
              displayName: 'Budi Santoso',
            )),
            profileRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileProvider.overrideWith(
              (ref) => fakeRepo.fetchProfile('uid-1'),
            ),
          ],
          child: _testHost(const ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Header Profil
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('budi@example.com'), findsOneWidget);
      expect(find.text('PELARI PEMULA'), findsOneWidget);

      // Sections
      expect(find.text('DATA DIRI & TARGET'), findsOneWidget);
      expect(find.text('PREFERENSI LARI & SUARA'), findsOneWidget);
      expect(find.text('PRIVASI SESI'), findsOneWidget);
      expect(find.text('AKUN & KEAMANAN'), findsOneWidget);

      // Edit name dialog
      final editIcon = find.byTooltip('Ubah nama');
      expect(editIcon, findsOneWidget);
      await tester.tap(editIcon);
      await tester.pumpAndSettle();

      expect(find.text('Ubah Nama Pelari'), findsOneWidget);
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Budi Champion');

      final saveButton = find.widgetWithText(FilledButton, 'Simpan');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(fakeRepo.updateCalled, isTrue);
      expect(fakeRepo.lastUpdatedProfile?.displayName, 'Budi Champion');
    });

    testWidgets('Double confirmation delete account flow works', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentProfileUserProvider.overrideWithValue((
              uid: 'uid-1',
              email: 'budi@example.com',
              displayName: 'Budi Santoso',
            )),
            profileRepositoryProvider.overrideWithValue(fakeRepo),
            userProfileProvider.overrideWith(
              (ref) => fakeRepo.fetchProfile('uid-1'),
            ),
          ],
          child: _testHost(const ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Temukan tombol Hapus Akun di Danger Zone
      final deleteAccountButton = find.widgetWithText(RwButton, 'Hapus Akun');
      expect(deleteAccountButton, findsOneWidget);

      await tester.scrollUntilVisible(deleteAccountButton, 100);
      await tester.tap(deleteAccountButton);
      await tester.pumpAndSettle();

      // Dialog Konfirmasi 1
      expect(find.text('Hapus Akun Permanen?'), findsOneWidget);
      final lanjutButton = find.widgetWithText(FilledButton, 'Lanjut');
      await tester.tap(lanjutButton);
      await tester.pumpAndSettle();

      // Dialog Konfirmasi 2 (Ketik HAPUS)
      expect(find.text('Konfirmasi Penghapusan'), findsOneWidget);
      expect(
        find.text('Ketik HAPUS untuk melanjutkan penghapusan akun:'),
        findsOneWidget,
      );

      final finalDeleteButton = find.widgetWithText(
        FilledButton,
        'HAPUS AKUN SAYA',
      );
      expect(finalDeleteButton, findsOneWidget);

      // Tombol masih disable sebelum mengetik HAPUS
      final filledBtn = tester.widget<FilledButton>(finalDeleteButton);
      expect(filledBtn.enabled, isFalse);

      // Ketik kata yang salah
      final deleteInput = find.byType(TextField);
      await tester.enterText(deleteInput, 'batal');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(finalDeleteButton).enabled, isFalse);

      // Ketik HAPUS
      await tester.enterText(deleteInput, 'HAPUS');
      await tester.pumpAndSettle();
      expect(tester.widget<FilledButton>(finalDeleteButton).enabled, isTrue);
    });
  });
}
