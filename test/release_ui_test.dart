import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/app_update_service.dart';
import 'package:runwild/design/components/rw_route_view.dart';
import 'package:runwild/domain/stats/stats_engine.dart';
import 'package:runwild/features/foundation/application/home_stats_provider.dart';
import 'package:runwild/features/foundation/presentation/app_update_dialog.dart';
import 'package:runwild/features/foundation/presentation/home_dashboard.dart';

import 'support.dart';

class _Updates implements AppUpdateService {
  @override
  Future<AppUpdateInfo?> checkForUpdate({bool notify = true}) async => null;
}

void main() {
  setUpAll(() async {
    await loadArchivo();
    await (FontLoader('Google Sans Flex')
          ..addFont(
            rootBundle.load('assets/fonts/GoogleSansFlex_24pt-Regular.ttf'),
          )
          ..addFont(
            rootBundle.load('assets/fonts/GoogleSansFlex_24pt-Black.ttf'),
          ))
        .load();
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('Readable update notes and dismissal at scale $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        componentHost(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: const AppUpdateDialog(
                    info: AppUpdateInfo(
                      hasUpdate: true,
                      currentVersion: '0.1.1',
                      latestVersion: '0.1.2',
                      releaseNotes: '## Diperbaiki\n- **Versi aplikasi** sesuai APK.\n\n## Diperbarui\n- Drawer judul dan catatan sesi.',
                      downloadUrl: 'https://example.org/app.apk',
                    ),
                  ),
                ),
              ),
              child: const Text('Buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(find.text('Versi aplikasi sesuai APK.'), findsOneWidget);
      expect(find.textContaining('##'), findsNothing);
      expect(tester.takeException(), isNull);
      if (scale == 1) {
        await expectLater(
          find.byType(AppUpdateDialog),
          matchesGoldenFile('goldens/update_readable.png'),
        );
      }
      await tester.ensureVisible(find.text('Nanti saja'));
      await tester.tap(find.text('Nanti saja'));
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdateDialog), findsNothing);
    });

    testWidgets('Home start action and honest empty route at scale $scale', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var started = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appUpdateServiceProvider.overrideWithValue(_Updates()),
            latestRoutePointsProvider.overrideWith((ref) async => []),
            weekSummaryProvider.overrideWith(
              (ref) async => StatsEngine.calculateWeekSummary(
                sessions: [],
                now: DateTime(2026, 11, 18),
                targetSessions: 3,
              ),
            ),
            recommendedSessionProvider.overrideWith(
              (ref) async =>
                  StatsEngine.getRecommendedSession(totalCompletedSessions: 0),
            ),
          ],
          child: componentHost(
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: HomeDashboard(onStart: () => started = true),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RunRouteView), findsNothing);
      if (scale == 1) {
        await expectLater(
          find.byType(Scaffold).first,
          matchesGoldenFile('goldens/home_next_session.png'),
        );
      }
      await tester.ensureVisible(find.text('Mulai berlari'));
      await tester.tap(find.text('Mulai berlari'));
      expect(started, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
