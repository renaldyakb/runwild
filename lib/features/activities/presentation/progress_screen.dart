import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_bar_chart.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_motion.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/stats/stats_engine.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../foundation/application/home_stats_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes}m';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final selectedPeriod = ref.watch(progressPeriodProvider);
    final statsAsync = ref.watch(progressStatsProvider);
    final recordsAsync = ref.watch(personalRecordsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.progressTitle,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: RwPage(
          children: [
            // ── Period Segmented Control ────────────────────────────
            RwSegmentedControl<ProgressPeriod>(
              items: [
                RwSegmentItem(
                  value: ProgressPeriod.week,
                  label: s.progressPeriodWeek,
                ),
                RwSegmentItem(
                  value: ProgressPeriod.month,
                  label: s.progressPeriodMonth,
                ),
                RwSegmentItem(
                  value: ProgressPeriod.allTime,
                  label: s.progressPeriodAll,
                ),
              ],
              selectedValue: selectedPeriod,
              onChanged: (val) {
                ref.read(progressPeriodProvider.notifier).setPeriod(val);
              },
            ),
            const SizedBox(height: RwSpace.md),

            // ── Period Statistics Card ──────────────────────────────
            statsAsync.when(
              loading: () => const _StatsSkeleton(),
              error: (_, _) => RwCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: RwSize.icon,
                        color: RwColors.danger500,
                      ),
                    ),
                    const SizedBox(height: RwSpace.sm),
                    Text(s.progressLoadError),
                    const SizedBox(height: RwSpace.md),
                    RwButton.secondary(
                      label: s.retry,
                      onPressed: () {
                        ref.invalidate(progressStatsProvider);
                        ref.invalidate(allFinishedSessionsProvider);
                      },
                    ),
                  ],
                ),
              ),
              data: (stats) {
                final chartItems = [
                  for (final bar in stats.chartBars)
                    RwBarChartItem(
                      label: bar.label,
                      value: bar.valueKm,
                      isHighlight: bar.isHighlight,
                    ),
                ];

                return RwEntrance(
                  order: 0,
                  child: RwCard(
                    padding: const EdgeInsets.all(RwSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RwCountUp(
                          value: stats.totalDistanceMeters / 1000.0,
                          builder: (_, value) => Text(
                            value.toStringAsFixed(2),
                            style: const TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              fontFeatures: [FontFeature.tabularFigures()],
                              letterSpacing: -1,
                              height: 1,
                              color: RwColors.ink950,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TOTAL KILOMETER · ${switch (selectedPeriod) {
                            ProgressPeriod.week => s.progressPeriodWeek,
                            ProgressPeriod.month => s.progressPeriodMonth,
                            ProgressPeriod.allTime => s.progressPeriodAll,
                          }.toUpperCase()}',
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: RwColors.mutedTextOnLight,
                          ),
                        ),
                        const SizedBox(height: RwSpace.md),
                        const Divider(color: RwColors.borderCard, height: 1),
                        const SizedBox(height: RwSpace.md),

                        // Metrics 4-Box Grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MetricColumn(
                              label: s.progressTotalTime,
                              value: _formatDuration(stats.totalMovingTime),
                            ),
                            _MetricColumn(
                              label: s.progressTotalSessions,
                              value: '${stats.sessionCount}',
                            ),
                            _MetricColumn(
                              label: s.progressTotalCalories,
                              value: '${stats.totalCalories}',
                              unit: ' kkal',
                            ),
                            _MetricColumn(
                              label: s.progressAvgPace,
                              value: _formatPace(stats.averagePaceSecondsPerKm),
                            ),
                          ],
                        ),
                        const SizedBox(height: RwSpace.xs),
                        Text(
                          s.progressCaloriesNote,
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            fontSize: 11,
                            color: RwColors.mutedTextOnLight,
                          ),
                        ),
                        const SizedBox(height: RwSpace.lg),

                        // fl_chart Community Bar Chart
                        RwBarChart(items: chartItems, height: 130),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: RwSpace.lg),

            // ── Personal Best / Rekor Pribadi Section ────────────────
            Text(
              s.progressRecordsTitle.toUpperCase(),
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: RwColors.mutedTextOnLight,
              ),
            ),
            const SizedBox(height: RwSpace.sm),

            recordsAsync.when(
              loading: () => const _StatsSkeleton(),
              error: (_, _) => const SizedBox.shrink(),
              data: (records) {
                final hasAnyRecord =
                    records.longestDistance != null ||
                    records.longestDuration != null ||
                    records.bestPace1k != null ||
                    records.bestPace5k != null;

                if (!hasAnyRecord) {
                  return RwCard(
                    padding: const EdgeInsets.all(RwSpace.lg),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events_outlined,
                          size: 32,
                          color: RwColors.ink500,
                        ),
                        const SizedBox(height: RwSpace.sm),
                        Text(
                          s.progressNoRecords,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            fontSize: 13,
                            color: RwColors.mutedTextOnLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _RecordCard(
                            title: s.progressRecordLongestDist,
                            record: records.longestDistance,
                            icon: Icons.trending_up_rounded,
                            unitOverride: 'km',
                          ),
                        ),
                        const SizedBox(width: RwSpace.sm),
                        Expanded(
                          child: _RecordCard(
                            title: s.progressRecordLongestDur,
                            record: records.longestDuration,
                            icon: Icons.timelapse_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: RwSpace.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _RecordCard(
                            title: s.progressRecordBest1k,
                            record: records.bestPace1k,
                            icon: Icons.bolt_rounded,
                          ),
                        ),
                        const SizedBox(width: RwSpace.sm),
                        Expanded(
                          child: _RecordCard(
                            title: s.progressRecordBest5k,
                            record: records.bestPace5k,
                            icon: Icons.flash_on_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: RwSpace.xl),
          ],
        ),
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.value, this.unit});
  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontFamily: RwType.family,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: RwColors.mutedTextOnLight,
        ),
      ),
      const SizedBox(height: 2),
      RichText(
        text: TextSpan(
          text: value,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 14,
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
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: RwColors.mutedTextOnLight,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.title,
    required this.record,
    required this.icon,
    this.unitOverride,
  });

  final String title;
  final PersonalRecord? record;
  final IconData icon;
  final String? unitOverride;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final dateStr = record != null
        ? DateFormat('d MMM yyyy', s.localeName).format(record!.achievedAt)
        : '—';

    return RwCard(
      padding: const EdgeInsets.all(RwSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: RwColors.mutedTextOnLight,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: RwColors.lime700),
            ],
          ),
          const SizedBox(height: RwSpace.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                record?.value ?? '—',
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: RwColors.ink950,
                ),
              ),
              if (record != null &&
                  (unitOverride ?? record!.unit).isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(
                  unitOverride ?? record!.unit,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            dateStr,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 10,
              color: RwColors.mutedTextOnLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 140,
            decoration: BoxDecoration(
              color: RwColors.paper200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: RwSpace.md),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: RwColors.paper200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    ),
  );
}
