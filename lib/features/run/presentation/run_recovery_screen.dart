import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_loading.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/run_journal.dart';
import '../application/run_permissions.dart';

final pendingRunProvider = FutureProvider.autoDispose<RunCheckpoint?>((
  ref,
) async {
  final owner = ref.read(runOwnerProvider)();
  return owner == null ? null : ref.read(runJournalProvider).pending(owner);
}, retry: (_, _) => null);

class RunRecoveryScreen extends ConsumerStatefulWidget {
  const RunRecoveryScreen({this.startIfEmpty = false, super.key});

  final bool startIfEmpty;

  @override
  ConsumerState<RunRecoveryScreen> createState() => _RunRecoveryScreenState();
}

class _RunRecoveryScreenState extends ConsumerState<RunRecoveryScreen> {
  bool _busy = false;
  bool _error = false;
  bool _permissionFailed = false;

  Future<void> _act(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = false;
      _permissionFailed = false;
    });
    try {
      await action();
    } on Exception {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resume(RunCheckpoint checkpoint) => _act(() async {
    final permissions = ref.read(runPermissionsProvider);
    var status = await permissions.status(RunPermission.location);
    if (!mounted) return;
    if (status == RunPermissionStatus.denied) {
      status = await permissions.request(RunPermission.location);
    }
    if (!mounted) return;
    if (status == RunPermissionStatus.granted) {
      context.go('/run/active', extra: checkpoint);
    } else {
      setState(() => _permissionFailed = true);
    }
  });

  Future<void> _resolve(RunCheckpoint checkpoint, {required bool discard}) =>
      _act(() async {
        final owner = ref.read(runOwnerProvider)();
        if (owner == null) throw const RunJournalException();
        if (discard) {
          final s = AppLocalizations.of(context);
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(s.runRecoveryDiscardPrompt),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(s.runCancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(s.runRecoveryDiscard),
                ),
              ],
            ),
          );
          if (!mounted || confirmed != true) return;
        }
        final journal = ref.read(runJournalProvider);
        if (discard) {
          await journal.discard(owner, checkpoint.id);
        } else {
          await journal.checkpoint(owner, checkpoint, const [], finish: true);
        }
        if (mounted) context.go(widget.startIfEmpty ? '/run/active' : '/');
      });

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingRunProvider);
    final checkpoint = pending.asData?.value;

    if (pending.isLoading || (pending.hasValue && checkpoint == null)) {
      if (pending.hasValue && checkpoint == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(widget.startIfEmpty ? '/run/active' : '/');
        });
      }
      return const Scaffold(body: RwFullPageLoading());
    }

    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.runRecoveryTitle),
        automaticallyImplyLeading: false,
      ),
      body: RwPage(
        children: [
          if (pending.hasError || _error) Text(s.runRecoveryError),
          if (pending.hasError)
            RwButton.primary(
              label: s.retry,
              onPressed: () => ref.invalidate(pendingRunProvider),
            ),
          if (checkpoint != null) ...[
            Text(
              s.runRecoverySummary(
                DateFormat.Hm().format(checkpoint.startedAt),
                checkpoint.meters.round(),
              ),
            ),
            const SizedBox(height: RwSpace.lg),
            if (_permissionFailed) ...[
              Text(s.runLocationBlocked),
              RwButton.secondary(
                label: s.runPermissionSettings,
                onPressed: _busy
                    ? null
                    : () => _act(() async {
                        if (!await ref
                            .read(runPermissionsProvider)
                            .openSettings()) {
                          throw const RunJournalException();
                        }
                      }),
              ),
            ],
            RwButton.primary(
              label: s.runRecoveryResume,
              onPressed: _busy ? null : () => _resume(checkpoint),
            ),
            const SizedBox(height: RwSpace.md),
            RwButton.secondary(
              label: s.runRecoverySave,
              onPressed: _busy
                  ? null
                  : () => _resolve(checkpoint, discard: false),
            ),
            const SizedBox(height: RwSpace.md),
            RwButton.secondary(
              label: s.runRecoveryDiscard,
              onPressed: _busy
                  ? null
                  : () => _resolve(checkpoint, discard: true),
            ),
          ],
        ],
      ),
    );
  }
}
