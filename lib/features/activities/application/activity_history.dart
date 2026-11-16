import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/tracking/activity_history.dart';
import '../../auth/application/auth_session.dart';
import '../../run/application/activity_sync.dart';
import '../../run/application/run_journal.dart';

abstract interface class ActivityHistoryRepository {
  Future<HistoryPage> load(
    String owner,
    ActivityHistoryFilter filter, {
    HistoryCursor? before,
  });
}

class LocalActivityHistoryRepository implements ActivityHistoryRepository {
  LocalActivityHistoryRepository(this.journal);
  final RunJournal journal;
  @override
  Future<HistoryPage> load(
    String owner,
    ActivityHistoryFilter filter, {
    HistoryCursor? before,
  }) => journal.history(owner, filter, before: before);
}

final activityHistoryRepositoryProvider = Provider<ActivityHistoryRepository>(
  (ref) => LocalActivityHistoryRepository(ref.watch(runJournalProvider)),
);
final activityHistoryProvider =
    AsyncNotifierProvider.autoDispose<ActivityHistory, HistoryPage>(
      ActivityHistory.new,
      retry: (_, _) => null,
    );

class ActivityHistory extends AsyncNotifier<HistoryPage> {
  ActivityHistoryFilter filter = ActivityHistoryFilter.all;
  bool loadingMore = false;
  bool moreFailed = false;
  int _request = 0;
  String? _owner;

  @override
  Future<HistoryPage> build() async {
    ref.watch(authSessionProvider);
    _owner = ref.watch(runOwnerProvider)();
    _request++;
    final owner = _owner;
    if (owner == null) return (items: const <HistoryItem>[], next: null);
    return ref.read(activityHistoryRepositoryProvider).load(owner, filter);
  }

  Future<void> refresh([ActivityHistoryFilter? selected]) async {
    final request = ++_request;
    filter = selected ?? filter;
    loadingMore = false;
    moreFailed = false;
    state = const AsyncLoading();
    final owner = ref.read(runOwnerProvider)();
    _owner = owner;

    if (owner != null) {
      try {
        final syncRepo = ref.read(activitySyncRepositoryProvider);
        await syncRepo.syncPending(owner);
        await syncRepo.pullCloudHistory(owner);
      } catch (_) {}
    }

    final result = await AsyncValue.guard<HistoryPage>(
      () async => owner == null
          ? (items: <HistoryItem>[], next: null)
          : ref.read(activityHistoryRepositoryProvider).load(owner, filter),
    );
    if (ref.mounted &&
        request == _request &&
        owner == ref.read(runOwnerProvider)()) {
      state = result;
    }
  }

  Future<void> loadMore() async {
    final page = state.asData?.value;
    final owner = _owner;
    if (page == null || page.next == null || owner == null || loadingMore) {
      return;
    }
    final request = ++_request;
    loadingMore = true;
    moreFailed = false;
    state = AsyncData((items: List.unmodifiable(page.items), next: page.next));
    try {
      final next = await ref
          .read(activityHistoryRepositoryProvider)
          .load(owner, filter, before: page.next);
      if (!ref.mounted ||
          request != _request ||
          owner != ref.read(runOwnerProvider)()) {
        return;
      }
      loadingMore = false;
      state = AsyncData((
        items: List.unmodifiable([...page.items, ...next.items]),
        next: next.next,
      ));
    } on Exception {
      if (!ref.mounted || request != _request) return;
      loadingMore = false;
      moreFailed = true;
      state = AsyncData((
        items: List.unmodifiable(page.items),
        next: page.next,
      ));
    }
  }
}
