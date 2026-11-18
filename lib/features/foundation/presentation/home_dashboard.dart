import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_bar_chart.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/home_stats_provider.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({required this.onStart, super.key});

  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final weekAsync = ref.watch(weekSummaryProvider);
    final routePointsAsync = ref.watch(latestRoutePointsProvider);
    final recommendationAsync = ref.watch(recommendedSessionProvider);

    final latestPoints = routePointsAsync.asData?.value ?? const [];

    return RwPage(
      children: [
        // ── Hero Action Card (Hitam Arang Atletis & Prime Lime) ───────
        DecoratedBox(
          decoration: BoxDecoration(
            color: RwColors.ink950,
            borderRadius: BorderRadius.circular(RwRadius.lg),
            border: Border.all(color: RwColors.ink800, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x30000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(RwSpace.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: RwColors.lime500,
                          borderRadius: BorderRadius.circular(RwRadius.pill),
                        ),
                        child: Text(
                          s.homeReady,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            color: RwColors.ink950,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.bolt_rounded,
                      color: RwColors.lime500,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: RwSpace.md),
                Semantics(
                  header: true,
                  child: Text(
                    s.homeTitle,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      letterSpacing: -0.5,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                Text(
                  s.homeAccent,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    color: RwColors.lime500,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: RwSpace.md),

                // Hero Route Visual Preview Box
                Container(
                  height: 125,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RwColors.ink900,
                    borderRadius: BorderRadius.circular(RwRadius.md),
                    border: Border.all(color: RwColors.ink800, width: 1),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (latestPoints.length >= 2) ...[
                        RunRouteView(
                          points: latestPoints,
                          routeColor: RwColors.lime500,
                          strokeWidth: 3.0,
                        ),
                        Positioned(
                          left: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: RwColors.ink950.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(
                                RwRadius.pill,
                              ),
                            ),
                            child: const Text(
                              'RUTE TERAKHIR',
                              style: TextStyle(
                                fontFamily: RwType.family,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: RwColors.lime500,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        const RunRouteView(
                          routeColor: RwColors.lime500,
                          strokeWidth: 3.0,
                        ),
                        SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: RwColors.ink800,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.directions_run_rounded,
                                  color: RwColors.lime500,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                s.homeRouteEmpty,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: RwType.family,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                s.homeRouteHint,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: RwType.family,
                                  fontSize: 10,
                                  color: RwColors.paper200,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: RwSpace.md),

                // Quick Metrics Tile Row
                weekAsync.when(
                  loading: () => const _HeroMetricsSkeleton(),
                  error: (_, _) => const _HeroMetricsEmpty(),
                  data: (summary) {
                    final distKm = (summary.totalDistanceMeters / 1000.0)
                        .toStringAsFixed(1);
                    final durMin = summary.totalMovingTime.inMinutes;
                    return Row(
                      children: [
                        Expanded(
                          child: _HeroMetricTile(
                            label: s.homeDistance,
                            value: summary.totalDistanceMeters > 0
                                ? '$distKm km'
                                : s.homeMetricEmpty,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _HeroMetricTile(
                            label: s.homeDuration,
                            value: summary.totalMovingTime > Duration.zero
                                ? '$durMin m'
                                : s.homeMetricEmpty,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _HeroMetricTile(
                            label: 'KALORI',
                            value: summary.totalCalories > 0
                                ? '${summary.totalCalories}'
                                : s.homeMetricEmpty,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: RwSpace.lg),

                // Tombol Mulai Berlari Menyala Kontras
                RwButton.primary(
                  label: s.homeStart,
                  icon: Icons.play_arrow_rounded,
                  onPressed: onStart,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RwSpace.md),

        // ── Performa Minggu Ini Card (Dengan Grafik fl_chart) ────────
        weekAsync.when(
          loading: () => const _CardSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (summary) {
            final startFmt = DateFormat(
              'd MMM',
              s.localeName,
            ).format(summary.weekStart);
            final endFmt = DateFormat(
              'd MMM',
              s.localeName,
            ).format(summary.weekEnd);
            final rangeLabel = '$startFmt – $endFmt';

            final distKm = (summary.totalDistanceMeters / 1000.0)
                .toStringAsFixed(2);
            final chartItems = [
              for (final bar in summary.dailyBars)
                RwBarChartItem(
                  label: bar.dayLabel,
                  value: bar.distanceKm,
                  isHighlight: bar.isToday,
                ),
            ];

            return RwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s.homeThisWeek.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: RwColors.mutedTextOnLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: RwColors.paper100,
                            borderRadius: BorderRadius.circular(RwRadius.pill),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              rangeLabel,
                              style: const TextStyle(
                                fontFamily: RwType.family,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: RwColors.ink950,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RwSpace.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            distKm,
                            style: const TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              fontFeatures: [FontFeature.tabularFigures()],
                              letterSpacing: -1,
                              color: RwColors.ink950,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'KM',
                        style: TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: RwColors.mutedTextOnLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: RwSpace.md),

                  // 7-Day Bar Chart via fl_chart
                  RwBarChart(items: chartItems, height: 110),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: RwSpace.md),

        // ── Target Mingguan Card & Streak ────────────────────────────
        weekAsync.when(
          loading: () => const _CardSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (summary) {
            final target = summary.targetSessions;
            final completed = summary.sessionCount;
            final isTargetReached = target > 0 && completed >= target;
            final ratio = (completed / target).clamp(0.0, 1.0);
            final percent = (ratio * 100).round();

            return RwCard(
              color: isTargetReached ? const Color(0xFFF7FCE8) : null,
              borderColor: isTargetReached ? RwColors.lime600 : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                s.homeWeeklyGoal.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: RwType.family,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isTargetReached
                                      ? RwColors.ink950
                                      : RwColors.mutedTextOnLight,
                                ),
                              ),
                            ),
                            if (isTargetReached) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: RwColors.lime500,
                                  borderRadius: BorderRadius.circular(
                                    RwRadius.pill,
                                  ),
                                ),
                                child: const Text(
                                  'TUNTAS! 🔥',
                                  style: TextStyle(
                                    fontFamily: RwType.family,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: RwColors.ink950,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (summary.streakWeeks > 0)
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(
                                RwRadius.pill,
                              ),
                              border: Border.all(
                                color: const Color(0xFFFDE68A),
                                width: 1,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    '🔥 ',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    s.homeStreak(summary.streakWeeks),
                                    style: const TextStyle(
                                      fontFamily: RwType.family,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: RwSpace.sm),
                  Text(
                    isTargetReached
                        ? 'Target minggu ini tuntas! ($completed/$target sesi)'
                        : s.homeWeeklyGoalProgress(completed, target, percent),
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isTargetReached
                          ? RwColors.ink950
                          : RwColors.ink950,
                    ),
                  ),
                  if (isTargetReached) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Konsistensi lari luar biasa! Pertahankan semangatmu.',
                      style: TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RwColors.mutedTextOnLight,
                      ),
                    ),
                  ],
                  const SizedBox(height: RwSpace.xs),

                  // Progress Bar atletis
                  ClipRRect(
                    borderRadius: BorderRadius.circular(RwRadius.pill),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 10,
                      backgroundColor: const Color(0xFFE2E6DC),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isTargetReached ? RwColors.lime700 : RwColors.lime600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: RwSpace.md),

        // ── Rekomendasi Sesi Hari Ini Card ───────────────────────────
        recommendationAsync.when(
          loading: () => const _CardSkeleton(),
          error: (_, _) => const SizedBox.shrink(),
          data: (rec) => RwCard(
            padding: const EdgeInsets.all(RwSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(RwSpace.xs),
                      decoration: BoxDecoration(
                        color: RwColors.lime100,
                        borderRadius: BorderRadius.circular(RwRadius.sm),
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: RwColors.ink950,
                      ),
                    ),
                    const SizedBox(width: RwSpace.xs),
                    Expanded(
                      child: Text(
                        s.homeRecommendationTitle.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: RwColors.mutedTextOnLight,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RwSpace.sm),
                Text(
                  rec.title,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: RwColors.ink950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.description,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 13,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
                const SizedBox(height: RwSpace.md),
                RwButton.secondary(
                  label: 'Pilih & Mulai Lari',
                  icon: Icons.play_arrow_rounded,
                  fullWidth: true,
                  onPressed: onStart,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: RwSpace.md),

        // ── Akses Menu Progress & Rekor Pribadi (S-40) ───────────────
        RwCard(
          onTap: () => context.push('/progress'),
          padding: const EdgeInsets.all(RwSpace.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RwColors.lime500,
                  borderRadius: BorderRadius.circular(RwRadius.sm),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 22,
                  color: RwColors.ink950,
                ),
              ),
              const SizedBox(width: RwSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.progressTitle,
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: RwColors.ink950,
                      ),
                    ),
                    Text(
                      s.homeSeeProgress,
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 12,
                        color: RwColors.mutedTextOnLight,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: RwColors.mutedTextOnLight,
              ),
            ],
          ),
        ),
        const SizedBox(height: RwSpace.lg),
      ],
    );
  }
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: RwSpace.xs, vertical: 8),
    decoration: BoxDecoration(
      color: RwColors.ink900,
      borderRadius: BorderRadius.circular(RwRadius.sm),
      border: Border.all(color: RwColors.ink800, width: 1),
    ),
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: RwType.family,
            color: RwColors.paper200,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            fontFeatures: [FontFeature.tabularFigures()],
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}

class _HeroMetricsEmpty extends StatelessWidget {
  const _HeroMetricsEmpty();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(
        child: _HeroMetricTile(label: 'JARAK', value: '—'),
      ),
      SizedBox(width: 4),
      Expanded(
        child: _HeroMetricTile(label: 'DURASI', value: '—'),
      ),
      SizedBox(width: 4),
      Expanded(
        child: _HeroMetricTile(label: 'KALORI', value: '—'),
      ),
    ],
  );
}

class _HeroMetricsSkeleton extends StatelessWidget {
  const _HeroMetricsSkeleton();
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < 3; i++)
        Expanded(
          child: Container(
            height: 48,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: RwColors.ink900,
              borderRadius: BorderRadius.circular(RwRadius.sm),
            ),
          ),
        ),
    ],
  );
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            width: 120,
            decoration: BoxDecoration(
              color: RwColors.paper200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: RwSpace.md),
          Container(
            height: 32,
            width: 80,
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
