class AppVersion {
  const AppVersion._();

  static const String current = '0.1.0';
  static const int buildNumber = 1;
  static const String repoOwner = 'renaldyakb';
  static const String repoName = 'runwild';
  static const String latestReleaseApi =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';
  static const String releasesPage =
      'https://github.com/$repoOwner/$repoName/releases';
}
