import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/google_logo_icon.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/decor/mountain_silhouette.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_session.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../profile/application/initial_profile.dart';
import '../../run/application/run_journal.dart';
import '../application/intro_preferences.dart';

const splashLottieAsset = 'assets/lottie/splash_runner.json';

/// Durasi minimum tampilan Splash agar animasi Lottie terbaca halus di perangkat.
final splashMinimumDurationProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 1400),
);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_openNextScreen());
    });
  }

  Future<void> _openNextScreen() async {
    setState(() => _failed = false);
    final minDuration = ref.read(splashMinimumDurationProvider);
    final delayFuture = minDuration > Duration.zero
        ? Future<void>.delayed(minDuration)
        : Future<void>.value();
    final bool complete;
    try {
      complete = await ref.read(introPreferencesProvider).isComplete();
    } on Exception {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    if (!complete) {
      await delayFuture;
      if (mounted) context.go('/intro');
      return;
    }
    AuthSession session;
    try {
      final service = await ref.read(authServiceProvider.future);
      session = await service.sessions().first;
    } on Exception {
      // Get Started exposes the auth error when the user selects a method.
      session = AuthSession.signedOut;
    }
    if (!mounted) return;
    final destination = session == AuthSession.signedOut
        ? '/start'
        : await destinationAfterSignIn(
            ref.read(initialProfileRepositoryProvider),
          );
    await delayFuture;
    if (!mounted) return;
    final owner = ref.read(runOwnerProvider)();
    context.go(
      destination == '/' && owner != null ? '/run/recover' : destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (_failed) {
      return _OnboardingPage(
        title: s.appName,
        children: [
          Text(s.splashError),
          const SizedBox(height: RwSpace.md),
          RwButton.primary(
            label: s.retry,
            fullWidth: true,
            onPressed: _openNextScreen,
          ),
        ],
      );
    }

    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: RwColors.ink950,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: RwSpace.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 176,
                  height: 176,
                  child: Lottie.asset(
                    splashLottieAsset,
                    animate: !reduced,
                    repeat: !reduced,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(
                        color: RwColors.lime500,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.directions_run_rounded,
                        color: RwColors.ink950,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: RwSpace.md),
                Text(
                  s.appName,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    color: RwColors.paper100,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: RwSpace.xs),
                Text(
                  s.introTagline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    color: RwColors.lime500,
                    fontSize: RwType.label,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _QuickAuth { google, apple }

class GetStartedScreen extends ConsumerStatefulWidget {
  const GetStartedScreen({super.key});

  @override
  ConsumerState<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends ConsumerState<GetStartedScreen> {
  _QuickAuth? _busyProvider;
  Object? _error;

  bool get _busy => _busyProvider != null;

  Future<void> _signInQuick(_QuickAuth provider) async {
    if (_busy) return;
    setState(() {
      _busyProvider = provider;
      _error = null;
    });
    try {
      final service = await ref.read(authServiceProvider.future);
      if (!mounted) return;
      switch (provider) {
        case _QuickAuth.google:
          await service.signInWithGoogle();
        case _QuickAuth.apple:
          await service.signInWithApple();
      }
      if (!mounted) return;
      final destination = await destinationAfterSignIn(
        ref.read(initialProfileRepositoryProvider),
      );
      if (mounted) context.go(destination);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busyProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final showGoogle =
        defaultTargetPlatform == TargetPlatform.android && !kIsWeb;
    final showApple = defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb;
    final error = _error;

    return _OnboardingPage(
      title: s.startTitle,
      subtitle: s.startBody,
      children: [
        RwButton.primary(
          label: s.startNow,
          icon: Icons.arrow_forward_rounded,
          fullWidth: true,
          onPressed: _busy ? null : () => context.push('/auth/register'),
        ),
        const SizedBox(height: RwSpace.sm),
        RwButton.secondary(
          label: s.signIn,
          icon: Icons.login_rounded,
          fullWidth: true,
          onPressed: _busy ? null : () => context.push('/auth/sign-in'),
        ),
        if (showGoogle || showApple) ...[
          const SizedBox(height: RwSpace.md),
          Row(
            children: [
              const Expanded(
                child: Divider(color: RwColors.borderCard, thickness: 1),
              ),
              Flexible(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    s.authOtherOptions.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: RwColors.borderCard, thickness: 1),
              ),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: RwSpace.sm),
            Container(
              padding: const EdgeInsets.all(RwSpace.sm),
              decoration: BoxDecoration(
                color: RwColors.danger500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(RwRadius.md),
                border: Border.all(
                  color: RwColors.danger500.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: RwColors.danger500,
                    size: 18,
                  ),
                  const SizedBox(width: RwSpace.xs),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        authErrorMessage(s, error),
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          color: RwColors.danger500,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: RwSpace.md),
          if (showGoogle)
            RwButton.secondary(
              label: s.authGoogle,
              leading: const GoogleLogoIcon(),
              fullWidth: true,
              loading: _busyProvider == _QuickAuth.google,
              loadingLabel: s.authWorking,
              onPressed: _busy ? null : () => _signInQuick(_QuickAuth.google),
            ),
          if (showApple)
            RwButton.secondary(
              label: s.authApple,
              icon: Icons.apple_rounded,
              fullWidth: true,
              loading: _busyProvider == _QuickAuth.apple,
              loadingLabel: s.authWorking,
              onPressed: _busy ? null : () => _signInQuick(_QuickAuth.apple),
            ),
        ],
      ],
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: RwPage(
      children: [
        // Brand Header Capsule
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
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: RwSpace.md),

        // Visual Mountain Silhouette terbuka (Tier-A tanpa kotak kaku)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: RwSpace.sm),
          child: MountainSilhouette(),
        ),
        const SizedBox(height: RwSpace.md),

        Semantics(
          header: true,
          child: Text(
            title,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontFamily: RwType.family,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: RwColors.ink950,
            ),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: RwSpace.xs),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontFamily: RwType.family,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
        const SizedBox(height: RwSpace.xl),
        ...children,
      ],
    ),
  );
}
