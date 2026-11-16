import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/run_wakelock.dart';
import 'package:runwild/design/components/rw_hold_button.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/features/run/presentation/run_active_screen.dart';
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

class _MockWakelock implements RunWakelock {
  bool enabled = false;

  @override
  Future<void> enable() async {
    enabled = true;
  }

  @override
  Future<void> disable() async {
    enabled = false;
  }
}

void main() {
  group('Upgrade #2: Hold To Finish & Wakelock', () {
    testWidgets('RwHoldToFinishButton completes on 1.5s long press', (
      tester,
    ) async {
      bool completed = false;
      bool shortTapped = false;

      await tester.pumpWidget(
        _testHost(
          RwHoldToFinishButton(
            label: 'Selesai',
            onHoldCompleted: () => completed = true,
            onTapShort: () => shortTapped = true,
            holdDuration: const Duration(milliseconds: 1500),
          ),
        ),
      );

      expect(find.text('Selesai'), findsOneWidget);

      // Start hold
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(RwHoldToFinishButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(completed, isFalse);

      // Continue holding to 1500ms
      await tester.pump(const Duration(milliseconds: 1050));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(shortTapped, isFalse);
    });

    testWidgets('RwHoldToFinishButton triggers onTapShort on quick tap', (
      tester,
    ) async {
      bool completed = false;
      bool shortTapped = false;

      await tester.pumpWidget(
        _testHost(
          RwHoldToFinishButton(
            label: 'Selesai',
            onHoldCompleted: () => completed = true,
            onTapShort: () => shortTapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(RwHoldToFinishButton));
      await tester.pumpAndSettle();

      expect(shortTapped, isTrue);
      expect(completed, isFalse);
    });

    testWidgets('RunActiveScreen enables wakelock and disables on unmount', (
      tester,
    ) async {
      final mockWakelock = _MockWakelock();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            runWakelockProvider.overrideWithValue(mockWakelock),
            runCountdownClockProvider.overrideWithValue(() => Duration.zero),
          ],
          child: _testHost(const RunActiveScreen()),
        ),
      );

      await tester.pump();
      expect(mockWakelock.enabled, isTrue);

      // Replace screen to trigger dispose
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            runWakelockProvider.overrideWithValue(mockWakelock),
            runCountdownClockProvider.overrideWithValue(() => Duration.zero),
          ],
          child: _testHost(const SizedBox.shrink()),
        ),
      );

      await tester.pumpAndSettle();
      expect(mockWakelock.enabled, isFalse);
    });
  });
}
