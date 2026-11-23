import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/app_update_service.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/domain/stats/stats_engine.dart';
import 'package:runwild/features/activities/presentation/activities_screen.dart';
import 'package:runwild/features/foundation/application/home_stats_provider.dart';
import 'package:runwild/features/foundation/presentation/home_dashboard.dart';
import 'package:runwild/l10n/generated/app_localizations.dart';

Widget _testHost(Widget child) => MaterialApp(
  theme: RwTheme.light,
  locale: const Locale('id'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

class _NoUpdates implements AppUpdateService {
  @override
  Future<AppUpdateInfo?> checkForUpdate({bool notify = true}) async => null;
}

void main() {
  group('Upgrade #4: Weekly Goal Celebration & Progress Shortcut', () {
    testWidgets(
      'HomeDashboard renders goal celebration state when completed >= target',
      (tester) async {
        final summary = (
          weekStart: DateTime(2026, 11, 10),
          weekEnd: DateTime(2026, 11, 16),
          totalDistanceMeters: 18500.0,
          totalMovingTime: const Duration(hours: 2),
          totalCalories: 950,
          sessionCount: 4,
          targetSessions: 3,
          streakWeeks: 2,
          dailyBars: <DailyBar>[],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appUpdateServiceProvider.overrideWithValue(_NoUpdates()),
              weekSummaryProvider.overrideWith((ref) => Future.value(summary)),
              recommendedSessionProvider.overrideWith(
                (ref) => Future.value((
                  title: 'Lari Bebas 30m',
                  description: 'Pemanasan dan lari santai',
                  isFree: true,
                  preset: null,
                )),
              ),
            ],
            child: _testHost(HomeDashboard(onStart: () {})),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Target minggu ini tuntas'), findsOneWidget);
        expect(find.text('4 dari 3 sesi'), findsOneWidget);
      },
    );

    testWidgets('ActivitiesScreen renders Statistik shortcut button', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: _testHost(ActivitiesScreen(onStart: () {}))),
      );

      await tester.pumpAndSettle();

      expect(find.text('Statistik'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    });
  });
}
