import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/interval_limits.dart';
import '../../../core/services/interval_audio.dart';
import '../../../core/services/interval_haptics.dart';
import '../../../core/services/run_notifications.dart';
import '../../../domain/interval/interval_cues.dart';
import '../../../domain/interval/interval_engine.dart';
import '../../../domain/tracking/live_route.dart';
import '../../../domain/tracking/run_summary.dart';
import '../../../domain/tracking/tracking_engine.dart';
import '../../profile/application/profile_service.dart';
import 'interval_selection.dart';
import 'run_journal.dart';
import 'run_location.dart';

enum GpsProbeStatus { idle, waiting, recording, stopped, failed }

typedef GpsProbeSnapshot = ({
  GpsProbeStatus status,
  int points,
  double meters,
  Duration moving,
  double? pace,
  TrackingState tracking,
});

final runGpsProbeProvider =
    NotifierProvider.autoDispose<RunGpsProbe, GpsProbeSnapshot>(
      RunGpsProbe.new,
    );

final activeRunProvider =
    NotifierProvider.autoDispose<RunGpsProbe, GpsProbeSnapshot>(
      RunGpsProbe.new,
    );

final runClockFactoryProvider = Provider<Duration Function() Function()>(
  (ref) => () {
    final stopwatch = Stopwatch()..start();
    return () => stopwatch.elapsed;
  },
);

class RunGpsProbe extends Notifier<GpsProbeSnapshot> {
  StreamSubscription<GpsSample>? _subscription;
  Future<void>? _stopping;
  TrackingEngine? _engine;
  IntervalEngine? _interval;
  IntervalSnapshot? get interval => _interval?.snapshot;
  IntervalConfig? get intervalConfig => _interval?.config;
  int? get intervalRounds => _interval?.config.rounds;
  Timer? _ticker;
  Timer? _checkpointTimer;
  RunJournal? _journal;
  String? _owner;
  RunCheckpoint? _checkpoint;
  Future<void>? _writing;
  final _points = <(GpsSample, SampleResult)>[];
  final _route = LiveRoute();
  Duration Function()? _routeClock;
  LiveRouteSnapshot get liveRoute =>
      _route.snapshot(_routeClock?.call() ?? Duration.zero);
  List<KmSplit> get liveSplits => _engine?.splits ?? const [];
  bool _storageFailed = false;
  bool _starting = false;
  int _savedPointCount = 0;

  bool get storageFailed => _storageFailed;
  late IntervalAudio _audio;
  late IntervalHaptics _haptics;
  late RunNotifications _notifications;
  final _cues = IntervalCues();
  bool _audioEnabled = true;
  bool _hapticsEnabled = true;
  bool get audioEnabled => _audioEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  bool get audioFailed => _audio.failed;

  void setAudioEnabled(bool enabled) {
    _audioEnabled = enabled;
    if (!enabled) unawaited(_audio.stop());
    _publish(state.status, state.points);
  }

  void setHapticsEnabled(bool enabled) {
    _hapticsEnabled = enabled;
  }

  @override
  GpsProbeSnapshot build() {
    _audio = ref.watch(intervalAudioProvider);
    _haptics = ref.watch(intervalHapticsProvider);
    _notifications = ref.watch(runNotificationsProvider);
    ref.onDispose(() {
      _ticker?.cancel();
      _checkpointTimer?.cancel();
      unawaited(_notifications.cancel());
      final subscription = _subscription;
      _subscription = null;
      if (subscription != null) unawaited(_cancel(subscription));
    });
    return (
      status: GpsProbeStatus.idle,
      points: 0,
      meters: 0,
      moving: Duration.zero,
      pace: null,
      tracking: TrackingState.active,
    );
  }

  Future<void> start({
    required String notificationTitle,
    required String notificationText,
    bool activeSession = false,
    RunCheckpoint? resume,
  }) async {
    if (_starting || _subscription != null || _stopping != null) return;
    _starting = true;
    try {
      await _start(
        notificationTitle: notificationTitle,
        notificationText: notificationText,
        activeSession: activeSession,
        resume: resume,
      );
    } finally {
      _starting = false;
    }
  }

