import '../../core/constants/interval_limits.dart';

enum IntervalPhase { idle, countdown, warmup, run, walk, cooldown, finished }

typedef IntervalConfig = ({
  Duration warmup,
  Duration run,
  Duration walk,

  /// null = bebas (tanpa batas putaran), mesin berhenti hanya saat stop manual.
  int? rounds,
  bool startWithWalk,
  Duration cooldown,
});

const defaultIntervalConfig = (
  warmup: Duration(minutes: 5),
  run: Duration(minutes: 1),
  walk: Duration(minutes: 2),
  rounds: 8,
  startWithWalk: true,
  cooldown: Duration(minutes: 5),
);

typedef IntervalSnapshot = ({
  IntervalPhase phase,
  bool paused,
  int round,
  int completedRounds,
  Duration remaining,
  Duration elapsed,
  Duration runTime,
  Duration walkTime,
});

typedef _Leg = ({IntervalPhase phase, Duration duration, int round});

final class IntervalEngine {
  IntervalEngine({required this.config, required this.clock}) {
    final preparation = [config.warmup, config.cooldown];
    final legs = [config.run, config.walk];
    final rounds = config.rounds;
    if (preparation.any(
          (d) => d < Duration.zero || d > IntervalLimits.maximumPreparation,
        ) ||
        legs.any(
          (d) => d < IntervalLimits.minimumLeg || d > IntervalLimits.maximumLeg,
        ) ||
        (rounds != null &&
            (rounds < IntervalLimits.minimumRounds ||
                rounds > IntervalLimits.maximumRounds))) {
      throw ArgumentError.value(config, 'config', 'Invalid interval limits');
    }
    // Mode bebas: bangun leg dengan placeholder besar; snapshot menangani
    // looping melalui _freeRoundDuration dan _freeRoundLegs.
    final fixedRounds = rounds ?? 1;
    _legs = [
      (
        phase: IntervalPhase.countdown,
        duration: IntervalLimits.countdown,
        round: 0,
      ),
      if (config.warmup > Duration.zero)
        (phase: IntervalPhase.warmup, duration: config.warmup, round: 0),
      for (var round = 1; round <= fixedRounds; round++) ...[
        if (config.startWithWalk)
          (phase: IntervalPhase.walk, duration: config.walk, round: round),
        (phase: IntervalPhase.run, duration: config.run, round: round),
        if (!config.startWithWalk)
          (phase: IntervalPhase.walk, duration: config.walk, round: round),
      ],
      if (config.cooldown > Duration.zero)
        (phase: IntervalPhase.cooldown, duration: config.cooldown, round: 0),
    ];
  }

  final IntervalConfig config;
  final Duration Function() clock;
  late final List<_Leg> _legs;
  Duration? _startedAt;
  Duration? _pausedAt;
  Duration _pausedTime = Duration.zero;

  factory IntervalEngine.restore({
    required IntervalConfig config,
    required Duration Function() clock,
    required Duration elapsed,
  }) {
    final engine = IntervalEngine(config: config, clock: clock);
    // Mode bebas tidak punya batas atas durasi sehingga hanya cek batas bawah.
    final trainingDuration = engine.trainingDuration;
    final maxElapsed = trainingDuration == null
        ? null
        : trainingDuration + IntervalLimits.countdown;
    if (elapsed < Duration.zero ||
        (maxElapsed != null && elapsed > maxElapsed)) {
      throw ArgumentError.value(elapsed, 'elapsed');
    }
    engine._startedAt = clock() - elapsed;
    return engine;
  }

  /// Durasi latihan terencana (tanpa countdown awal).
  /// Null jika rounds bebas (tanpa batas).
  Duration? get trainingDuration {
    final rounds = config.rounds;
    if (rounds == null) return null;
    return config.warmup +
        config.cooldown +
        (config.run + config.walk) * rounds;
  }

  /// Durasi satu putaran penuh (lari + jalan).
  Duration get _roundDuration => config.run + config.walk;

  void start() {
    if (_startedAt != null) return;
    _startedAt = clock();
  }

  void pause() {
    if (_startedAt == null ||
        _pausedAt != null ||
        snapshot.phase == IntervalPhase.finished) {
      return;
    }
    _pausedAt = clock();
  }

