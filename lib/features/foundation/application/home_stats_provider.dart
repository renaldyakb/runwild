import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/stats/stats_engine.dart';
import '../../auth/application/auth_session.dart';
import '../../profile/application/initial_profile.dart';
import '../../profile/application/profile_service.dart';
import '../../profile/domain/user_profile.dart';
import '../../run/application/run_journal.dart';

final allFinishedSessionsProvider =
    FutureProvider.autoDispose<List<FinishedSessionRecord>>((ref) async {
      ref.watch(authSessionProvider);
      final owner = ref.watch(runOwnerProvider)();
      if (owner == null) return const [];
      final journal = ref.watch(runJournalProvider);
      return journal.allFinishedSessions(owner);
    });

final latestRoutePointsProvider =
    FutureProvider.autoDispose<List<({double latitude, double longitude})>>((
      ref,
    ) async {
      ref.watch(authSessionProvider);
      final owner = ref.watch(runOwnerProvider)();
      if (owner == null) return const [];
      final journal = ref.watch(runJournalProvider);
      return journal.latestRoute(owner);
    });

List<SessionItem> _toSessionItems(List<FinishedSessionRecord> records) {
  return [
    for (final r in records)
      (startedAt: r.startedAt, meters: r.meters, moving: r.moving),
  ];
}

final weekSummaryProvider = FutureProvider.autoDispose<WeekSummary>((
  ref,
) async {
  final records = await ref.watch(allFinishedSessionsProvider.future);
  UserProfile? profile;
  try {
    profile = await ref.watch(userProfileProvider.future);
  } catch (error) {
    // Profil gagal dibaca bukan alasan untuk diam: catat jenis error (tanpa
    // data pribadi), lalu pakai target bawaan agar Home tetap tampil jujur.
    debugPrint('Weekly goal profile unavailable: ${error.runtimeType}');
    profile = null;
  }
  final targetSessions =
      profile?.weeklyGoalSessions ?? ProfileLimits.initialSessions;
  return StatsEngine.calculateWeekSummary(
    sessions: _toSessionItems(records),
    now: DateTime.now(),
    targetSessions: targetSessions,
  );
});

final personalRecordsProvider = FutureProvider.autoDispose<PersonalRecords>((
  ref,
) async {
  final records = await ref.watch(allFinishedSessionsProvider.future);
  return StatsEngine.calculatePersonalRecords(_toSessionItems(records));
});

class ProgressPeriodNotifier extends Notifier<ProgressPeriod> {
  @override
  ProgressPeriod build() => ProgressPeriod.week;

  void setPeriod(ProgressPeriod period) {
    state = period;
  }
}

final progressPeriodProvider =
    NotifierProvider.autoDispose<ProgressPeriodNotifier, ProgressPeriod>(
      ProgressPeriodNotifier.new,
    );

final progressStatsProvider = FutureProvider.autoDispose<PeriodStats>((
  ref,
) async {
  final records = await ref.watch(allFinishedSessionsProvider.future);
  final period = ref.watch(progressPeriodProvider);
  return StatsEngine.calculatePeriodStats(
    sessions: _toSessionItems(records),
    period: period,
    now: DateTime.now(),
  );
});

final recommendedSessionProvider =
    FutureProvider.autoDispose<RecommendedSession>((ref) async {
      final sessions = await ref.watch(allFinishedSessionsProvider.future);
      return StatsEngine.getRecommendedSession(
        totalCompletedSessions: sessions.length,
      );
    });
