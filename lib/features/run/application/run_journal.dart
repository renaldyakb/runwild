import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/activity_history_limits.dart';
import '../../../core/constants/interval_limits.dart';
import '../../../domain/interval/interval_config.dart';
import '../../../domain/interval/interval_engine.dart';
import '../../../domain/tracking/activity_history.dart';
import '../../../domain/tracking/tracking_engine.dart';

typedef StoredInterval = ({IntervalConfig config, Duration elapsed});
typedef SavedInterval = ({int id, String name, IntervalConfig config});

typedef RunCheckpoint = ({
  int id,
  DateTime startedAt,
  double meters,
  Duration moving,
  Duration elapsed,
  int points,
});

/// Rincian interval yang benar-benar terjadi, disimpan saat sesi berjalan.
typedef StoredIntervalProgress = ({int rounds, Duration run, Duration walk});

typedef FinishedSessionRecord = ({
  int id,
  String owner,
  DateTime startedAt,
  double meters,
  Duration moving,
  Duration elapsed,
  int points,
  String? intervalJson,
  String? feeling,
  String? note,
  String? activityId,
  String? title,
  bool synced,
});

typedef StoredPoint = ({
  int seq,
  Duration capturedAt,
  double latitude,
  double longitude,
  double accuracy,
  bool segmentStart,
});

final runOwnerProvider = Provider<String? Function()>(
  (ref) => () {
    if (Firebase.apps.isEmpty) return null;
    return FirebaseAuth.instance.currentUser?.uid;
  },
);

final runJournalProvider = Provider<RunJournal>((ref) {
  final database = RunJournal(
    LazyDatabase(() async {
      final directory = await getApplicationSupportDirectory();
      return NativeDatabase.createInBackground(
        File('${directory.path}${Platform.pathSeparator}runwild.sqlite'),
      );
    }),
  );
  ref.onDispose(() => unawaited(database.close()));
  return database;
});

class RunJournal extends GeneratedDatabase {
  RunJournal(super.executor);

