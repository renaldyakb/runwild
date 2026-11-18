import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../run/application/run_journal.dart';
import '../domain/user_profile.dart';

typedef CurrentProfileUser = ({
  String? uid,
  String? email,
  String? displayName,
});

final currentProfileUserProvider = Provider<CurrentProfileUser>((ref) {
  if (Firebase.apps.isEmpty) {
    return (uid: 'guest', email: '', displayName: 'Pelari RUNWILD');
  }
  final user = FirebaseAuth.instance.currentUser;
  return (uid: user?.uid, email: user?.email, displayName: user?.displayName);
});

abstract interface class ProfileRepository {
  Future<UserProfile?> fetchProfile(String uid);
  Future<void> updateProfile(String uid, UserProfile profile);
  Future<void> deleteAccount(String uid);
}

class ProfileAuthRecentLoginRequiredException implements Exception {
  const ProfileAuthRecentLoginRequiredException();
}

class FirestoreProfileRepository implements ProfileRepository {
  FirestoreProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required this.journal,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final RunJournal journal;
  UserProfile? _cachedProfile;

  @override
  Future<UserProfile?> fetchProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) {
        return _cachedProfile;
      }
      final prof = UserProfile.fromFirestore(doc.data()!);
      _cachedProfile = prof;
      return prof;
    } catch (error) {
      // Offline atau rules menolak: cache tetap dipakai, tetapi kegagalannya
      // harus terlihat di log (jenis error saja, tanpa data pribadi).
      debugPrint('Profile fetch failed, using cache: ${error.runtimeType}');
      return _cachedProfile;
    }
  }

  @override
  Future<void> updateProfile(String uid, UserProfile profile) async {
    _cachedProfile = profile;
    final doc = _firestore.collection('users').doc(uid);
    await doc.set({
      ...profile.toFirestoreMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteAccount(String uid) async {
    // 1. Hapus subkoleksi activities di Firestore
    final activitiesSnapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('activities')
        .get();

    final batch = _firestore.batch();
    for (final doc in activitiesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    // Hapus dokumen user utama
    batch.delete(_firestore.collection('users').doc(uid));
    await batch.commit();

    // 2. Hapus seluruh data SQLite lokal
    await journal.purgeUserData(uid);

    // 3. Hapus akun pengguna Firebase Auth
    final user = _auth.currentUser;
    if (user != null && user.uid == uid) {
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          throw const ProfileAuthRecentLoginRequiredException();
        }
        rethrow;
      }
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final journal = ref.watch(runJournalProvider);
  return FirestoreProfileRepository(journal: journal);
});

final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((
  ref,
) async {
  final user = ref.watch(currentProfileUserProvider);
  if (user.uid == null) return null;
  final repo = ref.watch(profileRepositoryProvider);
  return repo.fetchProfile(user.uid!);
});
