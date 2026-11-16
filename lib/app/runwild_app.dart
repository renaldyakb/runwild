import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../design/theme/rw_theme.dart';
import '../design/tokens/rw_tokens.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';

class RunwildApp extends StatelessWidget {
  const RunwildApp({super.key});

  @override
  Widget build(BuildContext context) =>
      MediaQuery.fromView(view: View.of(context), child: const _LocalizedApp());
}

class _LocalizedApp extends ConsumerWidget {
  const _LocalizedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).appName,
    debugShowCheckedModeBanner: false,
    theme: RwTheme.light,
    darkTheme: RwTheme.light,
    themeMode: ThemeMode.light,
    themeAnimationDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : RwMotion.transition,
    locale: const Locale('id'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: ref.watch(routerProvider),
  );
}
