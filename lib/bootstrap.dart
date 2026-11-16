import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/runwild_app.dart';

void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: RunwildApp()));
}
