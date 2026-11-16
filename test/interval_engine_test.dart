import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/domain/interval/interval_engine.dart';

void main() {
  const short = (
    warmup: Duration.zero,
    run: Duration(seconds: 10),
    walk: Duration(seconds: 20),
    rounds: 2,
    startWithWalk: false,
    cooldown: Duration.zero,
  );

  for (final walkFirst in [false, true]) {
    test('Both legs complete each round, walk first=$walkFirst', () {
      var now = Duration.zero;
      final config = (
        warmup: short.warmup,
        run: short.run,
        walk: short.walk,
        rounds: short.rounds,
        startWithWalk: walkFirst,
        cooldown: short.cooldown,
      );
      final engine = IntervalEngine(config: config, clock: () => now);
      expect(engine.snapshot.phase, IntervalPhase.idle);
      engine.start();
      expect(engine.snapshot.phase, IntervalPhase.countdown);
      now = const Duration(seconds: 3);
      expect(
        engine.snapshot.phase,
        walkFirst ? IntervalPhase.walk : IntervalPhase.run,
      );
      expect(engine.snapshot.round, 1);
      now += walkFirst ? short.walk : short.run;
      expect(
        engine.snapshot.phase,
        walkFirst ? IntervalPhase.run : IntervalPhase.walk,
      );
      expect(engine.snapshot.completedRounds, 0);
      now = const Duration(seconds: 33);
      expect(engine.snapshot.round, 2);
      expect(engine.snapshot.completedRounds, 1);
      now = const Duration(seconds: 63);
      expect(engine.snapshot.phase, IntervalPhase.finished);
      expect(engine.snapshot.completedRounds, 2);
      expect(engine.snapshot.runTime, const Duration(seconds: 20));
      expect(engine.snapshot.walkTime, const Duration(seconds: 40));
      now += const Duration(hours: 1);
      expect(engine.snapshot.elapsed, const Duration(seconds: 63));
      engine.pause();
      engine.start();
      expect(engine.snapshot.paused, isFalse);
      expect(engine.snapshot.phase, IntervalPhase.finished);
    });
  }

  test('Warmup, final round and cooldown follow exact boundaries', () {
    var now = Duration.zero;
    final engine = IntervalEngine(
      config: defaultIntervalConfig,
      clock: () => now,
    )..start();
    expect(engine.trainingDuration, const Duration(minutes: 34));
    now = const Duration(seconds: 3);
    expect(engine.snapshot.phase, IntervalPhase.warmup);
    now += const Duration(minutes: 5);
    expect(engine.snapshot.phase, IntervalPhase.walk);
    now += const Duration(minutes: 24);
    expect(engine.snapshot.phase, IntervalPhase.cooldown);
    expect(engine.snapshot.completedRounds, 8);
    now += const Duration(minutes: 5);
    expect(engine.snapshot.phase, IntervalPhase.finished);
  });

  for (final seconds in [1, 5, 15, 35]) {
    test('Pause preserves phase and remainder at second $seconds', () {
      var now = Duration.zero;
      final engine = IntervalEngine(config: short, clock: () => now);
      engine.pause();
      engine.resume();
      engine.start();
      now = Duration(seconds: seconds);
      final before = engine.snapshot;
      engine.pause();
      now += const Duration(minutes: 10);
      engine.pause();
      expect(engine.snapshot.remaining, before.remaining);
      expect(engine.snapshot.phase, before.phase);
      engine.resume();
      engine.resume();
      engine.start();
      expect(engine.snapshot, before);
      now += const Duration(seconds: 1);
      expect(
        engine.snapshot.elapsed,
        before.elapsed + const Duration(seconds: 1),
      );
      engine.pause();
      now += const Duration(minutes: 2);
      engine.resume();
      expect(
        engine.snapshot.elapsed,
        before.elapsed + const Duration(seconds: 1),
      );
    });
  }

  test('60-minute simulation and delayed poll have no drift', () {
    var now = Duration.zero;
    const config = (
      warmup: Duration.zero,
      run: Duration(minutes: 1),
      walk: Duration(minutes: 1),
      rounds: 30,
      startWithWalk: false,
      cooldown: Duration.zero,
    );
    final regular = IntervalEngine(config: config, clock: () => now)..start();
    final delayed = IntervalEngine(config: config, clock: () => now)..start();
    for (var ms = 0; ms < 3603000; ms += 137) {
      now = Duration(milliseconds: ms);
      final state = regular.snapshot;
      expect(state.elapsed, now);
      if (ms >= 3000) {
        final active = ms - 3000;
        expect(
          state.phase,
          active ~/ 60000 % 2 == 0 ? IntervalPhase.run : IntervalPhase.walk,
        );
        expect(state.round, active ~/ 120000 + 1);
        expect(state.remaining, Duration(milliseconds: 60000 - active % 60000));
      }
    }
    now = const Duration(seconds: 3603);
    expect(regular.snapshot, delayed.snapshot);
    expect(delayed.snapshot.completedRounds, 30);
    expect(delayed.snapshot.runTime, const Duration(minutes: 30));
    expect(delayed.snapshot.phase, IntervalPhase.finished);
  });

  test('Config boundaries are enforced at runtime', () {
    IntervalEngine build({
      Duration warmup = Duration.zero,
      Duration cooldown = Duration.zero,
      Duration run = const Duration(seconds: 10),
      Duration walk = const Duration(seconds: 10),
      int rounds = 1,
    }) => IntervalEngine(
      config: (
        warmup: warmup,
        cooldown: cooldown,
        run: run,
        walk: walk,
        rounds: rounds,
        startWithWalk: false,
      ),
      clock: () => Duration.zero,
    );
    expect(build().trainingDuration, const Duration(seconds: 20));
    expect(
      build(
        warmup: const Duration(minutes: 15),
        cooldown: const Duration(minutes: 15),
        run: const Duration(minutes: 60),
        walk: const Duration(minutes: 60),
        rounds: 50,
      ).trainingDuration,
      const Duration(minutes: 6030),
    );
    for (final invalid in [
      () => build(warmup: const Duration(microseconds: -1)),
      () => build(cooldown: const Duration(minutes: 16)),
      () => build(warmup: const Duration(minutes: 16)),
      () => build(cooldown: const Duration(microseconds: -1)),
      () => build(run: const Duration(seconds: 9)),
      () => build(walk: const Duration(seconds: 9)),
      () => build(run: const Duration(seconds: 3601)),
      () => build(walk: const Duration(seconds: 3601)),
      () => build(rounds: 0),
      () => build(rounds: 51),
    ]) {
      expect(invalid, throwsArgumentError);
    }
  });

  test('Free rounds mode loops indefinitely without auto-finish', () {
    var now = Duration.zero;
    const freeConfig = (
      warmup: Duration.zero,
      run: Duration(seconds: 10),
      walk: Duration(seconds: 20),
      rounds: null,
      startWithWalk: false,
      cooldown: Duration.zero,
    );
    final engine = IntervalEngine(config: freeConfig, clock: () => now);
    expect(engine.trainingDuration, isNull);
    engine.start();

    // Countdown: 0-3s
    expect(engine.snapshot.phase, IntervalPhase.countdown);

    // Round 1: Run (3-13s)
    now = const Duration(seconds: 5);
    expect(engine.snapshot.phase, IntervalPhase.run);
    expect(engine.snapshot.round, 1);
    expect(engine.snapshot.remaining, const Duration(seconds: 8));

    // Round 1: Walk (13-33s)
    now = const Duration(seconds: 15);
    expect(engine.snapshot.phase, IntervalPhase.walk);
    expect(engine.snapshot.round, 1);
    expect(engine.snapshot.completedRounds, 0);

    // Round 2: Run (33-43s)
    now = const Duration(seconds: 35);
    expect(engine.snapshot.phase, IntervalPhase.run);
    expect(engine.snapshot.round, 2);
    expect(engine.snapshot.completedRounds, 1);

    // Round 10: at 3 + 9 * 30 + 5 = 278s
    now = const Duration(seconds: 278);
    expect(engine.snapshot.phase, IntervalPhase.run);
    expect(engine.snapshot.round, 10);
    expect(engine.snapshot.completedRounds, 9);

    // Engine never finishes automatically in free mode
    now = const Duration(hours: 5);
    expect(engine.snapshot.phase, isNot(IntervalPhase.finished));
  });
}
