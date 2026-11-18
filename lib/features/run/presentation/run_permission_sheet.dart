import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/gps_calibration.dart';
import '../application/run_gps_probe.dart';
import '../application/run_permissions.dart';
import 'gps_calibration_sheet.dart';
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
  bool _settingsFailed = false;
  bool _returningFromSettings = false;
  bool _refreshOnIdle = false;
  bool? _serviceEnabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refresh());
    });
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
    final serviceEnabled = await _serviceEnabledFor(service);
    if (!mounted) return;
    setState(() {
      _statuses[permission] = result;
      if (serviceEnabled != null) _serviceEnabled = serviceEnabled;
    });
  });

  Future<void> _refresh() => _run((service) async {
    final results = {
      for (final permission in RunPermission.values)
        permission: await service.status(permission),
    };
    final serviceEnabled = await _serviceEnabledFor(service);
    if (!mounted) return;
    setState(() {
      _statuses.addAll(results);
      _settingsFailed = false;
      if (serviceEnabled != null) _serviceEnabled = serviceEnabled;
    });
  });

  Future<bool?> _serviceEnabledFor(RunPermissions service) async {
    try {
      return await service.isLocationServiceEnabled();
    } on Exception catch (error) {
      debugPrint('Location service check failed: ${error.runtimeType}');
      return null;
    }
  }

  Future<void> _openSettings() => _run((service) async {
    _returningFromSettings = true;
    try {
      final opened = await service.openSettings();
      if (opened) return;
      if (mounted) setState(() => _settingsFailed = true);
    } finally {
      if (_settingsFailed || !mounted) {
        _returningFromSettings = false;
      }
    }
  });

  Future<void> _openLocationSettings() => _run((service) async {
    _returningFromSettings = true;
    try {
      var opened = await service.openLocationSettings();
      if (!opened) opened = await service.openSettings();
      if (opened) return;
      if (mounted) setState(() => _settingsFailed = true);
    } finally {
      if (_settingsFailed || !mounted) {
        _returningFromSettings = false;
      }
    }
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final location = _statuses[RunPermission.location];
    final notifications = _statuses[RunPermission.notifications];
    final permissionsKnown = _statuses.length == RunPermission.values.length;
    final locationGranted = location == RunPermissionStatus.granted;
    final notificationsGranted = notifications == RunPermissionStatus.granted;
    final serviceOff = _serviceEnabled == false;
    final missing = <RunPermission>[
      if (!locationGranted) RunPermission.location,
      if (!notificationsGranted) RunPermission.notifications,
    ];
    final canStart = locationGranted && notificationsGranted && !serviceOff;
    final showNotice =
        _failed ||
        _settingsFailed ||
        (permissionsKnown && (missing.isNotEmpty || serviceOff));

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

        // ── Peringatan hanya bila ada yang belum aktif ──────────────
        if (showNotice) ...[
          _permissionNotice(
            s,
            missing: permissionsKnown ? missing : const [],
            serviceOff: permissionsKnown && serviceOff,
          ),
        ],

        if (canStart) ...[
          const SizedBox(height: RwSpace.sm),
          _calibrationCard(s),
        ],
        const SizedBox(height: RwSpace.md),

        IntervalOptions(enabled: !_busy),

        if (_busy) ...[
          const SizedBox(height: RwSpace.md),
          Semantics(liveRegion: true, child: Text(s.runPermissionBusy)),
        ],
        const SizedBox(height: RwSpace.lg),

        RwButton.primary(
          label: s.runBeginSession,
          onPressed: canStart && !_busy ? _startSession : null,
        ),
        if (!canStart && permissionsKnown) ...[
          const SizedBox(height: RwSpace.xs),
          Text(
            s.runStartBlocked,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 12,
              color: RwColors.mutedTextOnLight,
            ),
          ),
        ],
        if (!canStart || _settingsFailed || _failed) ...[
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

  String _permissionMessage(AppLocalizations s, RunPermission permission) {
    final status = _statuses[permission];
    return switch (permission) {
      RunPermission.location => switch (status) {
        RunPermissionStatus.blocked => s.runLocationBlocked,
        RunPermissionStatus.restricted => s.runLocationRestricted,
        _ => s.runLocationDenied,
      },
      RunPermission.notifications => switch (status) {
        RunPermissionStatus.blocked => s.runNotificationsBlocked,
        _ => s.runNotificationsDenied,
      },
    };
  }

  bool _needsSettings(RunPermission permission) =>
      _statuses[permission] == RunPermissionStatus.blocked ||
      _statuses[permission] == RunPermissionStatus.restricted;

  Widget _permissionNotice(
    AppLocalizations s, {
    required List<RunPermission> missing,
    required bool serviceOff,
  }) {
    return RwCard(
      padding: const EdgeInsets.all(RwSpace.md),
      color: RwColors.paper50,
      borderColor: RwColors.lime600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 18,
                color: RwColors.ink950,
              ),
              const SizedBox(width: RwSpace.xs),
              Expanded(
                child: Text(
                  s.runPermissionsRequiredTitle,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: RwColors.ink950,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.xs),
          Text(
            s.runPermissionsRequiredBody,
            style: const TextStyle(
              fontFamily: RwType.family,
              fontSize: 12,
              color: RwColors.mutedTextOnLight,
            ),
          ),
          if (serviceOff) ...[
            const SizedBox(height: RwSpace.sm),
            Text(
              s.runLocationServiceOff,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                color: RwColors.ink950,
              ),
            ),
            const SizedBox(height: RwSpace.xs),
            RwButton.secondary(
              label: s.runLocationServiceEnable,
              onPressed: _busy ? null : _openLocationSettings,
            ),
          ],
          for (final permission in missing) ...[
            const SizedBox(height: RwSpace.sm),
            Text(
              _permissionMessage(s, permission),
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                color: RwColors.ink950,
              ),
            ),
            const SizedBox(height: RwSpace.xs),
            RwButton.secondary(
              label: _needsSettings(permission)
                  ? s.runPermissionSettings
                  : permission == RunPermission.location
                  ? s.runLocationEnable
                  : s.runNotificationsEnable,
              onPressed: _busy
                  ? null
                  : _needsSettings(permission)
                  ? _openSettings
                  : () => _request(permission),
            ),
          ],
          if (_failed) ...[
            const SizedBox(height: RwSpace.sm),
            Text(
              s.runPermissionError,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                color: RwColors.danger500,
              ),
            ),
          ],
          if (_settingsFailed) ...[
            const SizedBox(height: RwSpace.sm),
            Text(
              s.runPermissionSettingsFailed,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                color: RwColors.danger500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _calibrationCard(AppLocalizations s) {
    final status = ref.watch(gpsCalibrationStatusProvider).asData?.value;
    if (status == null || !status.isDue) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: RwSpace.md),
      child: RwCard(
        padding: const EdgeInsets.all(RwSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const GpsCalibrationBadge(size: 56),
                const SizedBox(width: RwSpace.sm),
                Expanded(
                  child: Text(
                    s.calibrationDueTitle,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: RwColors.ink950,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: RwSpace.xs),
            Text(
              s.calibrationDueBody,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 12,
                color: RwColors.mutedTextOnLight,
              ),
            ),
            const SizedBox(height: RwSpace.sm),
            RwButton.secondary(
              label: s.calibrationCta,
              onPressed: _openCalibration,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCalibration() async {
    await showGpsCalibrationSheet(context);
    if (mounted) ref.invalidate(gpsCalibrationStatusProvider);
  }

  Future<void> _startSession() => _run((_) async {
    await ref.read(runGpsProbeProvider.notifier).stop();
    if (mounted) Navigator.of(context).pop(true);
  });
}
