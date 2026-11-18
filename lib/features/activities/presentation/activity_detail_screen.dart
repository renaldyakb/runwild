import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/map_service.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/tracking/activity_detail.dart';
import '../../../domain/tracking/activity_history.dart';
import '../../../domain/tracking/live_route.dart';
import '../../../domain/tracking/run_summary.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/activity_detail_notifier.dart';

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

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({required this.sessionId, super.key});
  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final asyncState = ref.watch(activityDetailProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.activityDetailTitle,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (asyncState.asData?.value != null) ...[
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: s.activityShareButton,
              onPressed: () {
                final detail = asyncState.asData!.value!;
                context.push('/run/share', extra: detail.toRunSummary());
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: s.activityDelete,
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: asyncState.when(
          loading: () => const _DetailSkeleton(),
          error: (error, _) => _DetailError(
            onRetry: () => ref.invalidate(activityDetailProvider(sessionId)),
          ),
          data: (detail) {
            if (detail == null) {
              return const _DetailNotFound();
            }
            return _DetailContent(detail: detail);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.activityDelete),
        content: Text(s.activityDeletePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.runCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.activityDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(activityDetailControllerProvider).deleteSession(sessionId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.activityDeleteSuccess)));
        Navigator.of(context).maybePop();
      }
    }
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  const _DetailContent({required this.detail});
  final ActivityDetail detail;

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  bool _showMap = true;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final distanceKm = NumberFormat.decimalPatternDigits(
      locale: s.localeName,
      decimalDigits: 2,
    ).format(detail.meters / 1000.0);

    final defaultTitle = switch (historyTimeOfDay(detail.startedAt)) {
      HistoryTimeOfDay.morning => s.historyMorning,
      HistoryTimeOfDay.midday => s.historyMidday,
      HistoryTimeOfDay.afternoon => s.historyAfternoon,
      HistoryTimeOfDay.night => s.historyNight,
    };
    final displayTitle = detail.title?.isNotEmpty ?? false
        ? detail.title!
        : defaultTitle;

    final routePoints = [
      for (final p in detail.points)
        (latitude: p.latitude, longitude: p.longitude),
    ];
    final segments = <List<RoutePoint>>[];
    for (final point in detail.points) {
      if (segments.isEmpty || point.segmentStart) segments.add([]);
      segments.last.add((latitude: point.latitude, longitude: point.longitude));
    }
    final segmentStarts = {
      for (var i = 0; i < detail.points.length; i++)
        if (detail.points[i].segmentStart) i,
    };

    return RwPage(
      children: [
        // ── Header Title & Date ─────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: RwColors.ink950,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat(
                      'EEEE, d MMMM yyyy · HH:mm',
                      s.localeName,
                    ).format(detail.startedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: RwType.family,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: s.activityEditTitle,
              onPressed: () => _editTitleAndNote(context),
            ),
          ],
        ),
        const SizedBox(height: RwSpace.md),

        // ── Route Map Preview ───────────────────────────────────────
        if (routePoints.length >= 2) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.activityRouteTitle,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RwColors.ink950,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _showMap = !_showMap),
                borderRadius: BorderRadius.circular(RwRadius.pill),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _showMap ? RwColors.lime100 : RwColors.paper100,
                    borderRadius: BorderRadius.circular(RwRadius.pill),
                    border: Border.all(
                      color: _showMap
                          ? RwColors.lime500
                          : const Color(0xFFE2E6DC),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showMap ? Icons.map_rounded : Icons.route_rounded,
                        size: 14,
                        color: RwColors.ink950,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showMap ? 'Map: ON' : 'Map: OFF',
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: RwColors.ink950,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.xs),
          if (_showMap)
            ref
                .watch(mapServiceProvider)
                .buildLiveMap(
                  route: (segments: segments, position: null, age: null),
                  locked: false,
                  historical: true,
                )
          else
            Container(
              height: RwSize.liveMapHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(RwRadius.lg),
                border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
              ),
              clipBehavior: Clip.antiAlias,
              child: RunRouteView(
                points: routePoints,
                segmentStarts: segmentStarts,
                routeColor: RwColors.lime700,
                strokeWidth: 3.5,
              ),
            ),
          const SizedBox(height: RwSpace.md),
        ] else ...[
          RwCard(
            padding: const EdgeInsets.all(RwSpace.md),
            child: Row(
              children: [
                const Icon(
                  Icons.gps_off_rounded,
                  size: 20,
                  color: RwColors.ink500,
                ),
                const SizedBox(width: RwSpace.sm),
                Expanded(
                  child: Text(
                    s.activityNoRoute,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RwSpace.md),
        ],

        // ── Main Metrics Card ───────────────────────────────────────
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
                    child: _SummaryStat(
                      label: s.runMovingTime,
                      value: _formatDuration(detail.moving),
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: s.runAveragePace,
                      value: _formatPace(detail.averagePace),
                    ),
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: s.summaryCalories,
                      value: '${detail.estimatedCalories}',
                      unit: ' kkal',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: RwSpace.md),

        // ── Interval Summary (Bila Ada) ─────────────────────────────
        if (detail.intervalSummary != null) ...[
          _IntervalSummaryCard(interval: detail.intervalSummary!),
          const SizedBox(height: RwSpace.md),
        ],

        // ── Splits Table ────────────────────────────────────────────
        if (detail.splits.isNotEmpty) ...[
          _SplitsCard(splits: detail.splits),
          const SizedBox(height: RwSpace.md),
        ],

        // ── Notes & Feeling Card ────────────────────────────────────
        RwCard(
          padding: const EdgeInsets.all(RwSpace.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.summaryNote,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (detail.feeling != null)
                    _FeelingBadge(feeling: detail.feeling!),
                ],
              ),
              const SizedBox(height: RwSpace.xs),
              Text(
                detail.note?.isNotEmpty ?? false
                    ? detail.note!
                    : 'Tidak ada catatan tambahan untuk sesi ini.',
                style: TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 13,
                  color: detail.note?.isNotEmpty ?? false
                      ? RwColors.ink950
                      : RwColors.mutedTextOnLight,
                  fontStyle: detail.note?.isNotEmpty ?? false
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
              const SizedBox(height: RwSpace.md),
              RwButton.secondary(
                label: s.activityEditTitle,
                icon: Icons.edit_note_rounded,
                fullWidth: true,
                onPressed: () => _editTitleAndNote(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: RwSpace.md),

        // ── Cloud Sync Status ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RwSpace.md,
            vertical: RwSpace.sm,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(RwRadius.sm),
            border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
          ),
          child: Row(
            children: [
              Icon(
                detail.synced
                    ? Icons.cloud_done_rounded
                    : Icons.cloud_upload_outlined,
                size: 18,
                color: detail.synced ? RwColors.lime700 : RwColors.ink500,
              ),
              const SizedBox(width: RwSpace.sm),
              Expanded(
                child: Text(
                  detail.synced ? s.historySynced : s.historyPending,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: RwType.family,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RwSpace.lg),

        // ── Action Buttons ──────────────────────────────────────────
        RwButton.primary(
          label: s.activityShareButton,
          icon: Icons.share_rounded,
          fullWidth: true,
          onPressed: () {
            context.push('/run/share', extra: detail.toRunSummary());
          },
        ),
        const SizedBox(height: RwSpace.sm),
        RwButton.secondary(
          label: s.activityDelete,
          icon: Icons.delete_outline_rounded,
          fullWidth: true,
          onPressed: () => _confirmDelete(context),
        ),
        const SizedBox(height: RwSpace.xl),
      ],
    );
  }

  Future<void> _editTitleAndNote(BuildContext context) async {
    final detail = widget.detail;
    final result = await showModalBottomSheet<({String title, String note})>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: RwColors.paper100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RwRadius.lg)),
      ),
      builder: (ctx) =>
          _EditTitleSheet(initialTitle: detail.title, initialNote: detail.note),
    );

    if (result != null && context.mounted) {
      await ref
          .read(activityDetailControllerProvider)
          .updateDetails(detail.id, title: result.title, note: result.note);
      if (context.mounted) {
        final s = AppLocalizations.of(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.activitySaveSuccess)));
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final detail = widget.detail;
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.activityDelete),
        content: Text(s.activityDeletePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.runCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.activityDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(activityDetailControllerProvider).deleteSession(detail.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.activityDeleteSuccess)));
        Navigator.of(context).maybePop();
      }
    }
  }
}

