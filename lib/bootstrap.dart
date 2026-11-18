import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/runwild_app.dart';
import 'core/constants/app_version.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppVersion.initialize();
  } catch (error) {
    debugPrint('Package version unavailable: ${error.runtimeType}');
  }
  runApp(const ProviderScope(child: RunwildApp()));
}
