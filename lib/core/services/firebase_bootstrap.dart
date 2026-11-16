import 'package:firebase_core/firebase_core.dart';

enum BackendStatus { local, ready, invalid, failed }

abstract interface class BackendInitializer {
  Future<BackendStatus> initialize();
}

class FirebaseBootstrap implements BackendInitializer {
  const FirebaseBootstrap();

  @override
  Future<BackendStatus> initialize() async {
    const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
    const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    const bucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
    const bundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
    const values = [apiKey, appId, senderId, projectId];
    if (values.every((value) => value.isEmpty)) return BackendStatus.local;
    if (values.any((value) => value.isEmpty)) return BackendStatus.invalid;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: const FirebaseOptions(
            apiKey: apiKey,
            appId: appId,
            messagingSenderId: senderId,
            projectId: projectId,
            storageBucket: bucket,
            iosBundleId: bundleId,
          ),
        );
      }
      return BackendStatus.ready;
    } on Exception {
      // Never forward configuration or exception payloads to telemetry.
      return BackendStatus.failed;
    }
  }
}
