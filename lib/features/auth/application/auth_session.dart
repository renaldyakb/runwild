import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/providers.dart';
import '../../../core/services/firebase_bootstrap.dart';

enum AuthSession { signedOut, guest, member }

enum AuthProblem {
  offline,
  rejected,
  emailInUse,
  weakPassword,
  unavailable,
  googleUnavailable,
  canceled,
  failed,
}

final class AuthFailure implements Exception {
  const AuthFailure(this.problem);
  final AuthProblem problem;
}

abstract interface class AuthService {
  Stream<AuthSession> sessions();
  Future<void> signIn(String email, String password);
  Future<void> register(String email, String password);
  Future<void> continueAsGuest();
  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> resetPassword(String email);
  Future<void> signOut();
}

final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final status = await ref.watch(backendStatusProvider.future);
  if (status != BackendStatus.ready) {
    throw const AuthFailure(AuthProblem.unavailable);
  }
  return _FirebaseAuthService(FirebaseAuth.instance);
}, retry: (count, error) => null);

final authSessionProvider = StreamProvider<AuthSession>((ref) async* {
  final service = await ref.watch(authServiceProvider.future);
  yield* service.sessions();
}, retry: (count, error) => null);

class _FirebaseAuthService implements AuthService {
  _FirebaseAuthService(this._auth);
  final FirebaseAuth _auth;
  static Future<void>? _googleInitialization;

  @override
  Stream<AuthSession> sessions() => _auth.userChanges().map(
    (user) => user == null
        ? AuthSession.signedOut
        : user.isAnonymous
        ? AuthSession.guest
        : AuthSession.member,
  );

  @override
  Future<void> signIn(String email, String password) => _perform(() async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  });

  @override
  Future<void> register(String email, String password) => _perform(() async {
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      await user.linkWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } else {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  });

  @override
  Future<void> continueAsGuest() => _perform(() async {
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  });

  @override
  Future<void> signInWithGoogle() => _perform(() async {
    const serverClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (serverClientId.isEmpty) {
      throw const AuthFailure(AuthProblem.googleUnavailable);
    }
    final google = GoogleSignIn.instance;
    try {
      await (_googleInitialization ??= google.initialize(
        serverClientId: serverClientId,
      ));
    } on Exception {
      _googleInitialization = null;
      throw const AuthFailure(AuthProblem.googleUnavailable);
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (error) {
      throw AuthFailure(switch (error.code) {
        GoogleSignInExceptionCode.canceled => AuthProblem.canceled,
        GoogleSignInExceptionCode.clientConfigurationError ||
        GoogleSignInExceptionCode.providerConfigurationError =>
          AuthProblem.googleUnavailable,
        _ => AuthProblem.failed,
      });
    }
    final token = account.authentication.idToken;
    if (token == null) throw const AuthFailure(AuthProblem.googleUnavailable);
    final credential = GoogleAuthProvider.credential(idToken: token);
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      await user.linkWithCredential(credential);
    } else {
      await _auth.signInWithCredential(credential);
    }
  });

  @override
  Future<void> resetPassword(String email) => _perform(() async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'user-not-found') rethrow;
    }
  });

  @override
  Future<void> signInWithApple() => _perform(() async {
    final provider = AppleAuthProvider();
    final user = _auth.currentUser;
    if (user != null && user.isAnonymous) {
      await user.linkWithProvider(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  });

  @override
  Future<void> signOut() => _perform(_auth.signOut);

  Future<void> _perform(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(switch (error.code) {
        'canceled' ||
        'web-context-canceled' ||
        'web-context-cancelled' => AuthProblem.canceled,
        'network-request-failed' => AuthProblem.offline,
        'invalid-email' ||
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'user-disabled' => AuthProblem.rejected,
        'email-already-in-use' ||
        'credential-already-in-use' => AuthProblem.emailInUse,
        'weak-password' => AuthProblem.weakPassword,
        'operation-not-allowed' => AuthProblem.unavailable,
        _ => AuthProblem.failed,
      });
    }
  }
}
