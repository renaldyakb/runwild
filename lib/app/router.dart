import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../design/components/rw_bottom_nav.dart';
import '../design/components/rw_button.dart';
import '../design/components/rw_page.dart';
import '../design/tokens/rw_tokens.dart';
import '../domain/tracking/run_summary.dart';
import '../features/activities/presentation/activities_screen.dart';
import '../features/activities/presentation/activity_detail_screen.dart';
import '../features/activities/presentation/progress_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/catalog/presentation/catalog_screen.dart';
import '../features/foundation/presentation/foundation_screen.dart';
import '../features/foundation/presentation/run_reminders_screen.dart';
import '../features/onboarding/presentation/intro_screen.dart';
import '../features/onboarding/presentation/startup_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/run/application/run_journal.dart';
import '../features/run/presentation/run_active_screen.dart';
import '../features/run/presentation/run_permission_sheet.dart';
import '../features/run/presentation/run_recovery_screen.dart';
import '../features/run/presentation/run_summary_screen.dart';
import '../features/run/presentation/share_card_screen.dart';
import '../l10n/generated/app_localizations.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = createRouter(initialLocation: '/splash');
  ref.onDispose(router.dispose);
  return router;
});

GoRouter createRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/run/active',
      builder: (_, state) => RunActiveScreen(
        resume: state.extra is RunCheckpoint
            ? state.extra as RunCheckpoint
            : null,
      ),
    ),
    GoRoute(
      path: '/run/summary',
      builder: (_, state) =>
          RunSummaryScreen(summary: state.extra as RunSummary),
    ),
    GoRoute(
      path: '/run/share',
      builder: (_, state) =>
          ShareCardScreen(summary: state.extra as RunSummary),
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/reminders',
      builder: (context, state) => const RunRemindersScreen(),
    ),
    GoRoute(
      path: '/activities/:id',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
        return ActivityDetailScreen(sessionId: id);
      },
    ),
    GoRoute(
      path: '/run/recover',
      builder: (_, state) =>
          RunRecoveryScreen(startIfEmpty: state.extra == true),
    ),
    GoRoute(
      path: '/profile/setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/intro', builder: (context, state) => const IntroScreen()),
    GoRoute(
      path: '/start',
      builder: (context, state) => const GetStartedScreen(),
    ),
    for (final (path, form) in [
      ('/auth/sign-in', AuthForm.signIn),
      ('/auth/register', AuthForm.register),
      ('/auth/reset', AuthForm.reset),
    ])
      GoRoute(
        path: path,
        builder: (context, state) => AuthScreen(form: form),
      ),
    ShellRoute(
      builder: (context, state, child) =>
          _AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => FoundationScreen(
            destination: FoundationDestination.home,
            onStart: () => unawaited(_openRun(context)),
          ),
        ),
        GoRoute(
          path: '/activities',
          builder: (context, state) =>
              ActivitiesScreen(onStart: () => unawaited(_openRun(context))),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const FoundationScreen(
            destination: FoundationDestination.profile,
          ),
        ),
      ],
    ),
    if (kDebugMode)
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const CatalogScreen(),
      ),
  ],
  errorBuilder: (context, state) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      body: RwPage(
        children: [
          Text(s.pageMissing, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: RwSpace.md),
          Text(s.pageMissingBody),
          const SizedBox(height: RwSpace.lg),
          RwButton.primary(label: s.backHome, onPressed: () => context.go('/')),
        ],
      ),
    );
  },
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(RwSpace.xs),
            decoration: BoxDecoration(
              color: RwColors.lime500,
              borderRadius: BorderRadius.circular(RwRadius.sm),
            ),
            child: const Icon(Icons.directions_run, color: RwColors.ink950),
          ),
          const SizedBox(width: RwSpace.sm),
          Text(
            AppLocalizations.of(context).appName,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    ),
    body: child,
    bottomNavigationBar: RwBottomNav(
      selectedIndex: location == '/activities'
          ? 2
          : location == '/profile'
          ? 3
          : 0,
      onSelected: (index) {
        switch (index) {
          case 0:
            context.go('/');
          case 1:
            unawaited(_openRun(context));
          case 2:
            context.go('/activities');
          case 3:
            context.go('/profile');
        }
      },
    ),
  );
}

Future<void> _openRun(BuildContext context) async {
  final start = await showRunPermissionSheet(context);
  if (start == true && context.mounted) {
    final hasAccount =
        ProviderScope.containerOf(context).read(runOwnerProvider)() != null;
    if (hasAccount) {
      await context.push<void>('/run/recover', extra: true);
    } else {
      await context.push<void>('/run/active');
    }
  }
}
