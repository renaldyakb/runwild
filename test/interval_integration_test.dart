import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/domain/interval/interval_config.dart';
import 'package:runwild/domain/interval/interval_engine.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';
import 'package:runwild/features/run/application/interval_selection.dart';
import 'package:runwild/features/run/application/run_gps_probe.dart';
import 'package:runwild/features/run/application/run_journal.dart';
import 'package:runwild/features/run/application/run_location.dart';

class _Location implements RunLocation {
  final stream = StreamController<GpsSample>.broadcast();
  @override
  Stream<GpsSample> samples({
    required Duration Function() clock,
    required String notificationTitle,
    required String notificationText,
  }) => stream.stream;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Presets roundtrip, duration and corrupted configuration', () {
    for (final preset in IntervalPreset.values) {
      final config = intervalPreset(preset);
      expect(decodeInterval(encodeInterval(config)), config);
      expect(config.startWithWalk, preset == IntervalPreset.fiveOne);
    }
    const freeConfig = (
      warmup: Duration(minutes: 5),
      run: Duration(seconds: 30),
      walk: Duration(seconds: 30),
      rounds: null,
      startWithWalk: true,
      cooldown: Duration(minutes: 5),
    );
    expect(decodeInterval(encodeInterval(freeConfig)), freeConfig);
    expect(() => decodeInterval('{}'), throwsFormatException);
    expect(
      () => decodeInterval(
        encodeInterval((
          warmup: Duration.zero,
          run: Duration.zero,
          walk: Duration.zero,
          rounds: 0,
          startWithWalk: false,
          cooldown: Duration.zero,
        )),
      ),
      throwsFormatException,
    );
  });

  test('Restoration keeps phase and ignores shutdown time', () {
    var now = Duration.zero;
    final original = IntervalEngine(
      config: defaultIntervalConfig,
      clock: () => now,
    )..start();
    now = const Duration(minutes: 9, seconds: 15);
    original.pause();
    final saved = original.snapshot;
    now += const Duration(days: 1);
    final restored = IntervalEngine.restore(
      config: defaultIntervalConfig,
      clock: () => now,
      elapsed: saved.elapsed,
    );
    expect(restored.snapshot.phase, saved.phase);
    expect(restored.snapshot.remaining, saved.remaining);
    now += const Duration(seconds: 2);
    expect(
      restored.snapshot.elapsed,
      saved.elapsed + const Duration(seconds: 2),
    );
    expect(
      () => IntervalEngine.restore(
        config: defaultIntervalConfig,
        clock: () => now,
        elapsed: const Duration(seconds: -1),
      ),
      throwsArgumentError,
    );
  });

  test(
    'Preset CRUD is isolated, capped and supports rename at capacity',
    () async {
      final db = RunJournal(NativeDatabase.memory());
      addTearDown(db.close);
      for (var i = 0; i < 20; i++) {
        await db.savePreset('runner', 'Preset $i', defaultIntervalConfig);
      }
      expect(await db.presets('other'), isEmpty);
      await expectLater(
        db.savePreset('runner', 'Extra', defaultIntervalConfig),
        throwsA(isA<RunJournalException>()),
      );
      final id = (await db.presets('runner')).first.id;
      await expectLater(
        db.savePreset('other', 'Forbidden', defaultIntervalConfig, id: id),
        throwsA(isA<RunJournalException>()),
      );
      await db.savePreset('runner', 'Renamed', defaultIntervalConfig, id: id);
      expect((await db.presets('runner')).first.name, 'Renamed');
      await db.deletePreset('other', id);
      expect((await db.presets('runner')).length, 20);
      await db.deletePreset('runner', id);
      await db.savePreset('runner', 'New', defaultIntervalConfig);
      expect((await db.presets('runner')).length, 20);
    },
  );

  test(
    'Active interval pauses, persists, restores and ends without auto pause',
    () async {
      final db = RunJournal(NativeDatabase.memory());
      final location = _Location();
      var now = Duration.zero;
      final container = ProviderContainer(
        overrides: [
          runJournalProvider.overrideWithValue(db),
          runOwnerProvider.overrideWithValue(() => 'runner'),
          runLocationProvider.overrideWithValue(location),
          runClockFactoryProvider.overrideWithValue(
            () =>
                () => now,
          ),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await location.stream.close();
        await db.close();
      });
      final listener = container.listen(activeRunProvider, (_, _) {});
      const config = (
        warmup: Duration.zero,
        run: Duration(seconds: 10),
        walk: Duration(seconds: 10),
        rounds: 1,
        startWithWalk: false,
        cooldown: Duration.zero,
      );
      container.read(intervalSelectionProvider.notifier).select(config);
      final active = container.read(activeRunProvider.notifier);
      await active.start(
        notificationTitle: 'Test',
        notificationText: 'Test',
        activeSession: true,
      );
      expect(active.interval?.phase, IntervalPhase.run);
      now = const Duration(seconds: 5);
      active.togglePause();
      now = const Duration(seconds: 50);
      expect(active.interval?.remaining, const Duration(seconds: 5));
      active.togglePause();
      now += const Duration(seconds: 5);
      expect(active.interval?.phase, IntervalPhase.walk);
      await active.flushCheckpoint();
      await active.stop();
      await active.flushCheckpoint();
      final pending = await db.pending('runner');
      expect(pending, isNotNull);
      if (pending == null) fail('Missing persisted session');
      final saved = await db.interval('runner', pending.id);
      expect(saved?.config, config);
      expect(saved?.elapsed, const Duration(seconds: 13));
      expect(await db.interval('other', pending.id), isNull);
      listener.close();
      container.invalidate(activeRunProvider);
      final restoredListener = container.listen(activeRunProvider, (_, _) {});
      addTearDown(restoredListener.close);
      now += const Duration(hours: 1);
      container.read(intervalSelectionProvider.notifier).select(null);
      final restored = container.read(activeRunProvider.notifier);
      await restored.start(
        notificationTitle: 'Test',
        notificationText: 'Test',
        activeSession: true,
        resume: pending,
      );
      expect(restored.interval?.phase, IntervalPhase.walk);
      expect(restored.interval?.remaining, const Duration(seconds: 10));
      now += const Duration(seconds: 10);
      location.stream.add(
        GpsSample(
          latitude: 0,
          longitude: 0,
          accuracyMeters: 5,
          capturedAt: now,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(restored.interval?.phase, IntervalPhase.finished);
      expect(
        container.read(activeRunProvider).tracking,
        TrackingState.finished,
      );
      await restored.finishSession();
      expect(await db.pending('runner'), isNull);
    },
  );
}
