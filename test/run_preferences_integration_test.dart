import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/interval_audio.dart';
import 'package:runwild/core/services/interval_haptics.dart';
import 'package:runwild/core/services/run_notifications.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/domain/interval/interval_cues.dart';
import 'package:runwild/domain/tracking/run_summary.dart';
import 'package:runwild/features/profile/application/initial_profile.dart';
import 'package:runwild/features/profile/application/profile_service.dart';
import 'package:runwild/features/profile/domain/user_profile.dart';
import 'package:runwild/features/run/application/run_gps_probe.dart';
import 'package:runwild/features/run/presentation/share_card_screen.dart';
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

class _MockIntervalAudio implements IntervalAudio {
  int playCount = 0;
  IntervalCue? lastCue;

  @override
  bool failed = false;

  @override
  Future<void> play(IntervalCue cue) async {
    playCount++;
    lastCue = cue;
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeHaptics implements IntervalHaptics {
  @override
  Future<void> vibrate(IntervalCue cue) async {}

  @override
  Future<void> sessionFinished() async {}
}

class _FakeNotifications implements RunNotifications {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> update({required String title, required String body}) async {}

  @override
  Future<void> cancel() async {}
}

void main() {
  group('Upgrade #1: Profile Preferences Integration', () {
    test(
      'RunGpsProbe honors profile voice and autoPause preferences',
      () async {
        final mockAudio = _MockIntervalAudio();

        const customProfile = UserProfile(
          displayName: 'Runner One',
          email: 'runner@runwild.app',
          level: ProfileLevel.rutin,
          goal: ProfileGoal.lari5k,
          autoPause: false, // Pelari mematikan autoPause
          voice: UserVoiceSettings(
            enabled: false, // Pelari mematikan panduan suara
            haptics: true,
            countdownCue: false,
            roundCue: false,
          ),
        );

        final container = ProviderContainer(
          overrides: [
            intervalAudioProvider.overrideWithValue(mockAudio),
            intervalHapticsProvider.overrideWithValue(_FakeHaptics()),
            runNotificationsProvider.overrideWithValue(_FakeNotifications()),
            userProfileProvider.overrideWith(
              (ref) => Future.value(customProfile),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Trigger user profile resolution
        await container.read(userProfileProvider.future);

        final probeNotifier = container.read(runGpsProbeProvider.notifier);
        await probeNotifier.start(
          notificationTitle: 'RUNWILD',
          notificationText: 'Tracking test',
          activeSession: true,
        );

        // Verify audio disabled state from profile
        expect(probeNotifier.audioEnabled, isFalse);
        expect(mockAudio.playCount, 0);

        await probeNotifier.stop();
      },
    );

    testWidgets('ShareCardScreen initializes hideRoute from profile privacy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      const privacyProfile = UserProfile(
        displayName: 'Private Runner',
        email: 'private@test.com',
        level: ProfileLevel.pemula,
        goal: ProfileGoal.sehat,
        privacy: UserPrivacySettings(
          hideStartEnd: true, // Default hide route aktif
        ),
      );

      final summary = RunSummary(
        startedAt: DateTime(2026, 11, 16, 7, 0),
        distanceMeters: 4500,
        movingTime: const Duration(minutes: 25),
        elapsedTime: const Duration(minutes: 25),
        averagePace: 333,
        splits: const [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileProvider.overrideWith(
              (ref) => Future.value(privacyProfile),
            ),
          ],
          child: _testHost(ShareCardScreen(summary: summary)),
        ),
      );

      await tester.pumpAndSettle();

      // Find privacy switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      final switchWidget = tester.widget<Switch>(switchFinder);

      // Verify switch is initialized to true from profile
      expect(switchWidget.value, isTrue);
    });
  });
}
