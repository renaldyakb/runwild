import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/components/rw_motion.dart';

void main() {
  testWidgets('RwEntrance animates in and cleans up timers on dispose', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RwEntrance(order: 2, child: Text('Kartu Beranda')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kartu Beranda'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('RwCountUp counts to target and respects disableAnimations', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RwCountUp(
              value: 5.25,
              builder: (_, v) => Text(v.toStringAsFixed(2)),
            ),
          ),
        ),
      ),
    );
    expect(find.text('5.25'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RwCountUp(
            value: 10.50,
            builder: (_, v) => Text(v.toStringAsFixed(2)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('10.50'), findsOneWidget);
  });

  testWidgets('RwPressScale & RwPhaseSwitcher respond without errors', (
    tester,
  ) async {
    var phase = 3;
    late StateSetter setLocalState;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              setLocalState = setState;
              return RwPressScale(
                child: RwPhaseSwitcher(
                  child: Text('$phase', key: ValueKey(phase)),
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    final gesture = await tester.startGesture(tester.getCenter(find.text('3')));
    await tester.pump(const Duration(milliseconds: 60));
    await gesture.up();
    setLocalState(() => phase = 2);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
