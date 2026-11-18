import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  const AppVersion._();

  static String get current => _package?.version ?? '?';
  static String get buildNumber => _package?.buildNumber ?? '?';
  static PackageInfo? _package;

  static Future<void> initialize() async {
    _package = await PackageInfo.fromPlatform();
  }

  static const String repoOwner = 'renaldyakb';
  static const String repoName = 'runwild';
  static const String latestReleaseApi =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String releasesPage =
      'https://github.com/$repoOwner/$repoName/releases';
}
