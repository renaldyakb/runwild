import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:runwild/design/components/google_logo_icon.dart';
import 'package:runwild/features/auth/application/auth_session.dart';
import 'package:runwild/features/auth/presentation/account_actions.dart';
import 'package:runwild/features/onboarding/application/intro_preferences.dart';
import 'package:runwild/l10n/generated/app_localizations.dart';

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
  int googleAttempts = 0;
  int appleAttempts = 0;
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
    googleAttempts++;
    if (cancelGoogle) throw const AuthFailure(AuthProblem.canceled);
    await _set(AuthSession.member);
  }

  @override
  Future<void> signInWithApple() async {
    appleAttempts++;
    if (cancelApple) throw const AuthFailure(AuthProblem.canceled);
    await _set(AuthSession.member);
  }

  @override
  Future<void> resetPassword(String email) async => resetEmail = email;

  @override
  Future<void> signOut() => _set(AuthSession.signedOut);
}

void main() {
  testWidgets(
    'Google langsung masuk tanpa halaman konfirmasi dan tanpa tombol tamu',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final auth = _FakeAuth(AuthSession.signedOut)..cancelGoogle = true;
      addTearDown(auth.updates.close);

      await pumpRunwild(tester, path: '/start', authService: auth);
      expect(find.text('Lanjut sebagai tamu'), findsNothing);
      expect(find.byType(GoogleLogoIcon), findsOneWidget);

      final google = find.text('Masuk dengan Google');
      await tester.ensureVisible(google);
      await tester.tap(google);
      await tester.pumpAndSettle();

      expect(auth.googleAttempts, 1);
      expect(find.text('Proses masuk dibatalkan.'), findsOneWidget);
      expect(auth.session, AuthSession.signedOut);

      auth.cancelGoogle = false;
      await tester.ensureVisible(google);
      await tester.tap(google);
      await tester.pumpAndSettle();

      expect(auth.googleAttempts, 2);
      expect(auth.session, AuthSession.member);
      expect(find.text('Run Free,'), findsOneWidget);
    },
  );

  testWidgets('iOS menawarkan Apple langsung tanpa halaman konfirmasi', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final auth = _FakeAuth(AuthSession.signedOut)..cancelApple = true;
    addTearDown(auth.updates.close);

    await pumpRunwild(tester, path: '/start', authService: auth);
    expect(find.text('Masuk dengan Apple'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsNothing);
    expect(find.text('Lanjut sebagai tamu'), findsNothing);

    final apple = find.text('Masuk dengan Apple');
    await tester.ensureVisible(apple);
    await tester.tap(apple);
    await tester.pumpAndSettle();
    expect(auth.appleAttempts, 1);
    expect(find.text('Proses masuk dibatalkan.'), findsOneWidget);

    auth.cancelApple = false;
    await tester.ensureVisible(apple);
    await tester.tap(apple);
    await tester.pumpAndSettle();
    expect(auth.appleAttempts, 2);
    expect(auth.session, AuthSession.member);
    expect(find.text('Run Free,'), findsOneWidget);
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
    expect(find.text('Run Free,'), findsOneWidget);
  });

  testWidgets('Sesi anggota dipulihkan dan bisa keluar kembali ke start', (
    tester,
  ) async {
    final auth = _FakeAuth(AuthSession.member);
    addTearDown(auth.updates.close);
    await pumpRunwild(
      tester,
      path: '/splash',
      introPreferences: _CompletedIntro(),
      authService: auth,
    );
    await tester.pumpAndSettle();
    expect(find.text('Run Free,'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: AccountActions()),
        ),
        GoRoute(
          path: '/start',
          builder: (_, _) => const Scaffold(body: Text('START_SCREEN')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWith((ref) async => auth)],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('id'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Tautkan email'), findsNothing);
    expect(find.text('Keluar'), findsOneWidget);
    await tester.tap(find.text('Keluar'));
    await tester.pumpAndSettle();
    expect(auth.session, AuthSession.signedOut);
    expect(find.text('START_SCREEN'), findsOneWidget);
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
