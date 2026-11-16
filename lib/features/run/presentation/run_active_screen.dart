import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/map_limits.dart';
import '../../../core/services/map_service.dart';
import '../../../core/services/run_wakelock.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_hold_button.dart';
import '../../../design/components/rw_loading.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/interval/interval_engine.dart';
import '../../../domain/tracking/run_summary.dart';
import '../../../domain/tracking/tracking_engine.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/run_gps_probe.dart';
import '../application/run_journal.dart';

final runCountdownClockProvider = Provider<Duration Function()>((ref) {
  final stopwatch = Stopwatch()..start();
  return () => stopwatch.elapsed;
});

class RunActiveScreen extends ConsumerStatefulWidget {
  const RunActiveScreen({this.resume, super.key});

  final RunCheckpoint? resume;

  @override
  ConsumerState<RunActiveScreen> createState() => _RunActiveScreenState();
}

class _RunActiveScreenState extends ConsumerState<RunActiveScreen>
    with WidgetsBindingObserver {
  static const _countdownDuration = Duration(seconds: 3);
  static const _unlockDuration = Duration(seconds: 1);
  Timer? _countdownTimer;
  Timer? _unlockTimer;
  int _remaining = _countdownDuration.inSeconds;
  bool _locked = false;
  bool _confirming = false;
  bool _ending = false;
  bool _readyToLeave = false;
  bool _saveFailed = false;
  int _tab = 0;
  late final RunWakelock _wakelock;

  @override
  void initState() {
    super.initState();
    _wakelock = ref.read(runWakelockProvider);
    unawaited(_wakelock.enable());
    WidgetsBinding.instance.addObserver(this);
    if (widget.resume != null) {
      _remaining = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start();
      });
      return;
    }
    final clock = ref.read(runCountdownClockProvider);
    final startedAt = clock();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = _countdownDuration - (clock() - startedAt);
      if (remaining > Duration.zero) {
        setState(
          () => _remaining =
              (remaining.inMilliseconds / Duration.millisecondsPerSecond)
                  .ceil(),
        );
        return;
      }
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) return;
      _countdownTimer?.cancel();
      setState(() => _remaining = 0);
      _start();
    });
  }

  @override
  void dispose() {
    unawaited(_wakelock.disable());
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _unlockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _remaining == 0 && !_ending) {
      unawaited(ref.read(activeRunProvider.notifier).flushCheckpoint());
    }
  }

  void _start() {
    final s = AppLocalizations.of(context);
    unawaited(
      ref
          .read(activeRunProvider.notifier)
          .start(
            notificationTitle: s.runGpsNotificationTitle,
            notificationText: s.runSessionNotificationText,
            activeSession: true,
            resume: widget.resume,
          ),
    );
  }

  Future<void> _finish({bool skipDialog = false}) async {
    if (_locked || _confirming || _ending) return;
    if (_remaining == 0 && !_saveFailed && !skipDialog) {
      _confirming = true;
      final s = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(s.runFinishPrompt),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(s.runCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(s.runFinish),
            ),
          ],
        ),
      );
      _confirming = false;
      if (!mounted || confirmed != true) return;
    }
    _ending = true;
    _countdownTimer?.cancel();
    RunSummary? summary;
    try {
      final session = ref.read(activeRunProvider.notifier);
      if (_remaining > 0) {
        await session.stop();
      } else {
        summary = await session.finishSession();
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _ending = false;
          _saveFailed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _readyToLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (summary != null) {
        context.pushReplacement('/run/summary', extra: summary);
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
    });
  }

  void _unlock() {
    _unlockTimer?.cancel();
    if (_locked) setState(() => _locked = false);
  }

  String _time(int seconds) =>
      '${(seconds ~/ Duration.secondsPerMinute).toString().padLeft(2, '0')}:${(seconds % Duration.secondsPerMinute).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final session = ref.watch(activeRunProvider);
    final recorder = ref.read(activeRunProvider.notifier);
    final interval = recorder.interval;
    final intervalFinished = interval?.phase == IntervalPhase.finished;
    final paused =
        session.tracking == TrackingState.manuallyPaused ||
        session.tracking == TrackingState.autoPaused;
    final failed =
        session.status == GpsProbeStatus.failed ||
        session.status == GpsProbeStatus.stopped;
    final route = recorder.liveRoute;
    final distance = NumberFormat.decimalPatternDigits(
      locale: s.localeName,
      decimalDigits: 2,
    ).format(session.meters / 1000);
    final pace = session.pace;
    final status = switch (session.status) {
      GpsProbeStatus.failed => s.runGpsError,
      _ when intervalFinished => s.intervalFinished,
      _ when paused =>
        session.tracking == TrackingState.autoPaused
            ? s.runAutoPaused
            : s.runPaused,
      GpsProbeStatus.waiting || GpsProbeStatus.idle => s.runGpsWaiting,
      _ => s.runGpsRecording,
    };
    if (_ending) return const Scaffold(body: RwFullPageLoading());
    return PopScope(
      canPop: _readyToLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_finish());
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(s.runActiveTitle),
          actions: [
            if (_remaining == 0 && !_locked && interval != null)
              Semantics(
                toggled: recorder.audioEnabled,
                child: IconButton(
                  tooltip: s.intervalAudioEnabled,
                  onPressed: () =>
                      recorder.setAudioEnabled(!recorder.audioEnabled),
                  icon: Icon(
                    recorder.audioEnabled
                        ? Icons.volume_up_outlined
                        : Icons.volume_off_outlined,
                  ),
                ),
              ),
          ],
        ),
        body: RwPage(
          children: [
            if (_remaining > 0) ...[
              const SizedBox(height: RwSpace.xxl),
              Text(
                s.runCountdown,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: RwSpace.xl),
              Center(
                child: Container(
                  width: RwSize.countdownCircle,
                  height: RwSize.countdownCircle,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: RwColors.lime500,
                    shape: BoxShape.circle,
                  ),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      '$_remaining',
                      style: theme.textTheme.displayLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: RwSpace.xl),
              Text(s.runStartHint, textAlign: TextAlign.center),
            ] else ...[
              RwSegmentedControl<int>(
                items: [
                  RwSegmentItem(
                    value: 0,
                    label: s.runLiveTab,
                    icon: Icons.speed_rounded,
                  ),
                  RwSegmentItem(
                    value: 1,
                    label: s.runRouteTab,
                    icon: Icons.map_outlined,
                  ),
                  RwSegmentItem(
                    value: 2,
                    label: s.runHistoryTab,
                    icon: Icons.splitscreen_rounded,
                  ),
                ],
                selectedValue: _tab,
                onChanged: _locked
                    ? null
                    : (index) => setState(() => _tab = index),
              ),
              const SizedBox(height: RwSpace.md),
              Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      failed
                          ? Icons.info_outline
                          : paused
                          ? Icons.pause_circle_outline
                          : Icons.gps_fixed,
                      color: failed
                          ? theme.colorScheme.error
                          : RwColors.lime700,
                      size: RwSize.icon,
                    ),
                    const SizedBox(width: RwSpace.xs),
                    Expanded(child: Text(status)),
                  ],
                ),
              ),
              if (_saveFailed || recorder.storageFailed) ...[
                const SizedBox(height: RwSpace.sm),
                Text(
                  s.runStorageFailed,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              if (recorder.audioFailed && interval != null) ...[
                const SizedBox(height: RwSpace.sm),
                Text(s.intervalAudioError),
              ],
              const SizedBox(height: RwSpace.lg),
              if (_tab == 0) ...[
                RwCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(s.runDistance, style: theme.textTheme.labelSmall),
                      const SizedBox(height: RwSpace.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            distance,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: RwSpace.md),
                      const Divider(),
                      const SizedBox(height: RwSpace.md),
                      Wrap(
                        spacing: RwSpace.xl,
                        runSpacing: RwSpace.md,
                        children: [
                          _Metric(
                            label: s.runMovingTime,
                            value: _time(session.moving.inSeconds),
                          ),
                          _Metric(
                            label: s.runAveragePace,
                            value: pace == null
                                ? s.homeMetricEmpty
                                : s.runPaceUnit(_time(pace.round())),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (interval != null) ...[
                  const SizedBox(height: RwSpace.md),
                  RwCard(
                    color: RwColors.lime100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(switch (interval.phase) {
                          IntervalPhase.warmup => s.intervalWarmup,
                          IntervalPhase.run => s.intervalRun,
                          IntervalPhase.walk => s.intervalWalk,
                          IntervalPhase.cooldown => s.intervalCooldown,
                          IntervalPhase.finished => s.intervalFinished,
                          _ => s.runCountdown,
                        }, style: theme.textTheme.titleLarge),
                        if (!intervalFinished) ...[
                          const SizedBox(height: RwSpace.sm),
                          Text(
                            _time(
                              (interval.remaining.inMilliseconds /
                                      Duration.millisecondsPerSecond)
                                  .ceil(),
                            ),
                            style: theme.textTheme.displayMedium,
                          ),
                        ],
                        if (interval.round > 0) ...[
                          const SizedBox(height: RwSpace.xs),
                          Text(switch (recorder.intervalRounds) {
                            final rounds? => s.intervalRound(
                              interval.round,
                              rounds,
                            ),
                            null => s.intervalRoundFree(interval.round),
                          }),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: RwSpace.md),
                if (route.position case final position?)
                  Text(
                    (route.age ?? MapLimits.staleAfter) >= MapLimits.staleAfter
                        ? s.mapStale
                        : s.mapAccuracy(position.accuracyMeters.ceil()),
                  ),
              ] else if (_tab == 1) ...[
                ref
                    .read(mapServiceProvider)
                    .buildLiveMap(route: route, locked: _locked),
              ] else ...[
                Text(s.runSessionHistory, style: theme.textTheme.titleLarge),
                const SizedBox(height: RwSpace.sm),
                Text(s.runSessionHistoryHint),
                if (widget.resume != null) Text(s.runRecoveredSplitsHint),
                if (interval != null) ...[
                  const SizedBox(height: RwSpace.md),
                  RwCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          s.summaryIntervalRounds(interval.completedRounds),
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: RwSpace.sm),
                        Text(
                          s.summaryIntervalRunTime(
                            _time(interval.runTime.inSeconds),
                          ),
                        ),
                        Text(
                          s.summaryIntervalWalkTime(
                            _time(interval.walkTime.inSeconds),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: RwSpace.lg),
                Text(s.summarySplits, style: theme.textTheme.titleMedium),
                const SizedBox(height: RwSpace.md),
                if (recorder.liveSplits.isEmpty)
                  RwCard(child: Text(s.runSplitsEmpty)),
                for (final split in recorder.liveSplits) ...[
                  RwCard(
                    child: Wrap(
                      spacing: RwSpace.lg,
                      runSpacing: RwSpace.sm,
                      children: [
                        _Metric(
                          label: s.summarySplitKm(split.kilometer),
                          value: s.runSplitMeters(split.distanceMeters.round()),
                        ),
                        _Metric(
                          label: s.runMovingTime,
                          value: _time(split.duration.inSeconds),
                        ),
                        _Metric(
                          label: s.runAveragePace,
                          value: s.runPaceUnit(
                            _time(split.paceSecondsPerKm.round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: RwSpace.sm),
                ],
              ],
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              RwSpace.screen,
              RwSpace.sm,
              RwSpace.screen,
              RwSpace.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_remaining > 0)
                  RwButton.secondary(label: s.runCancel, onPressed: _finish)
                else if (_locked) ...[
                  Text(s.runLocked, textAlign: TextAlign.center),
                  Semantics(
                    button: true,
                    label: s.runUnlock,
                    onTap: _unlock,
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (_) =>
                          _unlockTimer = Timer(_unlockDuration, _unlock),
                      onTapUp: (_) => _unlockTimer?.cancel(),
                      onTapCancel: () => _unlockTimer?.cancel(),
                      child: Container(
                        padding: const EdgeInsets.all(RwSpace.md),
                        decoration: BoxDecoration(
                          color: RwColors.lime100,
                          borderRadius: BorderRadius.circular(RwRadius.pill),
                        ),
                        child: Text(s.runUnlock, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ] else ...[
                  if (!failed && !intervalFinished) ...[
                    RwButton.primary(
                      label: paused ? s.runResume : s.runPause,
                      icon: paused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      onPressed: recorder.togglePause,
                    ),
                    const SizedBox(height: RwSpace.xs),
                  ],
                  Row(
                    children: [
                      if (!failed && !intervalFinished) ...[
                        Expanded(
                          child: RwButton.secondary(
                            label: s.runLock,
                            icon: Icons.lock_outline,
                            onPressed: () => setState(() => _locked = true),
                          ),
                        ),
                        const SizedBox(width: RwSpace.xs),
                      ],
                      Expanded(
                        child: _saveFailed
                            ? RwButton.secondary(
                                label: s.retry,
                                onPressed: () => _finish(skipDialog: true),
                              )
                            : RwHoldToFinishButton(
                                label: s.runFinish,
                                onHoldCompleted: () =>
                                    _finish(skipDialog: true),
                                onTapShort: () => _finish(skipDialog: false),
                              ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: RwSpace.xxs),
      Text(value, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}
