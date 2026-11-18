import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:runwild/core/constants/app_version.dart';
import 'package:runwild/core/services/app_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Installed package version is the source of truth', () async {
    PackageInfo.setMockInitialValues(
      appName: 'RUNWILD',
      packageName: 'id.runwild.app',
      version: '0.1.1',
      buildNumber: '2',
      buildSignature: '',
    );
    await AppVersion.initialize();
    expect(AppVersion.current, '0.1.1');
    expect(AppVersion.buildNumber, '2');
    expect(
      GitHubAppUpdateService.isNewerVersion('v0.1.1', AppVersion.current),
      isFalse,
    );
    expect(
      GitHubAppUpdateService.isNewerVersion('v0.1.2', AppVersion.current),
      isTrue,
    );
  });
  test('Build metadata never changes semantic patch ordering', () {
    expect(
      GitHubAppUpdateService.isNewerVersion('0.1.1+99', '0.1.1+2'),
      isFalse,
    );
    expect(
      GitHubAppUpdateService.isNewerVersion('0.1.2+1', '0.1.1+99'),
      isTrue,
    );
    expect(GitHubAppUpdateService.isNewerVersion('0.1.2', '?'), isFalse);
  });
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
