import 'interval_engine.dart';

enum IntervalCue { run, walk, runTenSeconds, walkTenSeconds, general }

/// Emits only current cues; missed phases are never replayed after suspension.
final class IntervalCues {
  (IntervalPhase, int)? _phase;
  bool _paused = false;
  bool _warned = false;

  IntervalCue? update(IntervalSnapshot snapshot) {
    if (snapshot.phase == IntervalPhase.idle ||
        snapshot.phase == IntervalPhase.countdown) {
      return null;
    }
    final phase = (snapshot.phase, snapshot.round);
    if (snapshot.paused != _paused) {
      _paused = snapshot.paused;
      return IntervalCue.general;
    }
    if (_paused) return null;
    if (_phase != phase) {
      _phase = phase;
      _warned = snapshot.remaining <= const Duration(seconds: 10);
      return switch (snapshot.phase) {
        IntervalPhase.run => IntervalCue.run,
        IntervalPhase.walk => IntervalCue.walk,
        _ => IntervalCue.general,
      };
    }
    if (!_warned && snapshot.remaining <= const Duration(seconds: 10)) {
      _warned = true;
      if (snapshot.remaining < const Duration(seconds: 9)) return null;
      return switch (snapshot.phase) {
        IntervalPhase.run => IntervalCue.runTenSeconds,
        IntervalPhase.walk => IntervalCue.walkTenSeconds,
        _ => null,
      };
    }
    return null;
  }
}
