import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

abstract interface class RunWakelock {
  Future<void> enable();
  Future<void> disable();
}

class DeviceRunWakelock implements RunWakelock {
  const DeviceRunWakelock();

  @override
  Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Wakelock enable failed: $e');
    }
  }

  @override
  Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('Wakelock disable failed: $e');
    }
  }
}

final runWakelockProvider = Provider<RunWakelock>((ref) {
  return const DeviceRunWakelock();
});
