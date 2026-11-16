import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/core/services/run_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DeviceRunNotifications methods complete safely', () async {
    final notifications = DeviceRunNotifications();
    await expectLater(notifications.initialize(), completes);
    await expectLater(
      notifications.update(
        title: 'RUNWILD · Lari 01:00',
        body: '0.00 km · 00:00',
      ),
      completes,
    );
    await expectLater(notifications.cancel(), completes);
  });
}