  Future<void> _start({
    required String notificationTitle,
    required String notificationText,
    required bool activeSession,
    required RunCheckpoint? resume,
  }) async {
    _storageFailed = false;
    var config = activeSession && resume == null
        ? ref.read(intervalSelectionProvider)
        : null;
    var intervalElapsed = IntervalLimits.countdown;
    final owner = activeSession ? ref.read(runOwnerProvider)() : null;
    if (owner != null) {
      final journal = ref.read(runJournalProvider);
      try {
        final startedAt = DateTime.now();
        _checkpoint =
            resume ??
            (
              id: await journal.begin(owner, startedAt, interval: config),
              startedAt: startedAt,
              meters: 0,
              moving: Duration.zero,
              elapsed: Duration.zero,
              points: 0,
            );
        _journal = journal;
        _owner = owner;
        if (resume != null) {
          final saved = await journal.interval(owner, resume.id);
          config = saved?.config;
          intervalElapsed = saved?.elapsed ?? IntervalLimits.countdown;
          final points = await journal.sessionPoints(resume.id, owner: owner);
          _route.restore(
            points.map(
              (point) => (
                point: (latitude: point.latitude, longitude: point.longitude),
                segmentStart: point.segmentStart,
              ),
            ),
          );
        }
      } on Exception {
        _storageFailed = true;
        if (ref.mounted) {
          state = (
            status: GpsProbeStatus.failed,
            points: 0,
            meters: 0,
            moving: Duration.zero,
            pace: null,
            tracking: TrackingState.finished,
          );
        }
        return;
      }
    }
    if (!ref.mounted) return;
    final clock = ref.read(runClockFactoryProvider)();
    _routeClock = clock;

    final profile = ref.read(userProfileProvider).value;
    if (profile != null) {
      _audioEnabled = profile.voice.enabled;
      _hapticsEnabled = profile.voice.haptics;
    }
    final autoPausePref = profile?.autoPause ?? true;

    final engine = resume == null
        ? TrackingEngine(
            clock: clock,
            autoPause: autoPausePref && activeSession && config == null,
          )
        : TrackingEngine.restore(
            clock: clock,
            meters: resume.meters,
            moving: resume.moving,
            autoPause: autoPausePref && config == null,
          );
    _engine = engine;
    if (config != null) {
      _interval = IntervalEngine.restore(
        config: config,
        clock: clock,
        elapsed: intervalElapsed,
      );
    }
    _publish(GpsProbeStatus.waiting, resume?.points ?? 0);
    if (activeSession) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        _completeInterval();
        _publish(state.status, state.points);
      });
    }
    if (_journal != null) {
      _checkpointTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) => unawaited(_savePeriodically()),
      );
    }
    _subscription = ref
        .read(runLocationProvider)
        .samples(
          clock: clock,
          notificationTitle: notificationTitle,
          notificationText: notificationText,
        )
        .listen(
          (sample) {
            _completeInterval();
            final result = engine.addSample(sample);
            _route.add(sample, result, clock());
            final accepted = result != SampleResult.ignored;
            if (accepted && _journal != null) _points.add((sample, result));
            if (accepted || activeSession) {
              _publish(
                accepted ? GpsProbeStatus.recording : state.status,
                state.points + (accepted ? 1 : 0),
              );
            }
          },
          onError: (Object error, StackTrace trace) =>
              unawaited(_stop(GpsProbeStatus.failed)),
          onDone: () => unawaited(_stop(GpsProbeStatus.failed)),
        );
    _completeInterval();
  }

  Future<void> stop() => _stop(GpsProbeStatus.stopped);

  Future<RunSummary> finishSession() async {
    final engine = _engine;
    final intervalSnap = _interval?.snapshot;
    final checkpoint = _checkpoint;
    final startedAt = checkpoint?.startedAt ?? DateTime.now();
    final summary = RunSummary(
      sessionId: checkpoint?.id,
      startedAt: startedAt,
      distanceMeters: engine?.distanceMeters ?? 0,
      movingTime: engine?.movingTime ?? Duration.zero,
      elapsedTime: checkpoint == null
          ? (engine?.elapsedTime ?? Duration.zero)
          : checkpoint.elapsed + (engine?.elapsedTime ?? Duration.zero),
      averagePace: engine?.averagePace,
      splits: engine?.splits ?? const [],
      interval: intervalSnap == null
          ? null
          : (
              completedRounds: intervalSnap.completedRounds,
              totalRounds: _interval?.config.rounds,
              runTime: intervalSnap.runTime,
              walkTime: intervalSnap.walkTime,
            ),
    );
    await _stop(GpsProbeStatus.stopped);
    await _stopping;
    await _save(finish: true);
    return summary;
  }

  Future<void> flushCheckpoint() => _savePeriodically(wait: true);

  Future<void> _savePeriodically({bool wait = false}) async {
    try {
      await _save(wait: wait);
    } on Exception {
      _storageFailed = true;
      if (ref.mounted) _publish(state.status, state.points);
    }
  }

  Future<void> _save({bool finish = false, bool wait = false}) async {
    while (_writing != null) {
      final previous = _writing;
      if (!finish && !wait) return;
      try {
        await previous;
      } on Exception {
        // A final save retries the retained batch.
      }
    }
    final journal = _journal;
    final original = _checkpoint;
    final owner = _owner;
    final engine = _engine;
    if (journal == null ||
        original == null ||
        owner == null ||
        engine == null) {
      return;
    }
    final batch = List.of(_points);
    final operation = journal.checkpoint(
      owner,
      (
        id: original.id,
        startedAt: original.startedAt,
        meters: engine.distanceMeters,
        moving: engine.movingTime,
        elapsed: original.elapsed + engine.elapsedTime,
        points: original.points + _savedPointCount + batch.length,
      ),
      batch
          .map(
            (point) => (
              GpsSample(
                latitude: point.$1.latitude,
                longitude: point.$1.longitude,
                accuracyMeters: point.$1.accuracyMeters,
                capturedAt: original.elapsed + point.$1.capturedAt,
              ),
              point.$2,
            ),
          )
          .toList(),
      finish: finish,
      intervalElapsed: _interval?.snapshot.elapsed,
      intervalRounds: _interval?.snapshot.completedRounds,
      intervalRun: _interval?.snapshot.runTime,
      intervalWalk: _interval?.snapshot.walkTime,
    );
    _writing = operation;
    try {
      await operation;
      _points.removeRange(0, batch.length);
      _savedPointCount += batch.length;
      _storageFailed = false;
    } finally {
      _writing = null;
    }
  }

  void togglePause() {
    final engine = _engine;
    if (_subscription == null ||
        engine == null ||
        interval?.phase == IntervalPhase.finished) {
      return;
    }
    if (engine.state == TrackingState.active) {
      engine.pause();
      _interval?.pause();
      if (_hapticsEnabled) unawaited(_haptics.vibrate(IntervalCue.general));
    } else {
      engine.resume();
      _interval?.resume();
      if (_hapticsEnabled) unawaited(_haptics.vibrate(IntervalCue.general));
    }
    _publish(state.status, state.points);
    if (_journal != null) unawaited(flushCheckpoint());
  }

  void _completeInterval() {
    final engine = _engine;
    if (interval?.phase == IntervalPhase.finished &&
        engine != null &&
        engine.state != TrackingState.finished) {
      if (_hapticsEnabled) unawaited(_haptics.sessionFinished());
      unawaited(_stop(GpsProbeStatus.stopped).then((_) => flushCheckpoint()));
    }
  }

  void _publish(GpsProbeStatus status, int points) {
    final engine = _engine;
    if (engine == null) return;
    final phase = interval;
    if (phase != null && status != GpsProbeStatus.failed) {
      final cue = _cues.update(phase);
      if (cue != null) {
        final profile = ref.read(userProfileProvider).value;
        final allowCountdown = profile?.voice.countdownCue ?? true;
        final allowRound = profile?.voice.roundCue ?? true;

        final isCountdownCue =
            cue == IntervalCue.runTenSeconds ||
            cue == IntervalCue.walkTenSeconds;
        final isRoundCue = cue == IntervalCue.run || cue == IntervalCue.walk;

        final canPlayAudio =
            _audioEnabled &&
            (!isCountdownCue || allowCountdown) &&
            (!isRoundCue || allowRound);

        final canVibrate =
            _hapticsEnabled && (!isCountdownCue || allowCountdown);

        if (canPlayAudio) unawaited(_audio.play(cue));
        if (canVibrate) unawaited(_haptics.vibrate(cue));
      }
    }
    state = (
      status: status,
      points: points,
      meters: engine.distanceMeters,
      moving: engine.movingTime,
      pace: engine.averagePace,
      tracking: engine.state,
    );
    if (status != GpsProbeStatus.idle && status != GpsProbeStatus.stopped) {
      _updateNotification(status, engine, phase);
    }
  }

  void _updateNotification(
    GpsProbeStatus status,
    TrackingEngine engine,
    IntervalSnapshot? phase,
  ) {
    final distanceKm = (engine.distanceMeters / 1000).toStringAsFixed(2);
    final movingSec = engine.movingTime.inSeconds;
    final movingFormatted =
        '${(movingSec ~/ 60).toString().padLeft(2, '0')}:${(movingSec % 60).toString().padLeft(2, '0')}';
    final body = '$distanceKm km · $movingFormatted';

    if (status == GpsProbeStatus.failed) {
      unawaited(
        _notifications.update(
          title: 'RUNWILD · GPS Terputus',
          body: 'Periksa izin lokasi dan kembali ke area terbuka.',
        ),
      );
      return;
    }

    if (engine.state == TrackingState.manuallyPaused ||
        engine.state == TrackingState.autoPaused) {
      unawaited(
        _notifications.update(title: 'RUNWILD · Sesi Dijeda', body: body),
      );
      return;
    }

    if (phase != null) {
      final phaseName = switch (phase.phase) {
        IntervalPhase.warmup => 'Pemanasan',
        IntervalPhase.run => 'Lari',
        IntervalPhase.walk => 'Jalan',
        IntervalPhase.cooldown => 'Pendinginan',
        IntervalPhase.finished => 'Interval Selesai',
        _ => 'Bersiap',
      };
      final remSec = phase.remaining.inSeconds;
      final remFormatted =
          '${(remSec ~/ 60).toString().padLeft(2, '0')}:${(remSec % 60).toString().padLeft(2, '0')}';
      final roundInfo = phase.round > 0
          ? (intervalRounds == null
                ? ' (P${phase.round})'
                : ' (P${phase.round}/$intervalRounds)')
          : '';
      unawaited(
        _notifications.update(
          title: 'RUNWILD · $phaseName $remFormatted$roundInfo',
          body: body,
        ),
      );
      return;
    }

    unawaited(
      _notifications.update(title: 'RUNWILD · Sedang Berlari', body: body),
    );
  }

  Future<void> _stop(GpsProbeStatus status) async {
    final subscription = _subscription;
    if (subscription == null) return;
    _subscription = null;
    _ticker?.cancel();
    _checkpointTimer?.cancel();
    _engine?.finish();
    _interval?.pause();
    unawaited(_notifications.cancel());
    if (status == GpsProbeStatus.failed) unawaited(_audio.stop());
    final stopping = _cancel(subscription);
    _stopping = stopping;
    await stopping;
    _stopping = null;
    if (ref.mounted) {
      _publish(status, state.points);
      if (status == GpsProbeStatus.failed) await _savePeriodically();
    }
  }

  Future<void> _cancel(StreamSubscription<GpsSample> subscription) async {
    try {
      await subscription.cancel();
    } on Exception {
      // The subscription is already detached from the session.
      return;
    }
  }
}