  @override
  int get schemaVersion => 6;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (_) async {
      await customStatement('''
        CREATE TABLE run_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          owner TEXT NOT NULL,
          started_ms INTEGER NOT NULL,
          meters REAL NOT NULL DEFAULT 0,
          moving_us INTEGER NOT NULL DEFAULT 0,
          elapsed_us INTEGER NOT NULL DEFAULT 0,
          points INTEGER NOT NULL DEFAULT 0,
          finished INTEGER NOT NULL DEFAULT 0,
          interval_json TEXT,
          interval_us INTEGER NOT NULL DEFAULT 0,
          interval_rounds INTEGER,
          interval_run_us INTEGER,
          interval_walk_us INTEGER,
          feeling TEXT,
          note TEXT,
          synced INTEGER NOT NULL DEFAULT 0,
          activity_id TEXT,
          title TEXT
        )''');
      await customStatement('''
        CREATE UNIQUE INDEX one_active_run
        ON run_sessions(owner) WHERE finished = 0
      ''');
      await customStatement('''
        CREATE TABLE run_points (
          session_id INTEGER NOT NULL REFERENCES run_sessions(id) ON DELETE CASCADE,
          seq INTEGER NOT NULL,
          captured_us INTEGER NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          accuracy REAL NOT NULL,
          segment_start INTEGER NOT NULL,
          PRIMARY KEY (session_id, seq)
        )''');
      await _createPresets();
    },
    onUpgrade: (_, from, to) async {
      final info = await customSelect('PRAGMA table_info(run_sessions)').get();
      final columns = info.map((r) => r.read<String>('name')).toSet();
      if (!columns.contains('interval_json')) {
        await customStatement(
          'ALTER TABLE run_sessions ADD COLUMN interval_json TEXT',
        );
      }
      if (!columns.contains('interval_us')) {
        await customStatement(
          'ALTER TABLE run_sessions ADD COLUMN interval_us INTEGER NOT NULL DEFAULT 0',
        );
      }
      final tables = await customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='interval_presets'",
      ).get();
      if (tables.isEmpty) {
        await _createPresets();
      }
      if (!columns.contains('feeling')) {
        await customStatement(
          'ALTER TABLE run_sessions ADD COLUMN feeling TEXT',
        );
      }
      if (!columns.contains('note')) {
        await customStatement('ALTER TABLE run_sessions ADD COLUMN note TEXT');
      }
      if (!columns.contains('synced')) {
        await customStatement(
          'ALTER TABLE run_sessions ADD COLUMN synced INTEGER NOT NULL DEFAULT 0',
        );
      }
      if (!columns.contains('activity_id')) {
        await customStatement(
          'ALTER TABLE run_sessions ADD COLUMN activity_id TEXT',
        );
      }
      if (!columns.contains('title')) {
        await customStatement('ALTER TABLE run_sessions ADD COLUMN title TEXT');
      }
      if (!columns.contains('interval_rounds')) {
        await customStatement(
          'ALTER TABLE run_sessions ADD COLUMN interval_rounds INTEGER',
        );
      }
      if (!columns.contains('interval_run_us')) {
        await customStatement(
          'ALTER TABLE run_sessions ADD COLUMN interval_run_us INTEGER',
        );
      }
      if (!columns.contains('interval_walk_us')) {
        await customStatement(
          'ALTER TABLE run_sessions ADD COLUMN interval_walk_us INTEGER',
        );
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  Future<void> _createPresets() => customStatement('''
    CREATE TABLE interval_presets (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner TEXT NOT NULL,
      name TEXT NOT NULL,
      config TEXT NOT NULL
    )
  ''');

  Future<List<SavedInterval>> presets(String owner) async {
    final rows = await customSelect(
      'SELECT * FROM interval_presets WHERE owner = ? ORDER BY id',
      variables: [Variable(owner)],
    ).get();
    return [
      for (final row in rows)
        (
          id: row.read<int>('id'),
          name: row.read<String>('name'),
          config: decodeInterval(row.read<String>('config')),
        ),
    ];
  }

  Future<void> savePreset(
    String owner,
    String name,
    IntervalConfig config, {
    int? id,
  }) => transaction(() async {
    final label = name.trim();
    if (label.isEmpty || label.length > IntervalLimits.presetNameLength) {
      throw const RunJournalException();
    }
    final encoded = encodeInterval(config);
    decodeInterval(encoded);
    if (id != null) {
      final updated = await customUpdate(
        'UPDATE interval_presets SET name = ?, config = ? WHERE owner = ? AND id = ?',
        variables: [
          Variable(label),
          Variable(encoded),
          Variable(owner),
          Variable(id),
        ],
      );
      if (updated != 1) throw const RunJournalException();
      return;
    }
    if ((await presets(owner)).length >= IntervalLimits.maximumPresets) {
      throw const RunJournalException();
    }
    await customInsert(
      'INSERT INTO interval_presets(owner, name, config) VALUES (?, ?, ?)',
      variables: [Variable(owner), Variable(label), Variable(encoded)],
    );
  });

  Future<void> deletePreset(String owner, int id) => customStatement(
    'DELETE FROM interval_presets WHERE owner = ? AND id = ?',
    [owner, id],
  );

  Future<int> begin(
    String owner,
    DateTime startedAt, {
    IntervalConfig? interval,
  }) => customInsert(
    'INSERT INTO run_sessions(owner, started_ms, interval_json, interval_us) VALUES (?, ?, ?, ?)',
    variables: [
      Variable(owner),
      Variable(startedAt.millisecondsSinceEpoch),
      Variable<String>(interval == null ? null : encodeInterval(interval)),
      Variable(interval == null ? 0 : IntervalLimits.countdown.inMicroseconds),
    ],
  );

  Future<StoredInterval?> interval(String owner, int id) async {
    final row = await customSelect(
      'SELECT interval_json, interval_us FROM run_sessions WHERE owner = ? AND id = ?',
      variables: [Variable(owner), Variable(id)],
    ).getSingleOrNull();
    final encoded = row?.readNullable<String>('interval_json');
    if (row == null || encoded == null) return null;
    final config = decodeInterval(encoded);
    final elapsed = Duration(microseconds: row.read<int>('interval_us'));
    final trainingDuration = IntervalEngine(
      config: config,
      clock: () => Duration.zero,
    ).trainingDuration;
    final total = trainingDuration == null
        ? null
        : trainingDuration + IntervalLimits.countdown;
    if (elapsed < Duration.zero || (total != null && elapsed > total)) {
      throw const FormatException('Invalid saved interval time');
    }
    return (config: config, elapsed: elapsed);
  }

  /// Rincian interval aktual milik sesi ini, atau null bila belum pernah
  /// dicatat (sesi lama) sehingga tampilan tidak boleh mengarang angka.
  Future<StoredIntervalProgress?> intervalProgress(String owner, int id) async {
    final rows = await customSelect(
      'SELECT interval_rounds, interval_run_us, interval_walk_us '
      'FROM run_sessions WHERE owner = ? AND id = ?',
      variables: [Variable(owner), Variable(id)],
    ).get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    final rounds = row.readNullable<int>('interval_rounds');
    final run = row.readNullable<int>('interval_run_us');
    final walk = row.readNullable<int>('interval_walk_us');
    if (rounds == null || run == null || walk == null) return null;
    return (
      rounds: rounds,
      run: Duration(microseconds: run),
      walk: Duration(microseconds: walk),
    );
  }

  Future<RunCheckpoint?> pending(String owner) async {
    final row = await customSelect(
      'SELECT * FROM run_sessions WHERE owner = ? AND finished = 0',
      variables: [Variable(owner)],
    ).getSingleOrNull();
    if (row == null) return null;
    return (
      id: row.read<int>('id'),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('started_ms'),
      ),
      meters: row.read<double>('meters'),
      moving: Duration(microseconds: row.read<int>('moving_us')),
      elapsed: Duration(microseconds: row.read<int>('elapsed_us')),
      points: row.read<int>('points'),
    );
  }

