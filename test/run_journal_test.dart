import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/domain/interval/interval_engine.dart';
import 'package:runwild/domain/tracking/tracking_engine.dart';
import 'package:runwild/features/run/application/run_journal.dart';

void main() {
  test(
    'Checkpoint and route survive reopen and are isolated by account',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'runwild-journal-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}${Platform.pathSeparator}run.sqlite');
      final first = RunJournal(NativeDatabase(file));
      final startedAt = DateTime(2026, 11, 14, 6);
      final id = await first.begin(
        'runner',
        startedAt,
        interval: defaultIntervalConfig,
      );
      await first.savePreset('runner', 'My interval', defaultIntervalConfig);
      await expectLater(first.begin('runner', startedAt), throwsException);
      final checkpoint = (
        id: id,
        startedAt: startedAt,
        meters: 48.5,
        moving: const Duration(seconds: 16),
        elapsed: const Duration(seconds: 20),
        points: 1,
      );
      const fix = GpsSample(
        latitude: 0,
        longitude: 0,
        accuracyMeters: 4,
        capturedAt: Duration(seconds: 18),
      );
      await first.checkpoint('runner', checkpoint, const [
        (fix, SampleResult.segmentStart),
      ], intervalElapsed: const Duration(seconds: 20));
      await first.close();

      final reopened = RunJournal(NativeDatabase(file));
      addTearDown(reopened.close);
      expect(await reopened.pending('runner'), checkpoint);
      expect(await reopened.interval('runner', id), (
        config: defaultIntervalConfig,
        elapsed: const Duration(seconds: 20),
      ));
      expect((await reopened.presets('runner')).single.name, 'My interval');
      expect(await reopened.pending('other'), isNull);
      await expectLater(
        reopened.checkpoint('other', checkpoint, const [], finish: true),
        throwsA(isA<RunJournalException>()),
      );
      await reopened.checkpoint('runner', checkpoint, const [], finish: true);
      expect(await reopened.pending('runner'), isNull);
      final rows = await reopened
          .customSelect('SELECT * FROM run_points')
          .get();
      expect(rows.single.read<int>('segment_start'), 1);
      final nextId = await reopened.begin('runner', startedAt);
      expect(nextId, isNot(id));
      await reopened.discard('runner', nextId);
      expect(await reopened.pending('runner'), isNull);
    },
  );

  test(
    'Version 1 journal upgrades without losing an active free run',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'runwild-migration-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/run.sqlite');
      final old = RunJournal(NativeDatabase(file));
      final id = await old.begin('runner', DateTime(2026));
      await old.customStatement(
        'ALTER TABLE run_sessions DROP COLUMN interval_json',
      );
      await old.customStatement(
        'ALTER TABLE run_sessions DROP COLUMN interval_us',
      );
      await old.customStatement('DROP TABLE interval_presets');
      await old.customStatement('PRAGMA user_version = 1');
      await old.close();
      final upgraded = RunJournal(NativeDatabase(file));
      addTearDown(upgraded.close);
      expect((await upgraded.pending('runner'))?.id, id);
      expect(await upgraded.interval('runner', id), isNull);
      await upgraded.savePreset(
        'runner',
        'After upgrade',
        defaultIntervalConfig,
      );
      expect((await upgraded.presets('runner')).length, 1);
    },
  );

  test('Restored engine keeps totals and does not bridge the interruption', () {
    var clock = Duration.zero;
    final engine = TrackingEngine.restore(
      clock: () => clock,
      meters: 48.5,
      moving: const Duration(seconds: 16),
    );
    clock = const Duration(seconds: 3);
    expect(
      engine.addSample(
        const GpsSample(
          latitude: 10,
          longitude: 10,
          accuracyMeters: 5,
          capturedAt: Duration(seconds: 3),
        ),
      ),
      SampleResult.segmentStart,
    );
    expect(engine.distanceMeters, 48.5);
    expect(engine.movingTime, const Duration(seconds: 19));
  });
}
