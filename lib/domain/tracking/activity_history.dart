import '../../core/constants/activity_history_limits.dart';

enum ActivityHistoryFilter { all, free, interval }

enum HistoryTimeOfDay { morning, midday, afternoon, night }

HistoryTimeOfDay historyTimeOfDay(DateTime time) {
  final hour = time.toLocal().hour;
  if (hour < ActivityHistoryLimits.morningStart ||
      hour >= ActivityHistoryLimits.nightStart) {
    return HistoryTimeOfDay.night;
  }
  if (hour < ActivityHistoryLimits.middayStart) return HistoryTimeOfDay.morning;
  if (hour < ActivityHistoryLimits.afternoonStart) {
    return HistoryTimeOfDay.midday;
  }
  return HistoryTimeOfDay.afternoon;
}

typedef HistoryCursor = ({int startedMs, int id});
typedef HistoryPoint = ({double latitude, double longitude, bool segmentStart});
typedef HistoryItem = ({
  int id,
  DateTime startedAt,
  double meters,
  Duration moving,
  bool interval,
  bool synced,
  List<HistoryPoint> route,
  String? title,
});
typedef HistoryPage = ({List<HistoryItem> items, HistoryCursor? next});

double? historyPace(HistoryItem item) =>
    item.meters > 0 && item.moving > Duration.zero
    ? item.moving.inMilliseconds /
          Duration.millisecondsPerSecond /
          (item.meters / 1000)
    : null;