  Future<void> checkpoint(
    String owner,
    RunCheckpoint state,
    List<(GpsSample, SampleResult)> samples, {
    bool finish = false,
    Duration? intervalElapsed,
    int? intervalRounds,
    Duration? intervalRun,
    Duration? intervalWalk,
  }) => transaction(() async {
    final updated = await customUpdate(
      '''UPDATE run_sessions SET meters = ?, moving_us = ?, elapsed_us = ?,
         points = ?, finished = ?, interval_us = COALESCE(?, interval_us),
         interval_rounds = COALESCE(?, interval_rounds),
         interval_run_us = COALESCE(?, interval_run_us),
         interval_walk_us = COALESCE(?, interval_walk_us)
         WHERE id = ? AND owner = ? AND finished = 0''',
      variables: [
        Variable(state.meters),
        Variable(state.moving.inMicroseconds),
        Variable(state.elapsed.inMicroseconds),
        Variable(state.points),
        Variable(finish ? 1 : 0),
        Variable<int>(intervalElapsed?.inMicroseconds),
        Variable<int>(intervalRounds),
        Variable<int>(intervalRun?.inMicroseconds),
        Variable<int>(intervalWalk?.inMicroseconds),
        Variable(state.id),
        Variable(owner),
      ],
    );
    if (updated != 1) throw const RunJournalException();
    var seq = state.points - samples.length;
    for (final (sample, result) in samples) {
      await customStatement(
        'INSERT INTO run_points VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          state.id,
          ++seq,
          sample.capturedAt.inMicroseconds,
          sample.latitude,
          sample.longitude,
          sample.accuracyMeters,
          result == SampleResult.segmentStart ? 1 : 0,
        ],
      );
    }
  });

  Future<void> discard(String owner, int id) => customStatement(
    'DELETE FROM run_sessions WHERE owner = ? AND id = ? AND finished = 0',
    [owner, id],
  );

  Future<void> updateSummary(
    String owner,
    int id, {
    String? feeling,
    String? note,
  }) => customUpdate(
    'UPDATE run_sessions SET feeling = ?, note = ? WHERE owner = ? AND id = ?',
    variables: [
      Variable<String>(feeling),
      Variable<String>(note),
      Variable<String>(owner),
      Variable<int>(id),
    ],
  );

  Future<void> updateSession(
    String owner,
    int id, {
    String? title,
    String? note,
    String? feeling,
  }) => customUpdate(
    'UPDATE run_sessions SET title = ?, note = ?, feeling = ?, synced = 0 WHERE owner = ? AND id = ?',
    variables: [
      Variable<String>(title),
      Variable<String>(note),
      Variable<String>(feeling),
      Variable<String>(owner),
      Variable<int>(id),
    ],
  );

  Future<FinishedSessionRecord?> session(String owner, int id) async {
    final rows = await customSelect(
      'SELECT * FROM run_sessions WHERE owner = ? AND id = ?',
      variables: [Variable(owner), Variable(id)],
    ).get();
    if (rows.isEmpty) return null;
    final row = rows.first;
    return (
      id: row.read<int>('id'),
      owner: row.read<String>('owner'),
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('started_ms'),
        isUtc: true,
      ),
      meters: row.read<double>('meters'),
      moving: Duration(microseconds: row.read<int>('moving_us')),
      elapsed: Duration(microseconds: row.read<int>('elapsed_us')),
      points: row.read<int>('points'),
      intervalJson: row.readNullable<String>('interval_json'),
      feeling: row.readNullable<String>('feeling'),
      note: row.readNullable<String>('note'),
      activityId: row.readNullable<String>('activity_id'),
      title: row.readNullable<String>('title'),
      synced: row.read<int>('synced') == 1,
    );
  }

  Future<void> discardSession(String owner, int id) => customStatement(
    'DELETE FROM run_sessions WHERE owner = ? AND id = ?',
    [owner, id],
  );

  Future<List<FinishedSessionRecord>> unsyncedSessions(String owner) async {
    final rows = await customSelect(
      'SELECT * FROM run_sessions WHERE owner = ? AND finished = 1 AND synced = 0 ORDER BY id ASC',
      variables: [Variable(owner)],
    ).get();
    return [
      for (final row in rows)
        (
          id: row.read<int>('id'),
          owner: row.read<String>('owner'),
          startedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('started_ms'),
            isUtc: true,
          ),
          meters: row.read<double>('meters'),
          moving: Duration(microseconds: row.read<int>('moving_us')),
          elapsed: Duration(microseconds: row.read<int>('elapsed_us')),
          points: row.read<int>('points'),
          intervalJson: row.readNullable<String>('interval_json'),
          feeling: row.readNullable<String>('feeling'),
          note: row.readNullable<String>('note'),
          activityId: row.readNullable<String>('activity_id'),
          title: row.readNullable<String>('title'),
          synced: row.read<int>('synced') == 1,
        ),
    ];
  }

  Future<HistoryPage> history(
    String owner,
    ActivityHistoryFilter filter, {
    HistoryCursor? before,
  }) async {
    final mode = switch (filter) {
      ActivityHistoryFilter.all => '',
      ActivityHistoryFilter.free => ' AND interval_json IS NULL',
      ActivityHistoryFilter.interval => ' AND interval_json IS NOT NULL',
    };
    final cursor = before == null
        ? ''
        : ' AND (started_ms < ? OR (started_ms = ? AND id < ?))';
    final rows = await customSelect(
      'SELECT id, started_ms, meters, moving_us, interval_json, synced, title FROM run_sessions '
      'WHERE owner = ? AND finished = 1$mode$cursor ORDER BY started_ms DESC, id DESC LIMIT ?',
      variables: [
        Variable(owner),
        if (before != null) ...[
          Variable(before.startedMs),
          Variable(before.startedMs),
          Variable(before.id),
        ],
        Variable(ActivityHistoryLimits.pageSize + 1),
      ],
    ).get();
    final visible = rows.take(ActivityHistoryLimits.pageSize).toList();
    final items = <HistoryItem>[];
    for (final row in visible) {
      final id = row.read<int>('id');
      final route = await customSelect(
        '''
        SELECT latitude, longitude, segment_start FROM run_points
        WHERE session_id = ? AND (
          segment_start = 1 OR seq = 1 OR
          seq = (SELECT MAX(seq) FROM run_points WHERE session_id = ?) OR
          seq % (1 + (SELECT COUNT(*) FROM run_points WHERE session_id = ?) / ?) = 0
        ) ORDER BY seq
      ''',
        variables: [
          Variable(id),
          Variable(id),
          Variable(id),
          Variable(ActivityHistoryLimits.previewPoints),
        ],
      ).get();
      items.add((
        id: id,
        startedAt: DateTime.fromMillisecondsSinceEpoch(
          row.read<int>('started_ms'),
        ),
        meters: row.read<double>('meters'),
        moving: Duration(microseconds: row.read<int>('moving_us')),
        interval: row.readNullable<String>('interval_json') != null,
        synced: row.read<int>('synced') == 1,
        title: row.readNullable<String>('title'),
        route: List.unmodifiable([
          for (final point in route)
            (
              latitude: point.read<double>('latitude'),
              longitude: point.read<double>('longitude'),
              segmentStart: point.read<int>('segment_start') == 1,
            ),
        ]),
      ));
    }
    return (
      items: List<HistoryItem>.unmodifiable(items),
      next: rows.length > ActivityHistoryLimits.pageSize
          ? (
              startedMs: visible.last.read<int>('started_ms'),
              id: visible.last.read<int>('id'),
            )
          : null,
    );
  }

  Future<List<StoredPoint>> sessionPoints(
    int sessionId, {
    String? owner,
  }) async {
    final rows = await customSelect(
      'SELECT p.* FROM run_points p JOIN run_sessions s ON s.id = p.session_id '
      'WHERE session_id = ? AND (? IS NULL OR s.owner = ?) ORDER BY seq ASC',
      variables: [
        Variable(sessionId),
        Variable<String>(owner),
        Variable<String>(owner),
      ],
    ).get();
    return [
      for (final row in rows)
        (
          seq: row.read<int>('seq'),
          capturedAt: Duration(microseconds: row.read<int>('captured_us')),
          latitude: row.read<double>('latitude'),
          longitude: row.read<double>('longitude'),
          accuracy: row.read<double>('accuracy'),
          segmentStart: row.read<int>('segment_start') == 1,
        ),
    ];
  }

  Future<void> markSynced(String owner, int id, String activityId) =>
      customUpdate(
        'UPDATE run_sessions SET synced = 1, activity_id = ? WHERE owner = ? AND id = ?',
        variables: [
          Variable<String>(activityId),
          Variable<String>(owner),
          Variable<int>(id),
        ],
      );

  Future<int> importSession({
    required String owner,
    required String activityId,
    required DateTime startedAt,
    required double meters,
    required Duration moving,
    required Duration elapsed,
    String? title,
    String? feeling,
    String? note,
    String? intervalJson,
    int? intervalRounds,
    Duration? intervalRun,
    Duration? intervalWalk,
    List<({double latitude, double longitude})> routePoints = const [],
  }) => transaction(() async {
    final existing = await customSelect(
      'SELECT id, synced FROM run_sessions WHERE owner = ? AND activity_id = ? LIMIT 1',
      variables: [Variable(owner), Variable(activityId)],
    ).get();
    if (existing.isNotEmpty) {
      final localSynced = existing.first.read<int>('synced') == 1;
      if (localSynced) {
        await customUpdate(
          'UPDATE run_sessions SET title = ?, note = ?, feeling = ? WHERE owner = ? AND activity_id = ?',
          variables: [
            Variable<String>(title),
            Variable<String>(note),
            Variable<String>(feeling),
            Variable(owner),
            Variable(activityId),
          ],
        );
      }
      return existing.first.read<int>('id');
    }

    final id = await customInsert(
      '''INSERT INTO run_sessions(
           owner, started_ms, meters, moving_us, elapsed_us, points,
           finished, interval_json, interval_us, feeling, note, synced, activity_id, title,
           interval_rounds, interval_run_us, interval_walk_us
         ) VALUES (?, ?, ?, ?, ?, ?, 1, ?, 0, ?, ?, 1, ?, ?, ?, ?, ?)''',
      variables: [
        Variable(owner),
        Variable(startedAt.millisecondsSinceEpoch),
        Variable(meters),
        Variable(moving.inMicroseconds),
        Variable(elapsed.inMicroseconds),
        Variable(routePoints.length),
        Variable<String>(intervalJson),
        Variable<String>(feeling),
        Variable<String>(note),
        Variable(activityId),
        Variable<String>(title),
        Variable<int>(intervalRounds),
        Variable<int>(intervalRun?.inMicroseconds),
        Variable<int>(intervalWalk?.inMicroseconds),
      ],
    );

    if (routePoints.isNotEmpty) {
      final dt = routePoints.length > 1
          ? moving.inMicroseconds ~/ (routePoints.length - 1)
          : 0;
      for (var i = 0; i < routePoints.length; i++) {
        final pt = routePoints[i];
        await customStatement(
          'INSERT INTO run_points VALUES (?, ?, ?, ?, ?, ?, ?)',
          [id, i + 1, i * dt, pt.latitude, pt.longitude, 5.0, i == 0 ? 1 : 0],
        );
      }
    }

    return id;
  });

  Future<List<FinishedSessionRecord>> allFinishedSessions(String owner) async {
    final rows = await customSelect(
      'SELECT * FROM run_sessions WHERE owner = ? AND finished = 1 ORDER BY started_ms ASC',
      variables: [Variable(owner)],
    ).get();
    return [
      for (final row in rows)
        (
          id: row.read<int>('id'),
          owner: row.read<String>('owner'),
          startedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('started_ms'),
            isUtc: true,
          ),
          meters: row.read<double>('meters'),
          moving: Duration(microseconds: row.read<int>('moving_us')),
          elapsed: Duration(microseconds: row.read<int>('elapsed_us')),
          points: row.read<int>('points'),
          intervalJson: row.readNullable<String>('interval_json'),
          feeling: row.readNullable<String>('feeling'),
          note: row.readNullable<String>('note'),
          activityId: row.readNullable<String>('activity_id'),
          title: row.readNullable<String>('title'),
          synced: row.read<int>('synced') == 1,
        ),
    ];
  }

  Future<List<({double latitude, double longitude})>> latestRoute(
    String owner,
  ) async {
    final latest = await customSelect(
      'SELECT id FROM run_sessions WHERE owner = ? AND finished = 1 ORDER BY started_ms DESC LIMIT 1',
      variables: [Variable(owner)],
    ).getSingleOrNull();
    if (latest == null) return const [];
    final id = latest.read<int>('id');
    final points = await sessionPoints(id, owner: owner);
    return [
      for (final p in points) (latitude: p.latitude, longitude: p.longitude),
    ];
  }

  Future<void> purgeUserData(String owner) => transaction(() async {
    await customStatement('DELETE FROM interval_presets WHERE owner = ?', [
      owner,
    ]);
    await customStatement(
      'DELETE FROM run_points WHERE session_id IN (SELECT id FROM run_sessions WHERE owner = ?)',
      [owner],
    );
    await customStatement('DELETE FROM run_sessions WHERE owner = ?', [owner]);
  });
}

class RunJournalException implements Exception {
  const RunJournalException();
}
