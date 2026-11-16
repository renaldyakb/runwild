import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/components/rw_button.dart';
import 'package:runwild/design/components/rw_chip.dart';
import 'package:runwild/design/components/rw_stat_tile.dart';
import 'package:runwild/design/components/rw_state_view.dart';
import 'package:runwild/design/theme/rw_theme.dart';
import 'package:runwild/design/tokens/rw_tokens.dart';

import 'support.dart';

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return (max(l1, l2) + .05) / (min(l1, l2) + .05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadArchivo);

  test('Brand pairs meet AA including pressed, chips and both surfaces', () {
    final pairs = [
      (RwColors.ink950, RwColors.lime500),
      (RwColors.ink950, RwColors.lime600),
      (RwColors.ink950, RwColors.lime300),
      (RwColors.ink950, RwColors.lime100),
      (RwColors.lime700, RwColors.paper50),
      (RwColors.limeTextOnLight, RwColors.paper100),
      (RwColors.ink500, RwColors.paper50),
      (RwColors.mutedTextOnLight, RwColors.paper100),
      (RwColors.lime500, RwColors.ink800),
    ];
    for (final (foreground, background) in pairs) {
      expect(
        contrast(foreground, background),
        greaterThanOrEqualTo(4.5),
        reason: '$foreground on $background',
      );
    }
    for (final theme in [RwTheme.light, RwTheme.dark]) {
      final c = theme.colorScheme;
      for (final background in [c.surface, c.surfaceContainer]) {
        for (final foreground in [c.onSurface, c.onSurfaceVariant, c.primary]) {
          expect(contrast(foreground, background), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(c.outline, background), greaterThanOrEqualTo(3));
      }
    }
  });

  testWidgets('Buttons block repeat actions when loading or disabled', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      componentHost(
        Column(
          children: [
            RwButton.primary(label: 'Aktif', onPressed: () => presses++),
            const RwButton.primary(label: 'Nonaktif', onPressed: null),
            RwButton.primary(
              label: 'Simpan',
              loadingLabel: 'Memproses',
              loading: true,
              onPressed: () => presses++,
            ),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Aktif'));
    await tester.tap(find.text('Nonaktif'));
    await tester.tap(find.text('Memproses'));
    expect(presses, 1);
    for (final button in find.byType(FilledButton).evaluate()) {
      expect(
        tester.getSize(find.byWidget(button.widget)).height,
        greaterThanOrEqualTo(56),
      );
    }
  });

  for (final dark in [false, true]) {
    testWidgets('Component golden ${dark ? 'dark' : 'light'}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 932));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        componentHost(
          RepaintBoundary(
            key: const ValueKey('golden'),
            child: ColoredBox(
              color: (dark ? RwTheme.dark : RwTheme.light).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RwButton.primary(
                      label: 'Coba tombol utama',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    RwButton.secondary(
                      label: 'Buka contoh dialog',
                      onPressed: () {},
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        RwChip(
                          label: 'Bebas',
                          selected: true,
                          onSelected: (_) {},
                        ),
                        RwChip(
                          label: 'Interval',
                          selected: false,
                          onSelected: (_) {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const RwStatTile(
                      label: 'Jarak',
                      value: '--',
                      unit: 'km',
                      semanticLabel: 'Jarak belum tersedia',
                      icon: Icons.route_outlined,
                    ),
                    const SizedBox(height: 16),
                    RwStateView(state: RwViewState.empty, onAction: () {}),
                  ],
                ),
              ),
            ),
          ),
          dark: dark,
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byKey(const ValueKey('golden')),
        matchesGoldenFile('goldens/components_${dark ? 'dark' : 'light'}.png'),
      );
    });
  }
}
