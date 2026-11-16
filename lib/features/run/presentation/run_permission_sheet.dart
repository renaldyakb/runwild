import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/run_gps_probe.dart';
import '../application/run_permissions.dart';
import 'interval_options.dart';

Future<bool?> showRunPermissionSheet(BuildContext context) =>
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _RunPermissionSheet(),
    );

class _RunPermissionSheet extends ConsumerStatefulWidget {
  const _RunPermissionSheet();

  @override
  ConsumerState<_RunPermissionSheet> createState() =>
      _RunPermissionSheetState();
}

class _RunPermissionSheetState extends ConsumerState<_RunPermissionSheet>
    with WidgetsBindingObserver {
  final _statuses = <RunPermission, RunPermissionStatus>{};
  bool _busy = false;
  bool _failed = false;
  bool _returningFromSettings = false;
  bool _refreshOnIdle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _returningFromSettings) {
      _returningFromSettings = false;
      if (_busy) {
        _refreshOnIdle = true;
      } else {
        unawaited(_refresh());
      }
    }
  }

  Future<void> _run(Future<void> Function(RunPermissions) action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await action(ref.read(runPermissionsProvider));
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_refreshOnIdle) {
          _refreshOnIdle = false;
          unawaited(_refresh());
        }
      }
    }
  }

  Future<void> _request(RunPermission permission) => _run((service) async {
    final current = await service.status(permission);
    if (!mounted) return;
    final result = current == RunPermissionStatus.denied
        ? await service.request(permission)
        : current;
    if (mounted) setState(() => _statuses[permission] = result);
  });

  Future<void> _refresh() => _run((service) async {
    final results = {
      for (final permission in RunPermission.values)
        permission: await service.status(permission),
    };
    if (mounted) setState(() => _statuses.addAll(results));
  });

  Future<void> _openSettings() => _run((service) async {
    _returningFromSettings = true;
    try {
      if (await service.openSettings()) return;
      if (mounted) setState(() => _failed = true);
    } finally {
      if (_failed || !mounted) {
        _returningFromSettings = false;
      }
    }
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final location = _statuses[RunPermission.location];
    final notifications = _statuses[RunPermission.notifications];
    final needsSettings =
        location == RunPermissionStatus.blocked ||
        notifications == RunPermissionStatus.blocked;
    final locationMessage = switch (location) {
      RunPermissionStatus.granted => s.runLocationReady,
      RunPermissionStatus.denied => s.runLocationDenied,
      RunPermissionStatus.blocked => s.runLocationBlocked,
      RunPermissionStatus.restricted => s.runLocationRestricted,
      null => null,
    };
    final notificationsMessage = switch (notifications) {
      RunPermissionStatus.granted => s.runNotificationsReady,
      RunPermissionStatus.denied ||
      RunPermissionStatus.restricted => s.runNotificationsDenied,
      RunPermissionStatus.blocked => s.runNotificationsBlocked,
      null => null,
    };

    return RwPage(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: RwColors.lime500,
                borderRadius: BorderRadius.circular(RwRadius.md),
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                color: RwColors.ink950,
                size: 24,
              ),
            ),
            const SizedBox(width: RwSpace.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.runSetup,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: RwColors.ink950,
                    ),
                  ),
                  const Text(
                    'Pilih mode lari & pastikan sensor siap.',
                    style: TextStyle(
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
        const SizedBox(height: RwSpace.md),

        // ── Status Sensor Kompak ────────────────────────────────────
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: location == RunPermissionStatus.granted
                    ? const Color(0xFFF7FCE8)
                    : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(RwRadius.pill),
                border: Border.all(
                  color: location == RunPermissionStatus.granted
                      ? RwColors.lime600
                      : const Color(0xFFFDE68A),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 64,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      location == RunPermissionStatus.granted
                          ? Icons.check_circle_rounded
                          : Icons.location_on_outlined,
                      size: 14,
                      color: location == RunPermissionStatus.granted
                          ? RwColors.lime700
                          : const Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        location == RunPermissionStatus.granted
                            ? 'GPS Siap'
                            : 'Perlu Izin Lokasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: location == RunPermissionStatus.granted
                              ? RwColors.ink950
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: notifications == RunPermissionStatus.granted
                    ? const Color(0xFFF7FCE8)
                    : RwColors.paper50,
                borderRadius: BorderRadius.circular(RwRadius.pill),
                border: Border.all(
                  color: notifications == RunPermissionStatus.granted
                      ? RwColors.lime600
                      : const Color(0xFFE2E6DC),
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 64,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      notifications == RunPermissionStatus.granted
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_none_rounded,
                      size: 14,
                      color: notifications == RunPermissionStatus.granted
                          ? RwColors.lime700
                          : RwColors.mutedTextOnLight,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        notifications == RunPermissionStatus.granted
                            ? 'Notifikasi Aktif'
                            : 'Perlu Notifikasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: notifications == RunPermissionStatus.granted
                              ? RwColors.ink950
                              : RwColors.mutedTextOnLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: RwSpace.sm),

        // ── Info Sensor Ringkas & Rapi ──────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: RwColors.paper50,
            borderRadius: BorderRadius.circular(RwRadius.sm),
            border: Border.all(color: const Color(0xFFE2E6DC)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 15,
                color: RwColors.ink500,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.runLocationExplanation,
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 11,
                        color: RwColors.mutedTextOnLight,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.runNotificationsExplanation,
                      style: const TextStyle(
                        fontFamily: RwType.family,
                        fontSize: 11,
                        color: RwColors.mutedTextOnLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: RwSpace.md),

        IntervalOptions(enabled: !_busy),

        if (locationMessage != null ||
            notificationsMessage != null ||
            _failed) ...[
          const SizedBox(height: RwSpace.sm),
          Semantics(
            liveRegion: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (locationMessage != null)
                  Text(
                    locationMessage,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                if (notificationsMessage != null)
                  Text(
                    notificationsMessage,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                if (_failed)
                  Text(
                    s.runPermissionError,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      color: RwColors.danger500,
                    ),
                  ),
              ],
            ),
          ),
        ],

        if (_busy) ...[
          const SizedBox(height: RwSpace.md),
          Semantics(liveRegion: true, child: Text(s.runPermissionBusy)),
        ],
        const SizedBox(height: RwSpace.lg),

        if (location == RunPermissionStatus.granted) ...[
          RwButton.primary(
            label: s.runBeginSession,
            onPressed: _busy
                ? null
                : () => _run((_) async {
                    await ref.read(runGpsProbeProvider.notifier).stop();
                    if (context.mounted) Navigator.of(context).pop(true);
                  }),
          ),
        ],
        if (location == null || location == RunPermissionStatus.denied)
          RwButton.primary(
            label: s.runStart,
            onPressed: _busy ? null : () => _request(RunPermission.location),
          ),
        if (notifications == null ||
            notifications == RunPermissionStatus.denied) ...[
          const SizedBox(height: RwSpace.xs),
          RwButton.secondary(
            label: s.runNotificationsEnable,
            onPressed: _busy
                ? null
                : () => _request(RunPermission.notifications),
          ),
        ],
        if (needsSettings) ...[
          const SizedBox(height: RwSpace.xs),
          RwButton.secondary(
            label: s.runPermissionSettings,
            onPressed: _busy ? null : _openSettings,
          ),
        ],
        if (needsSettings || _failed) ...[
          const SizedBox(height: RwSpace.xs),
          RwButton.secondary(
            label: s.runPermissionRefresh,
            onPressed: _busy ? null : _refresh,
          ),
        ],
        const SizedBox(height: RwSpace.xs),
        RwButton.secondary(
          label: s.close,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
