import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

enum RunPermission { location, notifications }

enum RunPermissionStatus { granted, denied, blocked, restricted }

abstract interface class RunPermissions {
  Future<RunPermissionStatus> status(RunPermission permission);
  Future<RunPermissionStatus> request(RunPermission permission);
  Future<bool> openSettings();
}

final runPermissionsProvider = Provider<RunPermissions>(
  (ref) => const _SystemRunPermissions(),
);

class _SystemRunPermissions implements RunPermissions {
  const _SystemRunPermissions();

  Permission _native(RunPermission permission) => switch (permission) {
    RunPermission.location => Permission.locationWhenInUse,
    RunPermission.notifications => Permission.notification,
  };

  RunPermissionStatus _status(PermissionStatus status) => switch (status) {
    PermissionStatus.granted ||
    PermissionStatus.provisional => RunPermissionStatus.granted,
    PermissionStatus.permanentlyDenied => RunPermissionStatus.blocked,
    PermissionStatus.restricted => RunPermissionStatus.restricted,
    _ => RunPermissionStatus.denied,
  };

  @override
  Future<RunPermissionStatus> status(RunPermission permission) async =>
      _status(await _native(permission).status);

  @override
  Future<RunPermissionStatus> request(RunPermission permission) async =>
      _status(await _native(permission).request());

  @override
  Future<bool> openSettings() => openAppSettings();
}
