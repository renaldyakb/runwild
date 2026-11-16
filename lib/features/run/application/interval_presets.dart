import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/interval/interval_engine.dart';
import 'run_journal.dart';

final savedIntervalsProvider =
    AsyncNotifierProvider.autoDispose<SavedIntervals, List<SavedInterval>>(
      SavedIntervals.new,
    );

class SavedIntervals extends AsyncNotifier<List<SavedInterval>> {
  @override
  Future<List<SavedInterval>> build() async {
    final owner = ref.watch(runOwnerProvider)();
    return owner == null ? [] : ref.read(runJournalProvider).presets(owner);
  }

  Future<void> save(String name, IntervalConfig config, {int? id}) async {
    final owner = ref.read(runOwnerProvider)();
    if (owner == null) throw const RunJournalException();
    await ref.read(runJournalProvider).savePreset(owner, name, config, id: id);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    final owner = ref.read(runOwnerProvider)();
    if (owner == null) throw const RunJournalException();
    await ref.read(runJournalProvider).deletePreset(owner, id);
    ref.invalidateSelf();
  }
}
