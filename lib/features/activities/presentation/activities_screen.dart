import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/utils/duration_format.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/components/rw_route_view.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/tracking/activity_history.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/activity_history.dart';

class ActivitiesScreen extends ConsumerWidget {
  const ActivitiesScreen({required this.onStart, super.key});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final state = ref.watch(activityHistoryProvider);
    final controller = ref.read(activityHistoryProvider.notifier);
    final items = state.asData?.value.items ?? const <HistoryItem>[];
    final labels = [s.historyAll, s.intervalFree, s.intervalMode];
    return RefreshIndicator(
      onRefresh: () async => controller.refresh(),
      color: RwColors.lime600,
      child: RwPage(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.historyTitle,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: RwSpace.xs),
                    Text(s.historyLocal),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 22),
                    color: RwColors.ink950,
                    tooltip: s.historyRefresh,
                    onPressed: controller.refresh,
                  ),
                  const SizedBox(width: 2),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/progress'),
                    icon: const Icon(Icons.bar_chart_rounded, size: 18),
                    label: Text(
                      s.historyStatsButton,
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: RwColors.ink950,
                      side: const BorderSide(
                        color: RwColors.borderCard,
                        width: 1.2,
                      ),
                      backgroundColor: RwColors.paper100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(RwRadius.pill),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: RwSpace.lg),
          RwSegmentedControl<ActivityHistoryFilter>(
            items: [
              for (final filter in ActivityHistoryFilter.values)
                RwSegmentItem(value: filter, label: labels[filter.index]),
            ],
            selectedValue: controller.filter,
            onChanged: controller.refresh,
          ),
          const SizedBox(height: RwSpace.lg),
          if (state.isLoading)
            Semantics(
              label: s.historyLoading,
              liveRegion: true,
              child: const _HistorySkeleton(),
            ),
          if (state.hasError) ...[
            Text(s.historyError),
            const SizedBox(height: RwSpace.md),
            RwButton.primary(label: s.retry, onPressed: controller.refresh),
          ],
          if (state.hasValue && items.isEmpty)
            RwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.directions_run_outlined, size: RwSize.touch),
                  const SizedBox(height: RwSpace.md),
                  Text(
                    controller.filter == ActivityHistoryFilter.all
                        ? s.historyEmpty
                        : s.historyFilterEmpty,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: RwSpace.xs),
                  Text(s.historyEmptyBody),
                  const SizedBox(height: RwSpace.lg),
                  RwButton.primary(
                    label: controller.filter == ActivityHistoryFilter.all
                        ? s.homeStart
                        : s.historyAll,
                    onPressed: controller.filter == ActivityHistoryFilter.all
                        ? onStart
                        : () => controller.refresh(ActivityHistoryFilter.all),
                  ),
                ],
              ),
            ),
          for (var i = 0; i < items.length; i++) ...[
            if (i == 0 ||
                items[i].startedAt.month != items[i - 1].startedAt.month ||
                items[i].startedAt.year != items[i - 1].startedAt.year)
              _MonthGroupHeader(items: items, startIndex: i),
            _ActivityCard(item: items[i]),
            const SizedBox(height: RwSpace.md),
          ],
          if (controller.moreFailed) Text(s.historyMoreError),
          if (state.asData?.value.next != null) ...[
            RwButton.secondary(
              label: controller.moreFailed ? s.retry : s.historyMore,
              loading: controller.loadingMore,
              loadingLabel: s.historyLoading,
              onPressed: controller.loadingMore ? null : controller.loadMore,
            ),
            const SizedBox(height: RwSpace.md),
          ],
          const SizedBox(height: RwSpace.xl),
        ],
      ),
    );
  }
}

