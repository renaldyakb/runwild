import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/stats/stats_engine.dart';
import '../../../domain/tracking/run_summary.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../foundation/application/home_stats_provider.dart';
import '../application/activity_sync.dart';
import '../application/run_journal.dart';

String _formatDuration(Duration duration) {
  final seconds = duration.inSeconds;
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

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
      } catch (_) {}
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
      } catch (_) {
        // Abaikan error jaringan/penyimpanan sekunder agar user tidak tertahan
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
      } catch (_) {}
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
    final distanceKm = (summary.distanceMeters / 1000.0).toStringAsFixed(2);
    final movingFormatted = _formatDuration(summary.movingTime);
    final avgPaceFormatted = _formatPace(summary.averagePace);
    final records = ref.watch(personalRecordsProvider).value;
    final pbs = records != null
        ? StatsEngine.detectPersonalBestsForSession(
            startedAt: summary.startedAt,
            records: records,
          )
        : const <String>[];

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
      body: SafeArea(
        child: RwPage(
          children: [
            // ── PB / Personal Best Banner ───────────────────────────
            if (pbs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: RwSpace.md,
                  vertical: RwSpace.sm,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEAF854), Color(0xFFC7F000)],
                  ),
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  border: Border.all(color: RwColors.lime700, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: RwColors.lime500.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: RwColors.ink950,
                        borderRadius: BorderRadius.circular(RwRadius.pill),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: RwColors.lime500,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: RwSpace.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'REKOR PRIBADI BARU! 🏆',
                            style: TextStyle(
                              fontFamily: RwType.family,
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.3,
                              color: RwColors.ink950,
                            ),
                          ),
                          Text(
                            'Luar biasa! Kamu memecahkan ${pbs.join(' & ')}.',
                            style: const TextStyle(
                              fontFamily: RwType.family,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: RwColors.ink950,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: RwSpace.sm),
            ],

            // ── Celebration Banner ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: RwSpace.md,
                vertical: RwSpace.sm,
              ),
              decoration: BoxDecoration(
                color: RwColors.lime100,
                borderRadius: BorderRadius.circular(RwRadius.md),
                border: Border.all(color: RwColors.lime500, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(RwSpace.xs),
                    decoration: BoxDecoration(
                      color: RwColors.lime500,
                      borderRadius: BorderRadius.circular(RwRadius.pill),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      color: RwColors.ink950,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: RwSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.summaryCelebration,
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                            fontSize: 15,
                            color: RwColors.ink950,
                          ),
                        ),
                        Text(
                          '${summary.startedAt.day}/${summary.startedAt.month}/${summary.startedAt.year} · ${_formatDuration(Duration(hours: summary.startedAt.hour, minutes: summary.startedAt.minute))}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontFamily: RwType.family,
                            color: RwColors.mutedTextOnLight,
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
            RwCard(
              padding: const EdgeInsets.all(RwSpace.lg),
              child: Column(
                children: [
                  Text(
                    distanceKm,
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
                  const SizedBox(height: 4),
                  const Text(
                    'KILOMETER',
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                  const SizedBox(height: RwSpace.md),
                  const Divider(color: Color(0xFFE2E6DC), height: 1),
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
                        color: const Color(0xFFE2E6DC),
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
                        color: const Color(0xFFE2E6DC),
                      ),
                      Expanded(
                        child: _StatColumn(
                          label: s.summaryCalories,
                          value: '${summary.estimatedCalories} kkal',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: RwSpace.md),

            // ── Visual Histori Rute Lari Presisi ────────────────────
            if (_routePoints.isNotEmpty) ...[
              Container(
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
                ),
                padding: const EdgeInsets.all(10),
                child: Stack(
                  children: [
                    RunRouteView(
                      points: _routePoints,
                      routeColor: RwColors.lime600,
                      strokeWidth: 3.5,
                    ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: RwColors.ink950.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(RwRadius.pill),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.route_rounded,
                              size: 12,
                              color: RwColors.lime500,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'HISTORI RUTE PRESISI',
                              style: TextStyle(
                                fontFamily: RwType.family,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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

            // ── Feeling / RPE Rating (Segmented Simetris) ────────────
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
                        label: '🟢 ${s.summaryFeelingEasy}',
                      ),
                      RwSegmentItem(
                        value: RunFeeling.normal,
                        label: '🟡 ${s.summaryFeelingNormal}',
                      ),
                      RwSegmentItem(
                        value: RunFeeling.hard,
                        label: '🔴 ${s.summaryFeelingHard}',
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
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  borderSide: const BorderSide(color: Color(0xFFE2E6DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  borderSide: const BorderSide(color: Color(0xFFE2E6DC)),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: RwSpace.lg),

            // ── Tombol Aksi ─────────────────────────────────────────
            RwButton.primary(
              label: s.summarySave,
              loading: _saving,
              onPressed: _save,
            ),
            const SizedBox(height: RwSpace.xs),
            RwButton.secondary(
              label: s.summaryShare,
              icon: Icons.share_rounded,
              onPressed: () =>
                  context.push('/run/share', extra: widget.summary),
            ),
            const SizedBox(height: RwSpace.xs),
            Center(
              child: TextButton(
                onPressed: _discard,
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
                child: _StatColumn(label: 'Putaran', value: roundText),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Lari',
                  value: _formatDuration(interval.runTime),
                ),
              ),
              Expanded(
                child: _StatColumn(
                  label: 'Jalan',
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
              const Divider(color: Color(0xFFE2E6DC), height: 1),
          ],
        ],
      ),
    );
  }
}
