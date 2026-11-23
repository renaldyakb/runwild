import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/decor/mountain_silhouette.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/intro_preferences.dart';

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  int _index = 0;
  bool _saving = false;
  bool _saveFailed = false;

  Future<void> _finish() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      await ref.read(introPreferencesProvider).complete();
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _saveFailed = true;
        });
      }
      return;
    }
    if (mounted) context.go('/start');
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final slides = [
      (s.introRunTitle, s.introRunBody),
      (s.introTrackTitle, s.introTrackBody),
      (s.introGrowTitle, s.introGrowBody),
    ];
    final (title, body) = slides[_index];
    final isLast = _index == slides.length - 1;

    return Scaffold(
      body: RwPage(
        children: [
          Text(
            s.introTagline,
            style: theme.textTheme.labelMedium?.copyWith(
              fontFamily: RwType.family,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
              color: RwColors.ink950,
            ),
          ),
          const SizedBox(height: RwSpace.md),
          // TODO(asset): gunakan ilustrasi berlisensi saat tersedia.
          const MountainSilhouette(),
          const SizedBox(height: RwSpace.md),
          Row(
            children: [
              for (var i = 0; i < slides.length; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                      right: i < slides.length - 1 ? 6 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: i <= _index
                          ? RwColors.ink950
                          : RwColors.borderCard,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: RwSpace.xs),
          Text(
            s.introProgress(_index + 1, slides.length),
            style: theme.textTheme.labelSmall?.copyWith(
              fontFamily: RwType.family,
              fontWeight: FontWeight.w700,
              color: RwColors.mutedTextOnLight,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: RwSpace.md),
          Semantics(
            header: true,
            liveRegion: true,
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
          const SizedBox(height: RwSpace.xs),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: RwType.family,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (_saveFailed) ...[
            const SizedBox(height: RwSpace.sm),
            Semantics(
              liveRegion: true,
              child: Text(
                s.introSaveError,
                style: TextStyle(
                  fontFamily: RwType.family,
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: RwSpace.lg),
          RwButton.primary(
            label: isLast ? s.introFinish : s.introNext,
            loading: _saving && isLast,
            fullWidth: true,
            icon: isLast
                ? Icons.check_circle_outline
                : Icons.arrow_forward_rounded,
            onPressed: _saving
                ? null
                : isLast
                ? _finish
                : () => setState(() => _index++),
          ),
          if (!isLast) ...[
            const SizedBox(height: RwSpace.sm),
            RwButton.secondary(
              label: s.introSkip,
              loading: _saving,
              fullWidth: true,
              onPressed: _saving ? null : _finish,
            ),
          ],
        ],
      ),
    );
  }
}
