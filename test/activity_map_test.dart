import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/core/services/map_service.dart';

import 'support.dart';

class _Tiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(TileProvider.transparentImage);
}

void main() {
  testWidgets('Historical map fits saved segments without live GPS status', (
    tester,
  ) async {
    await tester.pumpWidget(
      componentHost(
        SingleChildScrollView(
          child: OpenStreetMapService(tileProviderFactory: _Tiles.new)
              .buildLiveMap(
                route: (
                  segments: const [
                    [
                      (latitude: -6.2, longitude: 106.8),
                      (latitude: -6.21, longitude: 106.81),
                    ],
                    [
                      (latitude: -6.22, longitude: 106.82),
                      (latitude: -6.23, longitude: 106.83),
                    ],
                  ],
                  position: null,
                  age: null,
                ),
                locked: false,
                historical: true,
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
    expect(map.options.initialCameraFit, isNotNull);
    final lines = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
    expect(lines.polylines, hasLength(2));
    expect(find.byIcon(Icons.my_location), findsNothing);
    expect(find.textContaining('OpenStreetMap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