class _MonthGroupHeader extends StatelessWidget {
  const _MonthGroupHeader({required this.items, required this.startIndex});
  final List<HistoryItem> items;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final anchor = items[startIndex].startedAt;
    var count = 0;
    var meters = 0.0;
    for (var j = startIndex; j < items.length; j++) {
      final dt = items[j].startedAt;
      if (dt.month != anchor.month || dt.year != anchor.year) break;
      count++;
      meters += items[j].meters;
    }
    final km = (meters / 1000.0).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.only(bottom: RwSpace.sm, top: RwSpace.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                DateFormat.yMMMM(s.localeName).format(anchor),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          const SizedBox(width: RwSpace.sm),
          Text(
            s.historyMonthSummary(count, km),
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: RwColors.mutedTextOnLight,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: RwSpace.md),
            child: RwCard(
              child: Column(
                children: [
                  Container(
                    height: RwSize.skeletonHeading,
                    color: RwColors.paper200,
                  ),
                  const SizedBox(height: RwSpace.md),
                  Container(height: RwSize.skeleton, color: RwColors.paper200),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});
  final HistoryItem item;

  String _time(int seconds) => formatClockDuration(Duration(seconds: seconds));

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pace = historyPace(item);
    final defaultTitle = switch (historyTimeOfDay(item.startedAt)) {
      HistoryTimeOfDay.morning => s.historyMorning,
      HistoryTimeOfDay.midday => s.historyMidday,
      HistoryTimeOfDay.afternoon => s.historyAfternoon,
      HistoryTimeOfDay.night => s.historyNight,
    };
    final title = item.title?.isNotEmpty ?? false ? item.title! : defaultTitle;
    return RwCard(
      onTap: () => context.push('/activities/${item.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(RwSpace.sm),
                decoration: BoxDecoration(
                  color: RwColors.lime100,
                  borderRadius: BorderRadius.circular(RwRadius.sm),
                ),
                child: Icon(
                  item.interval
                      ? Icons.timer_outlined
                      : Icons.directions_run_outlined,
                  color: RwColors.ink950,
                ),
              ),
              const SizedBox(width: RwSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    Text(
                      DateFormat(
                        'd MMM · HH:mm',
                        s.localeName,
                      ).format(item.startedAt),
                    ),
                    Text(
                      item.interval ? s.intervalMode : s.intervalFree,
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.lg),
          Wrap(
            spacing: RwSpace.xl,
            runSpacing: RwSpace.md,
            children: [
              _Metric(
                label: s.runDistance,
                value: NumberFormat.decimalPatternDigits(
                  locale: s.localeName,
                  decimalDigits: 2,
                ).format(item.meters / 1000),
              ),
              _Metric(
                label: s.runMovingTime,
                value: _time(item.moving.inSeconds),
              ),
              _Metric(
                label: s.runAveragePace,
                value: pace == null
                    ? s.homeMetricEmpty
                    : s.runPaceUnit(_time(pace.round())),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.md),
          if (item.route.length >= 2)
            Semantics(
              label: s.historyRoute,
              child: ExcludeSemantics(
                child: SizedBox(
                  height: RwSize.landscape,
                  child: RunRouteView(
                    points: [
                      for (final point in item.route)
                        (latitude: point.latitude, longitude: point.longitude),
                    ],
                    segmentStarts: {
                      for (var i = 0; i < item.route.length; i++)
                        if (item.route[i].segmentStart) i,
                    },
                    routeColor: RwColors.lime700,
                    backgroundColor: RwColors.paper50,
                  ),
                ),
              ),
            )
          else
            Text(s.historyNoRoute, style: theme.textTheme.bodySmall),
          const SizedBox(height: RwSpace.sm),
          Row(
            children: [
              Icon(
                item.synced
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_upload_outlined,
                size: RwSize.icon,
              ),
              const SizedBox(width: RwSpace.xs),
              Expanded(
                child: Text(
                  item.synced ? s.historySynced : s.historyPending,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
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
      Text(label, style: Theme.of(context).textTheme.labelSmall),
      const SizedBox(height: RwSpace.xxs),
      Text(value, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}