class _FeelingBadge extends StatelessWidget {
  const _FeelingBadge({required this.feeling});
  final String feeling;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final (label, color) = switch (feeling) {
      'easy' => ('🟢 ${s.summaryFeelingEasy}', const Color(0xFF15803D)),
      'normal' => ('🟡 ${s.summaryFeelingNormal}', const Color(0xFFB45309)),
      'hard' => ('🔴 ${s.summaryFeelingHard}', const Color(0xFFDC2626)),
      _ => (feeling, RwColors.ink950),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(RwRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: RwType.family,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value, this.unit});
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: RwColors.mutedTextOnLight,
          ),
        ),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: RichText(
          text: TextSpan(
            text: value,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
              color: RwColors.ink950,
            ),
            children: [
              if (unit != null)
                TextSpan(
                  text: unit,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _IntervalSummaryCard extends StatelessWidget {
  const _IntervalSummaryCard({required this.interval});
  final IntervalSummary interval;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final roundsText = interval.totalRounds != null
        ? '${interval.completedRounds} / ${interval.totalRounds}'
        : '${interval.completedRounds} (${s.intervalFree})';

    return RwCard(
      padding: const EdgeInsets.all(RwSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: RwColors.lime700,
              ),
              const SizedBox(width: RwSpace.xs),
              Text(
                s.intervalMode.toUpperCase(),
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: RwColors.ink950,
                ),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.sm),
          Row(
            children: [
              Expanded(
                child: _IntervalStat(label: 'PUTARAN', value: roundsText),
              ),
              Expanded(
                child: _IntervalStat(
                  label: 'WAKTU LARI',
                  value: _formatDuration(interval.runTime),
                ),
              ),
              Expanded(
                child: _IntervalStat(
                  label: 'WAKTU JALAN',
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

class _IntervalStat extends StatelessWidget {
  const _IntervalStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: RwColors.mutedTextOnLight,
          ),
        ),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
            color: RwColors.ink950,
          ),
        ),
      ),
    ],
  );
}

class _SplitsCard extends StatelessWidget {
  const _SplitsCard({required this.splits});
  final List<KmSplit> splits;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return RwCard(
      padding: const EdgeInsets.all(RwSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            s.activitySplitsTitle,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: RwSpace.sm),
          const Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  'KM',
                  style: TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'DURASI',
                  style: TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ),
              Text(
                'PACE',
                style: TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: RwColors.mutedTextOnLight,
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFE2E6DC), height: 16),
          for (final split in splits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${split.kilometer}',
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDuration(split.duration),
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Text(
                    _formatPace(split.paceSecondsPerKm),
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: RwColors.lime700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RwPage(
      children: [
        Container(
          height: 32,
          width: 180,
          decoration: BoxDecoration(
            color: RwColors.paper200,
            borderRadius: BorderRadius.circular(RwRadius.sm),
          ),
        ),
        const SizedBox(height: RwSpace.md),
        Container(
          height: RwSize.liveMapHeight,
          decoration: BoxDecoration(
            color: RwColors.paper200,
            borderRadius: BorderRadius.circular(RwRadius.lg),
          ),
        ),
        const SizedBox(height: RwSpace.md),
        RwCard(
          child: Column(
            children: [
              Container(height: 54, width: 120, color: RwColors.paper200),
              const SizedBox(height: RwSpace.md),
              Container(height: 32, color: RwColors.paper200),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DetailNotFound extends StatelessWidget {
  const _DetailNotFound();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RwSpace.lg),
        child: RwCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: RwSize.touch,
                color: RwColors.ink500,
              ),
              const SizedBox(height: RwSpace.md),
              Text(
                s.activityNotFound,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: RwSpace.xs),
              Text(s.activityNotFoundBody, textAlign: TextAlign.center),
              const SizedBox(height: RwSpace.lg),
              RwButton.primary(
                label: s.backHome,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(RwSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.errorTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: RwSpace.xs),
            Text(s.errorBody),
            const SizedBox(height: RwSpace.md),
            RwButton.primary(label: s.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _EditTitleSheet extends StatefulWidget {
  const _EditTitleSheet({this.initialTitle, this.initialNote});
  final String? initialTitle;
  final String? initialNote;

  @override
  State<_EditTitleSheet> createState() => _EditTitleSheetState();
}

class _EditTitleSheetState extends State<_EditTitleSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            RwSpace.screen,
            0,
            RwSpace.screen,
            RwSpace.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.activityEditSheetTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: s.runCancel,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: RwSpace.lg),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: s.activityTitleLabel,
                  hintText: s.activityTitleHint,
                ),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: RwSpace.lg),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: s.summaryNote,
                  hintText: s.summaryNoteHint,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: RwSpace.lg),
              RwButton.primary(
                label: s.activitySave,
                onPressed: () => Navigator.of(context).pop((
                  title: _titleController.text.trim(),
                  note: _noteController.text.trim(),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
