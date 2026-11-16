import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/core/services/interval_audio.dart';
import 'package:runwild/core/services/interval_haptics.dart';
import 'package:runwild/core/services/run_notifications.dart';
import 'package:runwild/domain/interval/interval_cues.dart';
import 'package:runwild/domain/interval/interval_engine.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';
import 'package:runwild/features/run/application/interval_selection.dart';
import 'package:runwild/features/run/application/run_gps_probe.dart';
import 'package:runwild/features/run/application/run_journal.dart';
import 'package:runwild/features/run/application/run_location.dart';

class _FakeHaptics implements IntervalHaptics {
  final cues = <IntervalCue>[];
  var finishedCalls = 0;

  @override
  Future<void> vibrate(IntervalCue cue) async {
    cues.add(cue);
  }

  @override
  Future<void> sessionFinished() async {
    finishedCalls++;
  }
}

class _FakeNotifications implements RunNotifications {
  final updates = <({String title, String body})>[];
  var cancelCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> update({required String title, required String body}) async {
    updates.add((title: title, body: body));
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}

class _FakeAudio implements IntervalAudio {
  final cues = <IntervalCue>[];
  @override
  bool failed = false;

  @override
  Future<void> play(IntervalCue cue) async {
    cues.add(cue);
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {}
}

class _FakeLocation implements RunLocation {
  final fixes = StreamController<GpsSample>.broadcast();

  @override
  Stream<GpsSample> samples({
    required Duration Function() clock,
    required String notificationTitle,
    required String notificationText,
  }) {
    return fixes.stream;
  }
}

class _PresetSelection extends IntervalSelection {
  _PresetSelection(this._initial);
  final IntervalConfig _initial;

  @override
  IntervalConfig? build() => _initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DeviceIntervalHaptics runs without throwing', () async {
    const haptics = DeviceIntervalHaptics(delay: Duration.zero);
    for (final cue in IntervalCue.values) {
      await expectLater(haptics.vibrate(cue), completes);
    }
    await expectLater(haptics.sessionFinished(), completes);
  });

  test('RunGpsProbe triggers haptics independently of audio', () async {
    final haptics = _FakeHaptics();
    final audio = _FakeAudio();
    final notifications = _FakeNotifications();
    final location = _FakeLocation();
    addTearDown(location.fixes.close);
    var now = const Duration(seconds: 3);

    const config = (
      warmup: Duration(seconds: 10),
      run: Duration(seconds: 10),
      walk: Duration(seconds: 10),
      rounds: 1,
      startWithWalk: false,
      cooldown: Duration(seconds: 10),
    );

    final container = ProviderContainer(
      overrides: [
        intervalHapticsProvider.overrideWithValue(haptics),
        intervalAudioProvider.overrideWithValue(audio),
        runNotificationsProvider.overrideWithValue(notifications),
        runLocationProvider.overrideWithValue(location),
        runClockFactoryProvider.overrideWithValue(
          () =>
              () => now,
        ),
        runOwnerProvider.overrideWithValue(() => null),
        intervalSelectionProvider.overrideWith(() => _PresetSelection(config)),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(activeRunProvider.notifier);
    await notifier.start(
      notificationTitle: 'RUNWILD',
      notificationText: 'Sesi lari',
      activeSession: true,
    );

    // Initial cue on start (warmup)
    expect(haptics.cues, contains(IntervalCue.general));
    expect(audio.cues, contains(IntervalCue.general));

    // Turn audio off, haptics remain active
    notifier.setAudioEnabled(false);
    expect(notifier.audioEnabled, isFalse);
    expect(notifier.hapticsEnabled, isTrue);

    // Advance to run phase (10s warmup elapsed)
    now = const Duration(seconds: 14);
    haptics.cues.clear();
    audio.cues.clear();

    notifier.setAudioEnabled(false); // triggers publish
    expect(haptics.cues, contains(IntervalCue.run));
    expect(audio.cues, isEmpty); // audio did not trigger because disabled!

    // Toggle pause triggers haptic feedback
    notifier.togglePause();
    expect(haptics.cues.last, IntervalCue.general);

    // Background notifications updated
    expect(notifications.updates, isNotEmpty);
    expect(notifications.updates.last.title, contains('RUNWILD'));

    // Stop cancels notifications
    await notifier.stop();
    expect(notifications.cancelCalls, greaterThanOrEqualTo(1));
  });
}
