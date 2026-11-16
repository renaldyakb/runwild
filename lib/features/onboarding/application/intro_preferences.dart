import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class IntroPreferences {
  Future<bool> isComplete();
  Future<void> complete();
}

final introPreferencesProvider = Provider<IntroPreferences>(
  (ref) => _LocalIntroPreferences(SharedPreferencesAsync()),
);

class _LocalIntroPreferences implements IntroPreferences {
  _LocalIntroPreferences(this._preferences);

  static const _key = 'runwild.intro_complete';
  final SharedPreferencesAsync _preferences;

  @override
  Future<bool> isComplete() async => await _preferences.getBool(_key) ?? false;

  @override
  Future<void> complete() => _preferences.setBool(_key, true);
}