  void resume() {
    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    _pausedTime += clock() - pausedAt;
    _pausedAt = null;
  }

  IntervalSnapshot get snapshot {
    final startedAt = _startedAt;
    final isFree = config.rounds == null;
    final totalDuration = trainingDuration;
    final total = totalDuration == null
        ? null
        : totalDuration + IntervalLimits.countdown;
    final raw = startedAt == null
        ? Duration.zero
        : (_pausedAt ?? clock()) - startedAt - _pausedTime;
    final elapsed = (total != null && raw > total) ? total : raw;
    var left = elapsed;
    var runTime = Duration.zero;
    var walkTime = Duration.zero;
    var completedRounds = 0;
    var phase = startedAt == null ? IntervalPhase.idle : IntervalPhase.finished;
    var round = 0;
    var remaining = Duration.zero;

    if (startedAt != null) {
      // Iterasi melalui legs yang sudah dibangun (countdown + warmup + 1 ronde + cooldown).
      // Untuk mode bebas, setelah putaran 1 habis kita "loop" kembali ke ronde interval.
      if (isFree) {
        // Hitung leg-leg tetap: countdown dan warmup.
        var foundFixed = false;
        for (final leg in _legs) {
          if (leg.round > 0) break; // masuk ke interval
          final consumed = left < leg.duration ? left : leg.duration;
          if (leg.phase == IntervalPhase.run) runTime += consumed;
          if (leg.phase == IntervalPhase.walk) walkTime += consumed;
          if (left < leg.duration) {
            phase = leg.phase;
            round = 0;
            remaining = leg.duration - left;
            foundFixed = true;
            break;
          }
          left -= leg.duration;
        }

        if (!foundFixed) {
          // Cek apakah masih ada cooldown di akhir (tidak relevan untuk bebas
          // karena tidak ada akhir, tapi kita tetap sertakan fase countdown/warmup).
          // Hitung berapa banyak putaran yang telah berlalu.
          final roundLen = _roundDuration;
          if (roundLen > Duration.zero) {
            final roundsElapsed =
                left.inMicroseconds ~/ roundLen.inMicroseconds;
            final leftInRound = left - roundLen * roundsElapsed;
            completedRounds = roundsElapsed;
            round = roundsElapsed + 1; // putaran saat ini
            // Tentukan fase di dalam putaran ini.
            if (config.startWithWalk) {
              if (leftInRound < config.walk) {
                phase = IntervalPhase.walk;
                remaining = config.walk - leftInRound;
                walkTime += leftInRound;
              } else {
                final runLeft = leftInRound - config.walk;
                walkTime += config.walk;
                phase = IntervalPhase.run;
                remaining = config.run - runLeft;
                runTime += runLeft;
              }
            } else {
              if (leftInRound < config.run) {
                phase = IntervalPhase.run;
                remaining = config.run - leftInRound;
                runTime += leftInRound;
              } else {
                final walkLeft = leftInRound - config.run;
                runTime += config.run;
                phase = IntervalPhase.walk;
                remaining = config.walk - walkLeft;
                walkTime += walkLeft;
              }
            }
          } else {
            phase = IntervalPhase.finished;
          }
        }
      } else {
        // Mode terbatas: gunakan iterasi biasa pada _legs.
        for (final leg in _legs) {
          final consumed = left < leg.duration ? left : leg.duration;
          if (leg.phase == IntervalPhase.run) runTime += consumed;
          if (leg.phase == IntervalPhase.walk) walkTime += consumed;
          if (left < leg.duration) {
            phase = leg.phase;
            round = leg.round;
            remaining = leg.duration - left;
            break;
          }
          if (leg.round > 0 &&
              leg.phase ==
                  (config.startWithWalk
                      ? IntervalPhase.run
                      : IntervalPhase.walk)) {
            completedRounds++;
          }
          left -= leg.duration;
        }
      }
    }
    return (
      phase: phase,
      paused: _pausedAt != null,
      round: round,
      completedRounds: completedRounds,
      remaining: remaining,
      elapsed: elapsed,
      runTime: runTime,
      walkTime: walkTime,
    );
  }
}
