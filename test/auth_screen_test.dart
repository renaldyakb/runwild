import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/features/auth/application/auth_session.dart';
import 'package:runwild/features/onboarding/application/intro_preferences.dart';

import 'support.dart';

class _CompletedIntro implements IntroPreferences {
  @override
  Future<bool> isComplete() async => true;

  @override
  Future<void> complete() async {}
}

class _FakeAuth implements AuthService {
  _FakeAuth(this.session);
  AuthSession session;
  final updates = StreamController<AuthSession>.broadcast();
  bool offline = false;
  bool cancelGoogle = false;
  bool cancelApple = false;
  String? resetEmail;

  @override
  Stream<AuthSession> sessions() async* {
    yield session;
    yield* updates.stream;
  }

  Future<void> _set(AuthSession next) async {
    session = next;
    updates.add(next);
  }

  @override
  Future<void> signIn(String email, String password) async {
    if (offline) throw const AuthFailure(AuthProblem.offline);
    await _set(AuthSession.member);
  }

  @override
  Future<void> register(String email, String password) =>
      _set(AuthSession.member);

  @override
  Future<void> continueAsGuest() => _set(AuthSession.guest);

  @override
  Future<void> signInWithGoogle() async {
    if (cancelGoogle) throw const AuthFailure(AuthProblem.canceled);
    await _set(AuthSession.member);
  }

  @override
  Future<void> signInWithApple() async {
    if (cancelApple) throw const AuthFailure(AuthProblem.canceled);
    await _set(AuthSession.member);
  }

  @override
  Future<void> resetPassword(String email) async => resetEmail = email;

  @override
  Future<void> signOut() => _set(AuthSession.signedOut);
}

void main() {
  testWidgets('Google menangani pembatalan dan percobaan ulang', (
    tester,
  ) async {
    final auth = _FakeAuth(AuthSession.signedOut)..cancelGoogle = true;
    addTearDown(auth.updates.close);
    await pumpRunwild(tester, path: '/start', authService: auth);
    final google = find.text('Masuk dengan Google');
    await tester.ensureVisible(google);
    await tester.tap(google);
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Masuk dengan Google');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Proses masuk dibatalkan.'), findsOneWidget);
    expect(auth.session, AuthSession.signedOut);
    auth.cancelGoogle = false;
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Kejar jarakmu.'), findsOneWidget);
  });
  testWidgets('iOS menawarkan Apple dan tamu dapat menautkannya', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final auth = _FakeAuth(AuthSession.guest)..cancelApple = true;
    addTearDown(auth.updates.close);
    await pumpRunwild(tester, path: '/start', authService: auth);
    expect(find.text('Masuk dengan Apple'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpRunwild(tester, path: '/profile', authService: auth);
    final link = find.text('Tautkan Apple');
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(FilledButton, 'Tautkan Apple');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Proses masuk dibatalkan.'), findsOneWidget);
    expect(auth.session, AuthSession.guest);
    auth.cancelApple = false;
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(auth.session, AuthSession.member);
    expect(find.text('Kejar jarakmu.'), findsOneWidget);
  });
  testWidgets('Form menolak email kosong dan bisa masuk setelah offline', (
    tester,
  ) async {
    final auth = _FakeAuth(AuthSession.signedOut)..offline = true;
    addTearDown(auth.updates.close);
    await pumpRunwild(tester, path: '/auth/sign-in', authService: auth);
    final submit = find.widgetWithText(FilledButton, 'Masuk');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Masukkan alamat email yang valid.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).first,
      'runner@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(
      find.text('Koneksi terputus. Sambungkan internet lalu coba lagi.'),
      findsOneWidget,
    );
    auth.offline = false;
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Kejar jarakmu.'), findsOneWidget);
  });

  testWidgets('Sesi tamu dipulihkan, dapat menautkan email dan keluar', (
    tester,
  ) async {
    final auth = _FakeAuth(AuthSession.guest);
    addTearDown(auth.updates.close);
    await pumpRunwild(
      tester,
      path: '/splash',
      introPreferences: _CompletedIntro(),
      authService: auth,
    );
    await tester.pumpAndSettle();
    expect(find.text('Kejar jarakmu.'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    final link = find.text('Tautkan email');
    await tester.ensureVisible(link);
    await tester.tap(link);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'runner@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.widgetWithText(FilledButton, 'Tautkan email'));
    await tester.pumpAndSettle();
    expect(auth.session, AuthSession.member);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    final signOut = find.text('Keluar');
    await tester.ensureVisible(signOut);
    await tester.tap(signOut);
    await tester.pumpAndSettle();
    expect(find.text('SIAP BERGERAK?'), findsOneWidget);
    await tester.tap(find.text('Lanjut sebagai tamu'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lanjut sebagai tamu'));
    await tester.pumpAndSettle();
    expect(auth.session, AuthSession.guest);
  });

  testWidgets('Reset mengirim email yang sudah dibersihkan', (tester) async {
    final auth = _FakeAuth(AuthSession.signedOut);
    addTearDown(auth.updates.close);
    await pumpRunwild(tester, path: '/auth/reset', authService: auth);
    await tester.enterText(find.byType(TextFormField), ' runner@example.com ');
    await tester.tap(find.text('Kirim tautan reset'));
    await tester.pumpAndSettle();
    expect(auth.resetEmail, 'runner@example.com');
    expect(find.textContaining('Jika email terdaftar'), findsOneWidget);
  });
}
