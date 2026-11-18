import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/app_update_service.dart';
import '../../../design/components/rw_bar_chart.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/home_stats_provider.dart';
import 'app_update_dialog.dart';

class HomeDashboard extends ConsumerStatefulWidget {
  const HomeDashboard({required this.onStart, super.key});

  final VoidCallback? onStart;

  @override
  ConsumerState<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends ConsumerState<HomeDashboard> {
  static bool _hasCheckedUpdateThisSession = false;

  @override
  void initState() {
    super.initState();
    if (!_hasCheckedUpdateThisSession) {
      _hasCheckedUpdateThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAppUpdate());
    }
  }

  Future<void> _checkAppUpdate() async {
    final updateService = ref.read(appUpdateServiceProvider);
    final updateInfo = await updateService.checkForUpdate(notify: true);
    if (mounted && updateInfo != null && updateInfo.hasUpdate) {
      unawaited(AppUpdateDialog.show(context, updateInfo));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final weekAsync = ref.watch(weekSummaryProvider);
    final routePointsAsync = ref.watch(latestRoutePointsProvider);
    final recommendationAsync = ref.watch(recommendedSessionProvider);

    final latestPoints = routePointsAsync.asData?.value ?? const [];

    return RwPage(
      children: [
        // ── Hero Action Card (Hitam Arang Atletis & Prime Lime) ───────
        Container(
          decoration: BoxDecoration(
            color: RwColors.ink950,
            borderRadius: BorderRadius.circular(RwRadius.lg),
          ),
          padding: const EdgeInsets.all(RwSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.homeReady,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  color: RwColors.paper200,
                  fontSize: RwType.label,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: RwSpace.lg),
              Text(
                s.homeTitle,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  color: RwColors.paper100,
                  fontSize: RwType.displayM,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              Text(
                s.homeAccent,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  color: RwColors.lime500,
                  fontSize: RwType.displayM,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: RwSpace.sm),
              Text(
                s.homeSessionHint,
                style: const TextStyle(
                  color: RwColors.paper200,
                  fontSize: RwType.bodySmall,
                ),
              ),
              const SizedBox(height: RwSpace.lg),
              RwButton.primary(
                label: s.homeStart,
                icon: Icons.arrow_forward_rounded,
                onPressed: widget.onStart,
              ),
              if (latestPoints.length >= 2) ...[
                const SizedBox(height: RwSpace.lg),
                const Divider(color: RwColors.ink700),
                const SizedBox(height: RwSpace.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.homeLastRoute,
                        style: const TextStyle(
                          color: RwColors.paper200,
                          fontSize: RwType.bodySmall,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: RwSize.landscape,
                      height: RwSize.pause,
                      child: RunRouteView(
                        points: latestPoints,
                        routeColor: RwColors.lime500,
                        backgroundColor: RwColors.transparent,
                        strokeWidth: RwSize.focus,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: RwSpace.md),

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
                  onPressed: widget.onStart,
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
