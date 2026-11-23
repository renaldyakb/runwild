import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/duration_format.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_motion.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/stats/stats_engine.dart';
import '../../../domain/tracking/run_summary.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../foundation/application/home_stats_provider.dart';
import '../application/activity_sync.dart';
import '../application/run_journal.dart';

String _formatDuration(Duration duration) => formatClockDuration(duration);

String _formatPace(double? secondsPerKm) {
  if (secondsPerKm == null || secondsPerKm <= 0 || secondsPerKm.isInfinite) {
    return '—';
  }
  final totalSec = secondsPerKm.round();
  final m = totalSec ~/ 60;
  final s = totalSec % 60;
  return '$m\'${s.toString().padLeft(2, '0')}"';
}

class RunSummaryScreen extends ConsumerStatefulWidget {
  const RunSummaryScreen({required this.summary, super.key});
  final RunSummary summary;

  @override
  ConsumerState<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends ConsumerState<RunSummaryScreen> {
  late RunFeeling? _feeling;
  late final TextEditingController _noteController;
  bool _saving = false;
  List<LatLngPoint> _routePoints = const [];

  @override
  void initState() {
    super.initState();
    _feeling = widget.summary.feeling;
    _noteController = TextEditingController(text: widget.summary.note ?? '');
    _loadRoutePoints();
  }

  Future<void> _loadRoutePoints() async {
    final sessionId = widget.summary.sessionId;
    if (sessionId != null) {
      try {
        final pts = await ref.read(runJournalProvider).sessionPoints(sessionId);
        if (mounted && pts.isNotEmpty) {
          setState(() {
            _routePoints = [
              for (final p in pts)
                (latitude: p.latitude, longitude: p.longitude),
            ];
          });
        }
      } on Object catch (error) {
        debugPrint('Load summary route failed: ${error.runtimeType}');
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final owner = ref.read(runOwnerProvider)();
    final sessionId = widget.summary.sessionId;
    if (owner != null && sessionId != null) {
      try {
        final journal = ref.read(runJournalProvider);
        await journal.updateSummary(
          owner,
          sessionId,
          feeling: _feeling?.name,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
        // Memicu sinkronisasi antrean offline ke Firestore di latar belakang
        unawaited(ref.read(activitySyncRepositoryProvider).syncPending(owner));
      } on Object catch (error) {
        debugPrint('Summary update/sync failed: ${error.runtimeType}');
      }
    }
    if (mounted) {
      context.go('/');
    }
  }

  Future<void> _discard() async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.summaryDiscard),
        content: Text(s.summaryDiscardPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.runCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: RwColors.danger500),
            child: Text(s.summaryDiscard),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final owner = ref.read(runOwnerProvider)();
    final sessionId = widget.summary.sessionId;
    if (owner != null && sessionId != null) {
      try {
        await ref.read(runJournalProvider).discardSession(owner, sessionId);
      } on Object catch (error) {
        debugPrint('Discard summary failed: ${error.runtimeType}');
      }
    }
    if (mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final summary = widget.summary;
    final movingFormatted = _formatDuration(summary.movingTime);
    final avgPaceFormatted = _formatPace(summary.averagePace);
    final records = ref.watch(personalRecordsProvider).value;
    final pbs = records != null
        ? StatsEngine.detectPersonalBestsForSession(
            startedAt: summary.startedAt,
            records: records,
          )
        : const <String>[];

    final startedLabel = DateFormat(
      'EEEE, d MMM yyyy · HH:mm',
      s.localeName,
    ).format(summary.startedAt);
    final hasPb = pbs.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.summaryTitle,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: RwColors.paper100,
          border: Border(top: BorderSide(color: RwColors.borderCard)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(RwSpace.md),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: RwButton.secondary(
                    label: s.summaryShare,
                    icon: Icons.share_rounded,
                    onPressed: _saving
                        ? null
                        : () =>
                              context.push('/run/share', extra: widget.summary),
                  ),
                ),
                const SizedBox(width: RwSpace.sm),
                Expanded(
                  flex: 6,
                  child: RwButton.primary(
                    label: s.summarySave,
                    loading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: RwPage(
          children: [
            // ── Unified Celebration / Personal Best Header ──────────
            Container(
              padding: const EdgeInsets.all(RwSpace.md),
              decoration: BoxDecoration(
                color: hasPb ? RwColors.lime500 : RwColors.ink950,
                borderRadius: BorderRadius.circular(RwRadius.lg),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: hasPb ? RwColors.ink950 : RwColors.lime500,
                      borderRadius: BorderRadius.circular(RwRadius.pill),
                    ),
                    child: Icon(
                      hasPb ? Icons.emoji_events_outlined : Icons.flag_rounded,
                      color: hasPb ? RwColors.lime500 : RwColors.ink950,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: RwSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPb ? s.personalBestTitle : s.summaryCelebration,
                          style: TextStyle(
                            fontFamily: RwType.family,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: hasPb ? RwColors.ink950 : RwColors.paper100,
                          ),
                        ),
                        if (hasPb) ...[
                          const SizedBox(height: 2),
                          Text(
                            s.personalBestDetails(pbs.join(' & ')),
                            style: const TextStyle(
                              fontFamily: RwType.family,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: RwColors.ink950,
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          startedLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: RwType.family,
                            color: hasPb ? RwColors.ink800 : RwColors.paper200,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RwSpace.md),

            // ── Main Metrics Card ───────────────────────────────────
            RwEntrance(
              order: 1,
              child: RwCard(
                padding: const EdgeInsets.all(RwSpace.lg),
                child: Column(
                  children: [
                    RwCountUp(
                      value: summary.distanceMeters / 1000.0,
                      builder: (_, value) => Text(
                        value.toStringAsFixed(2),
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 54,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: RwColors.ink950,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.distanceUnit.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: RwColors.mutedTextOnLight,
                      ),
                    ),
                    const SizedBox(height: RwSpace.md),
                    const Divider(color: RwColors.borderCard, height: 1),
                    const SizedBox(height: RwSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: _StatColumn(
                            label: s.runMovingTime,
                            value: movingFormatted,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: RwColors.borderCard,
                        ),
                        Expanded(
                          child: _StatColumn(
                            label: s.runAveragePace,
                            value: '$avgPaceFormatted/km',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: RwColors.borderCard,
                        ),
                        Expanded(
                          child: _StatColumn(
                            label: s.summaryCalories,
                            value: s.summaryCaloriesUnit(
                              summary.estimatedCalories,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: RwSpace.md),

            // ── Visual Rute Lari ────────────────────────────────────
            if (_routePoints.isNotEmpty) ...[
              RwCard(
                padding: const EdgeInsets.all(RwSpace.sm),
                child: SizedBox(
                  height: 168,
                  child: RunRouteView(
                    points: _routePoints,
                    routeColor: RwColors.lime700,
                    strokeWidth: 3.5,
                  ),
                ),
              ),
              const SizedBox(height: RwSpace.md),
            ],

            // ── Interval Summary (Bila Ada) ─────────────────────────
            if (summary.interval != null) ...[
              _IntervalSummaryCard(interval: summary.interval!),
              const SizedBox(height: RwSpace.md),
            ],

            // ── Splits per Kilometer ────────────────────────────────
            if (summary.splits.isNotEmpty) ...[
              _SplitsCard(splits: summary.splits),
              const SizedBox(height: RwSpace.md),
            ],

            // ── Feeling / RPE Rating (Ikon Atletis Tanpa Emoji) ─────
            RwCard(
              padding: const EdgeInsets.all(RwSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.summaryFeelingQuestion,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: RwSpace.sm),
                  RwSegmentedControl<RunFeeling?>(
                    items: [
                      RwSegmentItem(
                        value: RunFeeling.easy,
                        label: s.summaryFeelingEasy,
                        icon: Icons.sentiment_satisfied_alt_rounded,
                      ),
                      RwSegmentItem(
                        value: RunFeeling.normal,
                        label: s.summaryFeelingNormal,
                        icon: Icons.speed_rounded,
                      ),
                      RwSegmentItem(
                        value: RunFeeling.hard,
                        label: s.summaryFeelingHard,
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ],
                    selectedValue: _feeling,
                    onChanged: (val) => setState(() => _feeling = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RwSpace.md),

            // ── Catatan Sesi ────────────────────────────────────────
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: s.summaryNote,
                hintText: s.summaryNoteHint,
                isDense: true,
                filled: true,
                fillColor: RwColors.paper100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  borderSide: const BorderSide(color: RwColors.borderCard),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  borderSide: const BorderSide(color: RwColors.borderCard),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: RwSpace.md),
            Center(
              child: TextButton(
                onPressed: _saving ? null : _discard,
                style: TextButton.styleFrom(
                  foregroundColor: RwColors.danger500,
                ),
                child: Text(s.summaryDiscard),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            fontFeatures: [FontFeature.tabularFigures()],
            color: RwColors.ink950,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: RwColors.mutedTextOnLight,
          ),
        ),
      ],
    );
  }
}

class _IntervalSummaryCard extends StatelessWidget {
  const _IntervalSummaryCard({required this.interval});
  final IntervalSummary interval;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final roundText = interval.totalRounds != null
        ? s.summaryIntervalRoundsTotal(
            interval.completedRounds,
            interval.totalRounds!,
          )
        : s.summaryIntervalRounds(interval.completedRounds);

    return RwCard(
      padding: const EdgeInsets.all(RwSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.repeat_rounded,
                size: 18,
                color: RwColors.lime700,
              ),
              const SizedBox(width: RwSpace.xs),
              Text(
                s.summaryIntervalStats,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.sm),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: s.summaryRoundsLabel,
                  value: roundText,
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: s.intervalRun,
                  value: _formatDuration(interval.runTime),
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: s.intervalWalk,
                  value: _formatDuration(interval.walkTime),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitsCard extends StatelessWidget {
  const _SplitsCard({required this.splits});
  final List<KmSplit> splits;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);

    // Cari split tercepat untuk diberi highlight
    double minPace = double.infinity;
    for (final split in splits) {
      if (split.paceSecondsPerKm > 0 && split.paceSecondsPerKm < minPace) {
        minPace = split.paceSecondsPerKm;
      }
    }

    return RwCard(
      padding: const EdgeInsets.all(RwSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, size: 18, color: RwColors.lime700),
              const SizedBox(width: RwSpace.xs),
              Text(
                s.summarySplits,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.sm),
          for (final split in splits) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      s.summarySplitKm(split.kilometer),
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: RwSpace.sm),
                  Text(
                    _formatDuration(split.duration),
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 13,
                      color: RwColors.mutedTextOnLight,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_formatPace(split.paceSecondsPerKm)} /km',
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: split.paceSecondsPerKm == minPace
                          ? RwColors.lime700
                          : RwColors.ink950,
                    ),
                  ),
                  if (split.paceSecondsPerKm == minPace) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: RwColors.lime700,
                    ),
                  ],
                ],
              ),
            ),
            if (split != splits.last)
              const Divider(color: RwColors.borderCard, height: 1),
          ],
        ],
      ),
    );
  }
}
