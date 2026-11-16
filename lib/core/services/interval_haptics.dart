import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/interval/interval_cues.dart';

abstract interface class IntervalHaptics {
  Future<void> vibrate(IntervalCue cue);
  Future<void> sessionFinished();
}

final intervalHapticsProvider = Provider<IntervalHaptics>((ref) {
  return const DeviceIntervalHaptics();
});

class DeviceIntervalHaptics implements IntervalHaptics {
  const DeviceIntervalHaptics({this.delay = const Duration(milliseconds: 150)});

  final Duration delay;

  @override
  Future<void> vibrate(IntervalCue cue) async {
    switch (cue) {
      case IntervalCue.run:
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(delay);
        await HapticFeedback.mediumImpact();
      case IntervalCue.walk:
        await HapticFeedback.heavyImpact();
      case IntervalCue.runTenSeconds:
      case IntervalCue.walkTenSeconds:
        await HapticFeedback.selectionClick();
      case IntervalCue.general:
        await HapticFeedback.lightImpact();
    }
  }

  @override
  Future<void> sessionFinished() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(delay);
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(delay);
    await HapticFeedback.mediumImpact();
  }
}
