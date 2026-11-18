import 'package:flutter_test/flutter_test.dart';
import 'package:runwild/core/services/app_update_service.dart';

void main() {
  group('AppUpdateService semver tests', () {
    test('isNewerVersion detects major update', () {
      expect(GitHubAppUpdateService.isNewerVersion('1.0.0', '0.1.0'), isTrue);
      expect(GitHubAppUpdateService.isNewerVersion('0.1.0', '1.0.0'), isFalse);
    });

    test('isNewerVersion detects minor update', () {
      expect(GitHubAppUpdateService.isNewerVersion('0.2.0', '0.1.0'), isTrue);
      expect(GitHubAppUpdateService.isNewerVersion('0.1.0', '0.2.0'), isFalse);
    });

    test('isNewerVersion detects patch update', () {
      expect(GitHubAppUpdateService.isNewerVersion('0.1.1', '0.1.0'), isTrue);
      expect(GitHubAppUpdateService.isNewerVersion('0.1.0', '0.1.1'), isFalse);
    });

    test('isNewerVersion handles equal versions and prefixes', () {
      expect(GitHubAppUpdateService.isNewerVersion('v0.1.0', '0.1.0'), isFalse);
      expect(GitHubAppUpdateService.isNewerVersion('0.1.0', '0.1.0'), isFalse);
      expect(GitHubAppUpdateService.isNewerVersion('v0.2.0', '0.1.0'), isTrue);
    });

    test('isNewerVersion handles versions with build suffix', () {
      expect(
        GitHubAppUpdateService.isNewerVersion('0.2.0+2', '0.1.0+1'),
        isTrue,
      );
    });
  });
}
