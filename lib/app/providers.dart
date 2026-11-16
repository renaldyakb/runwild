import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/services/firebase_bootstrap.dart';

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void select(ThemeMode mode) => state = ThemeMode.light;
}

final backendInitializerProvider = Provider<BackendInitializer>(
  (ref) => const FirebaseBootstrap(),
);
final backendStatusProvider = FutureProvider<BackendStatus>(
  (ref) => ref.watch(backendInitializerProvider).initialize(),
);
