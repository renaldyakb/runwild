import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/components/rw_route_view.dart';

void main() {
  test('decodePolylinePoints accurately decodes standard polyline', () {
    const encoded = '_p~iF~ps|U_ulLnnqC_mqNvxq`@';
    final points = decodePolylinePoints(encoded);

    expect(points.length, 3);
    expect(points[0].latitude, closeTo(38.5, 0.0001));
    expect(points[0].longitude, closeTo(-120.2, 0.0001));
    expect(points[1].latitude, closeTo(40.7, 0.0001));
    expect(points[1].longitude, closeTo(-120.95, 0.0001));
    expect(points[2].latitude, closeTo(43.252, 0.0001));
    expect(points[2].longitude, closeTo(-126.453, 0.0001));
  });

  testWidgets(
    'RunRouteView renders successfully with coordinates and polyline',
    (tester) async {
      const testPoints = [
        (latitude: -6.2000, longitude: 106.8166),
        (latitude: -6.2050, longitude: 106.8200),
        (latitude: -6.2100, longitude: 106.8250),
        (latitude: -6.2150, longitude: 106.8300),
      ];

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 300,
            height: 200,
            child: RunRouteView(points: testPoints),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RunRouteView), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RunRouteView renders fallback placeholder smoothly with empty points',
    (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 300,
            height: 200,
            child: RunRouteView(points: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RunRouteView), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
