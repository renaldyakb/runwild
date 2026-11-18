import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ProfileGoal { sehat, lari5k, lari10k, turunBb, lainnya }

enum ProfileLevel { pemula, kembali, rutin }

abstract final class ProfileLimits {
  static const nameLength = 60;
  static const minSessions = 1;
  static const maxSessions = 7;
  static const initialSessions = 3;
}

abstract interface class InitialProfileRepository {
  Future<bool> exists();
  Future<void> save({
    required String name,
    required ProfileGoal goal,
    required ProfileLevel level,
    required int sessions,
  });
}

final initialProfileRepositoryProvider = Provider<InitialProfileRepository>(
  (ref) => _FirestoreInitialProfile(),
);

final initialProfileExistsProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(initialProfileRepositoryProvider).exists(),
  retry: (attempt, error) => null,
);

Future<String> destinationAfterSignIn(
  InitialProfileRepository repository,
) async {
  try {
    if (await repository.exists()) return '/';
  } on Exception {
    // If reading profile fails (offline, connection, or unconfigured firestore),
    // let authenticated user proceed to home screen rather than locking them out.
    return '/';
  }
  return '/profile/setup';
}

class _FirestoreInitialProfile implements InitialProfileRepository {
  @override
  Future<bool> exists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const _ProfileSessionMissing();
    return (await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get())
        .exists;
  }

  @override
  Future<void> save({
    required String name,
    required ProfileGoal goal,
    required ProfileLevel level,
    required int sessions,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw const _ProfileSessionMissing();
    final firestore = FirebaseFirestore.instance;
    final document = firestore.collection('users').doc(user.uid);
    await firestore.runTransaction((transaction) async {
      if ((await transaction.get(document)).exists) return;
      transaction.set(document, {
        'displayName': name,
        'email': user.email ?? '',
        'level': level.name,
        'goal': switch (goal) {
          ProfileGoal.lari5k => 'lari_5k',
          ProfileGoal.lari10k => 'lari_10k',
          ProfileGoal.turunBb => 'turun_bb',
          _ => goal.name,
        },
        'units': 'km',
        'weeklyGoal': {'type': 'sessions', 'target': sessions},
        'privacy': {
          'hideStartEnd': true,
          'trimMeters': 200,
          'defaultVisibility': 'private',
        },
        'voice': {
          'enabled': true,
          'volume': 0.8,
          'haptics': true,
          'countdownCue': true,
          'roundCue': true,
        },
        'autoPause': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      });
    });
  }
}

class _ProfileSessionMissing implements Exception {
  const _ProfileSessionMissing();
}
