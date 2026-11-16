import '../application/initial_profile.dart';

class UserPrivacySettings {
  const UserPrivacySettings({
    this.hideStartEnd = true,
    this.trimMeters = 200,
    this.defaultVisibility = 'private',
  });

  final bool hideStartEnd;
  final int trimMeters;
  final String defaultVisibility;

  Map<String, dynamic> toMap() => {
    'hideStartEnd': hideStartEnd,
    'trimMeters': trimMeters,
    'defaultVisibility': defaultVisibility,
  };

  factory UserPrivacySettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserPrivacySettings();
    return UserPrivacySettings(
      hideStartEnd: map['hideStartEnd'] as bool? ?? true,
      trimMeters: (map['trimMeters'] as num?)?.toInt() ?? 200,
      defaultVisibility: map['defaultVisibility'] as String? ?? 'private',
    );
  }

  UserPrivacySettings copyWith({
    bool? hideStartEnd,
    int? trimMeters,
    String? defaultVisibility,
  }) => UserPrivacySettings(
    hideStartEnd: hideStartEnd ?? this.hideStartEnd,
    trimMeters: trimMeters ?? this.trimMeters,
    defaultVisibility: defaultVisibility ?? this.defaultVisibility,
  );
}

class UserVoiceSettings {
  const UserVoiceSettings({
    this.enabled = true,
    this.volume = 0.8,
    this.haptics = true,
    this.countdownCue = true,
    this.roundCue = true,
  });

  final bool enabled;
  final double volume;
  final bool haptics;
  final bool countdownCue;
  final bool roundCue;

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'volume': volume,
    'haptics': haptics,
    'countdownCue': countdownCue,
    'roundCue': roundCue,
  };

  factory UserVoiceSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserVoiceSettings();
    return UserVoiceSettings(
      enabled: map['enabled'] as bool? ?? true,
      volume: (map['volume'] as num?)?.toDouble() ?? 0.8,
      haptics: map['haptics'] as bool? ?? true,
      countdownCue: map['countdownCue'] as bool? ?? true,
      roundCue: map['roundCue'] as bool? ?? true,
    );
  }

  UserVoiceSettings copyWith({
    bool? enabled,
    double? volume,
    bool? haptics,
    bool? countdownCue,
    bool? roundCue,
  }) => UserVoiceSettings(
    enabled: enabled ?? this.enabled,
    volume: volume ?? this.volume,
    haptics: haptics ?? this.haptics,
    countdownCue: countdownCue ?? this.countdownCue,
    roundCue: roundCue ?? this.roundCue,
  );
}

class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
    required this.level,
    required this.goal,
    this.units = 'km',
    this.weeklyGoalSessions = 3,
    this.privacy = const UserPrivacySettings(),
    this.voice = const UserVoiceSettings(),
    this.autoPause = true,
  });

  final String displayName;
  final String email;
  final ProfileLevel level;
  final ProfileGoal goal;
  final String units;
  final int weeklyGoalSessions;
  final UserPrivacySettings privacy;
  final UserVoiceSettings voice;
  final bool autoPause;

  UserProfile copyWith({
    String? displayName,
    String? email,
    ProfileLevel? level,
    ProfileGoal? goal,
    String? units,
    int? weeklyGoalSessions,
    UserPrivacySettings? privacy,
    UserVoiceSettings? voice,
    bool? autoPause,
  }) => UserProfile(
    displayName: displayName ?? this.displayName,
    email: email ?? this.email,
    level: level ?? this.level,
    goal: goal ?? this.goal,
    units: units ?? this.units,
    weeklyGoalSessions: weeklyGoalSessions ?? this.weeklyGoalSessions,
    privacy: privacy ?? this.privacy,
    voice: voice ?? this.voice,
    autoPause: autoPause ?? this.autoPause,
  );

  Map<String, dynamic> toFirestoreMap() => {
    'displayName': displayName,
    'email': email,
    'level': level.name,
    'goal': switch (goal) {
      ProfileGoal.lari5k => 'lari_5k',
      ProfileGoal.lari10k => 'lari_10k',
      ProfileGoal.turunBb => 'turun_bb',
      _ => goal.name,
    },
    'units': units,
    'weeklyGoal': {'type': 'sessions', 'target': weeklyGoalSessions},
    'privacy': privacy.toMap(),
    'voice': voice.toMap(),
    'autoPause': autoPause,
  };

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    final levelStr = data['level'] as String? ?? 'pemula';
    final goalStr = data['goal'] as String? ?? 'sehat';
    final weeklyGoalMap = data['weeklyGoal'] as Map<String, dynamic>?;

    return UserProfile(
      displayName: data['displayName'] as String? ?? 'Pelari RUNWILD',
      email: data['email'] as String? ?? '',
      level: ProfileLevel.values.firstWhere(
        (l) => l.name == levelStr,
        orElse: () => ProfileLevel.pemula,
      ),
      goal: switch (goalStr) {
        'lari_5k' => ProfileGoal.lari5k,
        'lari_10k' => ProfileGoal.lari10k,
        'turun_bb' => ProfileGoal.turunBb,
        'sehat' => ProfileGoal.sehat,
        _ => ProfileGoal.lainnya,
      },
      units: data['units'] as String? ?? 'km',
      weeklyGoalSessions: (weeklyGoalMap?['target'] as num?)?.toInt() ?? 3,
      privacy: UserPrivacySettings.fromMap(
        data['privacy'] as Map<String, dynamic>?,
      ),
      voice: UserVoiceSettings.fromMap(data['voice'] as Map<String, dynamic>?),
      autoPause: data['autoPause'] as bool? ?? true,
    );
  }
}
