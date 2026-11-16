import 'dart:convert';

import 'interval_engine.dart';

enum IntervalPreset { beginner, classic, fiveOne, levelUp }

IntervalConfig intervalPreset(IntervalPreset preset) => (
  warmup: defaultIntervalConfig.warmup,
  cooldown: defaultIntervalConfig.cooldown,
  run: Duration(minutes: preset == IntervalPreset.levelUp ? 2 : 1),
  walk: Duration(
    minutes: switch (preset) {
      IntervalPreset.beginner => 2,
      IntervalPreset.fiveOne => 5,
      _ => 1,
    },
  ),
  rounds: switch (preset) {
    IntervalPreset.classic => 10,
    IntervalPreset.fiveOne => 6,
    _ => 8,
  },
  startWithWalk: preset == IntervalPreset.fiveOne,
);

String encodeInterval(IntervalConfig config) => jsonEncode({
  'warmup': config.warmup.inMicroseconds,
  'run': config.run.inMicroseconds,
  'walk': config.walk.inMicroseconds,
  'rounds': config.rounds, // null = bebas
  'startWithWalk': config.startWithWalk,
  'cooldown': config.cooldown.inMicroseconds,
});

IntervalConfig decodeInterval(String source) {
  final Object? data = jsonDecode(source);
  if (data case {
    'warmup': final int warmup,
    'run': final int run,
    'walk': final int walk,
    'startWithWalk': final bool startWithWalk,
    'cooldown': final int cooldown,
  }) {
    final Object? rawRounds = (data as Map<String, Object?>)['rounds'];
    final int? rounds = rawRounds as int?;
    final config = (
      warmup: Duration(microseconds: warmup),
      run: Duration(microseconds: run),
      walk: Duration(microseconds: walk),
      rounds: rounds,
      startWithWalk: startWithWalk,
      cooldown: Duration(microseconds: cooldown),
    );
    try {
      IntervalEngine(config: config, clock: () => Duration.zero);
    } on ArgumentError {
      throw const FormatException('Invalid interval configuration');
    }
    return config;
  }
  throw const FormatException('Invalid interval configuration');
}
