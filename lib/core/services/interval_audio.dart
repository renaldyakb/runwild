import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../domain/interval/interval_cues.dart';

abstract interface class IntervalAudio {
  bool get failed;
  Future<void> play(IntervalCue cue);
  Future<void> stop();
  Future<void> dispose();
}

final intervalAudioProvider = Provider.autoDispose<IntervalAudio>((ref) {
  final audio = AssetIntervalAudio();
  ref.onDispose(() => unawaited(audio.dispose()));
  return audio;
});

final class AssetIntervalAudio implements IntervalAudio {
  AudioPlayer? _player;
  AudioSession? _session;
  Future<void> _commands = Future.value();
  int _generation = 0;
  bool _disposed = false;
  @override
  bool failed = false;

  static const assets = {
    IntervalCue.run: 'assets/audio/run_run_run.mp3',
    IntervalCue.walk: 'assets/audio/walk_walk.mp3',
    IntervalCue.runTenSeconds: 'assets/audio/ten_seconds_left_to_run.mp3',
    IntervalCue.walkTenSeconds: 'assets/audio/ten_seconds_left_to_walk.mp3',
    IntervalCue.general: 'assets/audio/Sound_effect.mp3',
  };

  Future<void> _configure() async {
    if (_session != null) return;
    _player ??= AudioPlayer(handleAudioSessionActivation: false);
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          usage: AndroidAudioUsage.assistanceNavigationGuidance,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
        androidWillPauseWhenDucked: false,
      ),
    );
    _session = session;
  }

  void _error(Object error, StackTrace stack) {
    failed = true;
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'RUNWILD interval audio',
      ),
    );
  }

  @override
  Future<void> play(IntervalCue cue) {
    final generation = ++_generation;
    _commands = _commands.then((_) async {
      if (_disposed || generation != _generation) return;
      try {
        await _configure();
        final player = _player;
        final session = _session;
        if (player == null || session == null) return;
        await player.stop();
        await player.setAsset(assets[cue] ?? assets.values.last);
        if (_disposed || generation != _generation) return;
        if (!await session.setActive(true)) {
          throw StateError('Audio focus denied');
        }
        if (_disposed || generation != _generation) {
          await _releaseFocus();
          return;
        }
        failed = false;
        unawaited(_playToEnd(player, session, generation));
      } catch (error, stack) {
        _error(error, stack);
        await _releaseFocus();
      }
    });
    return _commands;
  }

  Future<void> _playToEnd(
    AudioPlayer player,
    AudioSession session,
    int generation,
  ) async {
    try {
      await player.play();
    } catch (error, stack) {
      _error(error, stack);
    } finally {
      if (generation == _generation) await _releaseFocus();
    }
  }

  Future<void> _releaseFocus() async {
    try {
      await _session?.setActive(false);
    } catch (error, stack) {
      _error(error, stack);
    }
  }

  @override
  Future<void> stop() {
    ++_generation;
    _commands = _commands.then((_) async {
      try {
        await _player?.stop();
      } catch (error, stack) {
        _error(error, stack);
      }
      await _releaseFocus();
    });
    return _commands;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stop();
    try {
      await _player?.dispose();
    } catch (error, stack) {
      _error(error, stack);
    }
  }
}
