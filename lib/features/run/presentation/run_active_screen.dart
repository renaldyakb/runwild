import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/map_limits.dart';
import '../../../core/services/map_service.dart';
import '../../../core/services/run_wakelock.dart';
import '../../../core/utils/duration_format.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_hold_button.dart';
import '../../../design/components/rw_loading.dart';
import '../../../design/components/rw_motion.dart';
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
    setState(() => _ending = true);
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

  String _time(int seconds) => formatClockDuration(Duration(seconds: seconds));

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
    if (_ending) {
      return PopScope(
        canPop: false,
        child: Scaffold(
          body: RwFullPageLoading(
            label: s.runFinishing,
            subtitle: s.runFinishingHint,
          ),
        ),
      );
    }
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
                child: RwPhaseSwitcher(
                  child: Container(
                    key: ValueKey(_remaining),
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
                  padding: const EdgeInsets.all(RwSpace.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.runDistance.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: RwColors.mutedTextOnLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: RwSpace.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                distance,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: RwSpace.xs),
                          Text(
                            s.distanceUnit,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: RwColors.mutedTextOnLight,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: RwSpace.md),
                      const Divider(color: RwColors.borderCard, height: 1),
                      const SizedBox(height: RwSpace.md),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _Metric(
                              label: s.runMovingTime,
                              value: _time(session.moving.inSeconds),
                            ),
                          ),
                          const SizedBox(width: RwSpace.sm),
                          Expanded(
                            child: _Metric(
                              label: s.runAveragePace,
                              value: pace == null
                                  ? s.homeMetricEmpty
                                  : s.runPaceUnit(_time(pace.round())),
                            ),
                          ),
                          const SizedBox(width: RwSpace.sm),
                          Expanded(
                            child: _Metric(
                              label: s.summaryCalories,
                              value: s.summaryCaloriesUnit(
                                RunSummary.estimateCalories(session.meters),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (interval != null) ...[
                  const SizedBox(height: RwSpace.md),
                  RwPhaseSwitcher(
                    child: _IntervalPhaseBanner(
                      key: ValueKey(interval.phase),
                      interval: interval,
                      config: recorder.intervalConfig,
                      rounds: recorder.intervalRounds,
                      formatTime: _time,
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
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: RwColors.paper100,
            border: Border(top: BorderSide(color: RwColors.borderCard)),
          ),
          child: SafeArea(
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
                    const SizedBox(height: RwSpace.xs),
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
                            border: Border.all(color: RwColors.lime600),
                          ),
                          child: Text(
                            s.runUnlock,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: RwType.family,
                              fontWeight: FontWeight.w800,
                              color: RwColors.ink950,
                            ),
                          ),
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
      ),
    );
  }
}

class _IntervalPhaseBanner extends StatelessWidget {
  const _IntervalPhaseBanner({
    required this.interval,
    required this.config,
    required this.rounds,
    required this.formatTime,
    super.key,
  });

  final IntervalSnapshot interval;
  final IntervalConfig? config;
  final int? rounds;
  final String Function(int seconds) formatTime;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final phase = interval.phase;
    final isRun = phase == IntervalPhase.run;
    final isWalk = phase == IntervalPhase.walk;
    final isFinished = phase == IntervalPhase.finished;

    final phaseLabel = switch (phase) {
      IntervalPhase.warmup => s.intervalWarmup,
      IntervalPhase.run => s.intervalRun,
      IntervalPhase.walk => s.intervalWalk,
      IntervalPhase.cooldown => s.intervalCooldown,
      IntervalPhase.finished => s.intervalFinished,
      _ => s.runCountdown,
    };

    final totalDuration = switch (phase) {
      IntervalPhase.warmup => config?.warmup,
      IntervalPhase.run => config?.run,
      IntervalPhase.walk => config?.walk,
      IntervalPhase.cooldown => config?.cooldown,
      _ => null,
    };
    final double? progress =
        totalDuration != null && totalDuration > Duration.zero && !isFinished
        ? (1.0 -
                  interval.remaining.inMicroseconds /
                      totalDuration.inMicroseconds)
              .clamp(0.0, 1.0)
        : null;

    final bgColor = isRun
        ? RwColors.ink950
        : isFinished
        ? RwColors.lime500
        : isWalk
        ? RwColors.lime100
        : RwColors.paper100;
    final borderColor = isRun
        ? RwColors.ink950
        : isWalk
        ? RwColors.lime600
        : RwColors.borderCard;
    final titleColor = isRun ? RwColors.lime500 : RwColors.ink950;
    final digitColor = isRun ? RwColors.paper100 : RwColors.ink950;
    final subColor = isRun ? RwColors.paper200 : RwColors.mutedTextOnLight;
    final trackColor = isRun ? RwColors.ink700 : RwColors.chartTrack;
    final fillColor = isRun
        ? RwColors.lime500
        : isWalk
        ? RwColors.lime700
        : RwColors.ink950;

    return RwCard(
      color: bgColor,
      borderColor: borderColor,
      padding: const EdgeInsets.all(RwSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isRun
                    ? Icons.directions_run_rounded
                    : isWalk
                    ? Icons.directions_walk_rounded
                    : isFinished
                    ? Icons.flag_rounded
                    : Icons.timer_outlined,
                size: 20,
                color: titleColor,
              ),
              const SizedBox(width: RwSpace.xs),
              Expanded(
                child: Text(
                  phaseLabel,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (interval.round > 0)
                Text(
                  switch (rounds) {
                    final total? => s.intervalRound(interval.round, total),
                    null => s.intervalRoundFree(interval.round),
                  },
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: subColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (!isFinished) ...[
            const SizedBox(height: RwSpace.xs),
            Text(
              formatTime(
                (interval.remaining.inMilliseconds /
                        Duration.millisecondsPerSecond)
                    .ceil(),
              ),
              style: theme.textTheme.displayMedium?.copyWith(
                color: digitColor,
                fontWeight: FontWeight.w900,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: RwSpace.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(RwRadius.pill),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(fillColor),
              ),
            ),
          ],
        ],
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
      Text(
        label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: RwColors.mutedTextOnLight,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: RwSpace.xxs),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
  );
}
