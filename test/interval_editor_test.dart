import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/domain/interval/interval_engine.dart';
import 'package:runwild/features/run/application/run_journal.dart';
import 'package:runwild/features/run/presentation/interval_options.dart';

import 'support.dart';

void main() {
  setUpAll(loadArchivo);

  testWidgets('Hidden validator fields never paint outside their box', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [runOwnerProvider.overrideWithValue(() => null)],
        child: componentHost(
          const IntervalEditor(initial: defaultIntervalConfig),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(5));
    for (final element in fields.evaluate()) {
      final finder = find.byWidget(element.widget);
      // Kolom meregangkan lebar, tetapi tingginya tetap 1 px dan ter-clip.
      expect(tester.getSize(finder).height, 1);
      expect(
        find.ancestor(of: finder, matching: find.byType(ClipRect)),
        findsWidgets,
      );
    }
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Interval editor layout dark=$dark scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [runOwnerProvider.overrideWithValue(() => null)],
            child: componentHost(
              const IntervalEditor(initial: defaultIntervalConfig),
              dark: dark,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        if (scale == 1) {
          await expectLater(
            find.byType(Scaffold).first,
            matchesGoldenFile(
              'goldens/interval_${dark ? 'dark' : 'light'}.png',
            ),
          );
        }
        await tester.ensureVisible(find.text('Gunakan interval'));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
