import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_loading.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/decor/mountain_silhouette.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/application/auth_session.dart';
import '../../profile/application/initial_profile.dart';
import '../../run/application/run_journal.dart';
import '../application/intro_preferences.dart';

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
    final bool complete;
    try {
      complete = await ref.read(introPreferencesProvider).isComplete();
    } on Exception {
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) return;
    if (!complete) {
      context.go('/intro');
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
    if (!mounted) return;
    final owner = ref.read(runOwnerProvider)();
    context.go(
      destination == '/' && owner != null ? '/run/recover' : destination,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      final s = AppLocalizations.of(context);
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

    // Tampilan loading bersih 1 layar penuh tanpa teks saat membuka aplikasi
    return const Scaffold(body: RwFullPageLoading());
  }
}

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _OnboardingPage(
      title: s.startTitle,
      subtitle: s.startBody,
      children: [
        RwButton.primary(
          label: s.startNow,
          icon: Icons.arrow_forward_rounded,
          fullWidth: true,
          onPressed: () => context.push('/auth/register'),
        ),
        const SizedBox(height: RwSpace.sm),
        RwButton.secondary(
          label: s.signIn,
          icon: Icons.login_rounded,
          fullWidth: true,
          onPressed: () => context.push('/auth/sign-in'),
        ),
        const SizedBox(height: RwSpace.md),

        // Quick Auth Options Divider
        Row(
          children: [
            const Expanded(
              child: Divider(color: Color(0xFFE2E6DC), thickness: 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'OPSI LAIN',
                style: TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                  color: RwColors.mutedTextOnLight.withValues(alpha: 0.8),
                ),
              ),
            ),
            const Expanded(
              child: Divider(color: Color(0xFFE2E6DC), thickness: 1),
            ),
          ],
        ),
        const SizedBox(height: RwSpace.md),

        RwButton.secondary(
          label: s.authGuest,
          icon: Icons.person_outline_rounded,
          fullWidth: true,
          onPressed: () => context.push('/auth/guest'),
        ),
        if (defaultTargetPlatform == TargetPlatform.android && !kIsWeb) ...[
          const SizedBox(height: RwSpace.sm),
          RwButton.secondary(
            label: s.authGoogle,
            icon: Icons.g_mobiledata_rounded,
            fullWidth: true,
            onPressed: () => context.push('/auth/google'),
          ),
        ],
        if (defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb) ...[
          const SizedBox(height: RwSpace.sm),
          RwButton.secondary(
            label: s.authApple,
            icon: Icons.apple_rounded,
            fullWidth: true,
            onPressed: () => context.push('/auth/apple'),
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

        // Visual Mountain Silhouette Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(RwRadius.lg),
            border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
          ),
          child: const MountainSilhouette(),
        ),
        const SizedBox(height: RwSpace.lg),

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
