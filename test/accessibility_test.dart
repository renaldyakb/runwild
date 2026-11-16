import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/components/rw_button.dart';
import 'package:runwild/design/components/rw_chip.dart';
import 'package:runwild/design/components/rw_state_view.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadArchivo);

  testWidgets('Buttons and choices are reachable with keyboard', (
    tester,
  ) async {
    var presses = 0;
    var selected = false;
    await tester.pumpWidget(
      componentHost(
        StatefulBuilder(
          builder: (context, update) => Column(
            children: [
              RwButton.primary(label: 'Aksi', onPressed: () => presses++),
              RwButton.secondary(
                label: 'Aksi kedua',
                onPressed: () => presses++,
              ),
              RwChip(
                label: 'Pilihan',
                selected: selected,
                onSelected: (value) => update(() => selected = value),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(presses, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(presses, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(selected, isTrue);
  });

  for (final dark in [false, true]) {
    testWidgets('Navigation touch targets and labels dark=$dark', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpRunwild(tester, dark: dark);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      semantics.dispose();
    });
    for (final state in RwViewState.values) {
      testWidgets('State $state reflows at 200%, dark=$dark', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          componentHost(
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: RwStateView(state: state, onAction: () {}),
              ),
            ),
            dark: dark,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
