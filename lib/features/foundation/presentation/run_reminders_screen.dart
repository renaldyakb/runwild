import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/run_reminder.dart';

/// Halaman pengelolaan jadwal lari: daftar seperti kalender, bisa memuat
/// banyak jadwal sekaligus, dan tiap jadwal memicu notifikasi bersuara dari
/// sistem operasi walau aplikasi sedang tertutup.
class RunRemindersScreen extends ConsumerStatefulWidget {
  const RunRemindersScreen({super.key});

  @override
  ConsumerState<RunRemindersScreen> createState() => _RunRemindersScreenState();
}

class _RunRemindersScreenState extends ConsumerState<RunRemindersScreen> {
  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: startOfToday,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// Menjalankan aksi jadwal lalu melaporkan hasilnya tanpa menelan kegagalan.
  Future<void> _apply(
    ScaffoldMessengerState messenger,
    AppLocalizations s,
    Future<void> Function() action, {
    required String success,
  }) async {
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(s.reminderError)));
    }
  }

  Future<void> _add() async {
    final s = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final selected = await _pickDateTime(
      DateTime.now().add(const Duration(hours: 1)),
    );
    if (selected == null) return;
    if (!selected.isAfter(DateTime.now())) {
      messenger.showSnackBar(SnackBar(content: Text(s.reminderPast)));
      return;
    }
    await _apply(
      messenger,
      s,
      () => ref
          .read(runRemindersProvider.notifier)
          .add(
            selected,
            title: s.reminderNotificationTitle,
            body: s.reminderNotificationBody,
          ),
      success: s.remindersSaved,
    );
  }

  Future<void> _reschedule(RunReminder reminder) async {
    final s = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final selected = await _pickDateTime(reminder.time);
    if (selected == null) return;
    if (!selected.isAfter(DateTime.now())) {
      messenger.showSnackBar(SnackBar(content: Text(s.reminderPast)));
      return;
    }
    if (selected.isAtSameMomentAs(reminder.time)) return;
    await _apply(messenger, s, () async {
      final notifier = ref.read(runRemindersProvider.notifier);
      await notifier.remove(reminder.id);
      await notifier.add(
        selected,
        title: s.reminderNotificationTitle,
        body: s.reminderNotificationBody,
      );
    }, success: s.remindersSaved);
  }

  Future<void> _delete(RunReminder reminder) async {
    final s = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _apply(
      messenger,
      s,
      () => ref.read(runRemindersProvider.notifier).remove(reminder.id),
      success: s.remindersDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final remindersAsync = ref.watch(runRemindersProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.remindersTitle,
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
            RwButton.primary(
              label: s.remindersAdd,
              icon: Icons.alarm_add,
              onPressed: () => unawaited(_add()),
            ),
            const SizedBox(height: RwSpace.xs),
            Text(
              s.remindersIntro,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                color: RwColors.mutedTextOnLight,
              ),
            ),
            const SizedBox(height: RwSpace.md),
            remindersAsync.when(
              loading: () => const _ReminderSkeleton(),
              error: (_, _) => _ReminderErrorCard(
                onRetry: () => ref.invalidate(runRemindersProvider),
              ),
              data: (reminders) => reminders.isEmpty
                  ? _EmptyReminders(onAdd: () => unawaited(_add()))
                  : _ReminderList(
                      reminders: reminders,
                      onDelete: (reminder) => unawaited(_delete(reminder)),
                      onEdit: (reminder) => unawaited(_reschedule(reminder)),
                    ),
            ),
            const SizedBox(height: RwSpace.md),
            RwCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.remindersSoundNote,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: RwColors.ink950,
                    ),
                  ),
                  const SizedBox(height: RwSpace.xs),
                  Text(
                    s.reminderInexact,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({
    required this.reminders,
    required this.onDelete,
    required this.onEdit,
  });

  final List<RunReminder> reminders;
  final void Function(RunReminder reminder) onDelete;
  final void Function(RunReminder reminder) onEdit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final now = DateTime.now();
    final children = <Widget>[];
    var group = ReminderGroup.today;
    var hasHeader = false;
    for (final reminder in reminders) {
      final current = reminderGroupFor(reminder.time, now);
      if (!hasHeader || current != group) {
        group = current;
        hasHeader = true;
        children.add(
          Semantics(
            header: true,
            child: Padding(
              padding: const EdgeInsets.only(
                top: RwSpace.sm,
                bottom: RwSpace.xs,
              ),
              child: Text(
                switch (current) {
                  ReminderGroup.today => s.remindersGroupToday,
                  ReminderGroup.tomorrow => s.remindersGroupTomorrow,
                  ReminderGroup.later => s.remindersGroupLater,
                },
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: RwColors.mutedTextOnLight,
                ),
              ),
            ),
          ),
        );
      }
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: RwSpace.sm),
          child: _ReminderTile(
            reminder: reminder,
            onDelete: () => onDelete(reminder),
            onEdit: () => onEdit(reminder),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.reminder,
    required this.onDelete,
    required this.onEdit,
  });

  final RunReminder reminder;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = s.localeName;
    final fullDate = DateFormat(
      'EEEE, d MMMM yyyy',
      locale,
    ).format(reminder.time);
    final time = DateFormat.Hm(locale).format(reminder.time);
    return RwCard(
      padding: const EdgeInsets.all(RwSpace.md),
      onTap: onEdit,
      child: Row(
        children: [
          Container(
            width: RwSpace.xxl,
            padding: const EdgeInsets.symmetric(vertical: RwSpace.xs),
            decoration: BoxDecoration(
              color: RwColors.surfaceMuted,
              borderRadius: BorderRadius.circular(RwRadius.sm),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('d', locale).format(reminder.time),
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: RwColors.ink950,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  DateFormat('MMM', locale).format(reminder.time),
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: RwSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullDate,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: RwColors.ink950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: s.remindersDelete,
            color: RwColors.dangerTextOnLight,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _EmptyReminders extends StatelessWidget {
  const _EmptyReminders({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return RwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.event_available_outlined, size: RwSize.icon),
          ),
          const SizedBox(height: RwSpace.md),
          Semantics(
            liveRegion: true,
            child: Text(
              s.remindersEmptyTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: RwSpace.xs),
          Text(s.remindersEmptyBody),
          const SizedBox(height: RwSpace.lg),
          RwButton.secondary(label: s.remindersAdd, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _ReminderSkeleton extends StatelessWidget {
  const _ReminderSkeleton();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Semantics(
      label: s.remindersLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: RwCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 14,
                width: 140,
                decoration: BoxDecoration(
                  color: RwColors.borderCard,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: RwSpace.md),
              Container(
                height: 32,
                width: 90,
                decoration: BoxDecoration(
                  color: RwColors.borderCard,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderErrorCard extends StatelessWidget {
  const _ReminderErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return RwCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.error_outline, size: RwSize.icon),
          ),
          const SizedBox(height: RwSpace.md),
          Semantics(
            liveRegion: true,
            child: Text(
              s.remindersErrorTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: RwSpace.xs),
          Text(s.remindersErrorBody),
          const SizedBox(height: RwSpace.lg),
          RwButton.secondary(label: s.retry, onPressed: onRetry),
        ],
      ),
    );
  }
}
