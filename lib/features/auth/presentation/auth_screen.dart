import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_loading.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../profile/application/initial_profile.dart';
import '../application/auth_session.dart';

enum AuthForm { signIn, register, reset, guest, google, apple }

String authErrorMessage(AppLocalizations s, Object error) {
  final problem = error is AuthFailure ? error.problem : AuthProblem.failed;
  return switch (problem) {
    AuthProblem.offline => s.authOffline,
    AuthProblem.rejected => s.authRejected,
    AuthProblem.emailInUse => s.authEmailInUse,
    AuthProblem.weakPassword => s.authWeakPassword,
    AuthProblem.unavailable => s.authUnavailable,
    AuthProblem.googleUnavailable => s.authGoogleUnavailable,
    AuthProblem.canceled => s.authProviderCanceled,
    AuthProblem.failed => s.authFailed,
  };
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({required this.form, super.key});
  final AuthForm form;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  Object? _error;
  bool _busy = false;
  bool _resetSent = false;

  bool get _usesEmail => switch (widget.form) {
    AuthForm.signIn || AuthForm.register || AuthForm.reset => true,
    _ => false,
  };

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final mode = widget.form;
    if (_usesEmail && _formKey.currentState?.validate() != true) {
      return;
    }
    final email = _email.text.trim();
    final password = _password.text;
    setState(() {
      _busy = true;
      _error = null;
      _resetSent = false;
    });
    try {
      final service = await ref.read(authServiceProvider.future);
      if (!mounted) return;
      await switch (mode) {
        AuthForm.signIn => service.signIn(email, password),
        AuthForm.register => service.register(email, password),
        AuthForm.reset => service.resetPassword(email),
        AuthForm.guest => service.continueAsGuest(),
        AuthForm.google => service.signInWithGoogle(),
        AuthForm.apple => service.signInWithApple(),
      };
      if (!mounted) return;
      if (mode == AuthForm.reset) {
        setState(() => _resetSent = true);
      } else {
        final destination = await destinationAfterSignIn(
          ref.read(initialProfileRepositoryProvider),
        );
        if (mounted) context.go(destination);
      }
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mode = widget.form;
    final service = ref.watch(authServiceProvider);
    final loading = service.isLoading;
    final error = _error ?? service.error;
    final title = switch (mode) {
      AuthForm.signIn => s.signIn,
      AuthForm.register =>
        ref.watch(authSessionProvider).value == AuthSession.guest
            ? s.authLink
            : s.authRegister,
      AuthForm.reset => s.authForgot,
      AuthForm.guest => s.authGuest,
      AuthForm.google =>
        ref.watch(authSessionProvider).value == AuthSession.guest
            ? s.authGoogleLink
            : s.authGoogle,
      AuthForm.apple =>
        ref.watch(authSessionProvider).value == AuthSession.guest
            ? s.authAppleLink
            : s.authApple,
    };

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Stack(
          children: [
            Semantics(liveRegion: true, child: Text(s.authLoading)),
            const RwFullPageLoading(),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      body: RwPage(
        children: [
          if (service.hasError) ...[
            Semantics(
              liveRegion: true,
              child: Text(
                authErrorMessage(
                  s,
                  error ?? const AuthFailure(AuthProblem.failed),
                ),
                style: TextStyle(
                  fontFamily: RwType.family,
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: RwSpace.md),
            RwButton.primary(
              label: s.retry,
              fullWidth: true,
              onPressed: () {
                setState(() => _error = null);
                ref.invalidate(backendStatusProvider);
              },
            ),
          ] else ...[
            // Brand Accent Header
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(RwSpace.xs),
                decoration: BoxDecoration(
                  color: RwColors.ink950,
                  borderRadius: BorderRadius.circular(RwRadius.sm),
                ),
                child: const Icon(
                  Icons.directions_run_rounded,
                  color: RwColors.lime500,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: RwSpace.sm),
            Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontFamily: RwType.family,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: RwColors.ink950,
                ),
              ),
            ),
            const SizedBox(height: RwSpace.lg),

            if (_usesEmail)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _email,
                      enabled: !_busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: s.authEmail,
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          size: 20,
                        ),
                      ),
                      validator: (value) =>
                          RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch(value?.trim() ?? '')
                          ? null
                          : s.authEmailInvalid,
                    ),
                    if (mode != AuthForm.reset) ...[
                      const SizedBox(height: RwSpace.md),
                      TextFormField(
                        controller: _password,
                        enabled: !_busy,
                        obscureText: _obscurePassword,
                        autofillHints: [
                          mode == AuthForm.register
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: s.authPassword,
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return s.authPasswordRequired;
                          }
                          if (mode == AuthForm.register && value.length < 6) {
                            return s.authWeakPassword;
                          }
                          return null;
                        },
                      ),
                    ],
                  ],
                ),
              )
            else ...[
              // Social / Guest Explanatory Card
              Container(
                padding: const EdgeInsets.all(RwSpace.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: RwColors.ink950,
                        borderRadius: BorderRadius.circular(RwRadius.sm),
                      ),
                      child: Icon(
                        switch (mode) {
                          AuthForm.google => Icons.g_mobiledata_rounded,
                          AuthForm.apple => Icons.apple_rounded,
                          AuthForm.guest => Icons.person_outline_rounded,
                          _ => Icons.security_rounded,
                        },
                        color: RwColors.lime500,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: RwSpace.md),
                    Expanded(
                      child: Text(
                        switch (mode) {
                          AuthForm.guest => 'Lari sekarang tanpa perlu kata sandi. Progres tersimpan lokal di perangkat.',
                          AuthForm.google => 'Sinkronisasi riwayat lari ke Google Cloud dengan aman.',
                          AuthForm.apple => 'Sinkronisasi riwayat lari ke Apple ID dengan aman.',
                          _ => title,
                        },
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 13,
                          color: RwColors.ink800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (error != null)
              Container(
                margin: const EdgeInsets.only(top: RwSpace.md),
                padding: const EdgeInsets.all(RwSpace.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFB91C1C),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          authErrorMessage(s, error),
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            color: Color(0xFFB91C1C),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_resetSent)
              Container(
                margin: const EdgeInsets.only(top: RwSpace.md),
                padding: const EdgeInsets.all(RwSpace.sm),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Color(0xFF15803D),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          s.authResetSent,
                          style: const TextStyle(
                            fontFamily: RwType.family,
                            color: Color(0xFF15803D),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: RwSpace.lg),
            RwButton.primary(
              label: mode == AuthForm.reset ? s.authReset : title,
              onPressed: _submit,
              loading: _busy,
              loadingLabel: s.authWorking,
              fullWidth: true,
            ),
            if (mode == AuthForm.signIn) ...[
              const SizedBox(height: RwSpace.sm),
              RwButton.secondary(
                label: s.authForgot,
                fullWidth: true,
                onPressed: _busy ? null : () => context.push('/auth/reset'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
