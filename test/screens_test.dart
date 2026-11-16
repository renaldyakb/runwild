import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadArchivo);

  for (final dark in [false, true]) {
    testWidgets('Home golden dark=$dark', (tester) async {
      await pumpRunwild(tester, size: const Size(430, 932), dark: dark);
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/home_${dark ? 'dark' : 'light'}.png'),
      );
    });
    testWidgets('Catalog golden dark=$dark', (tester) async {
      await pumpRunwild(
        tester,
        path: '/catalog',
        size: const Size(430, 932),
        dark: dark,
      );
      await expectLater(
        find.byType(Scaffold).first,
        matchesGoldenFile('goldens/catalog_${dark ? 'dark' : 'light'}.png'),
      );
    });
  }
}
