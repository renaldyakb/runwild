import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_session.dart';
import 'auth_screen.dart';

class AccountActions extends ConsumerStatefulWidget {
  const AccountActions({this.showLinkOptions = true, super.key});

  final bool showLinkOptions;

  @override
  ConsumerState<AccountActions> createState() => _AccountActionsState();
}

class _AccountActionsState extends ConsumerState<AccountActions> {
  bool _busy = false;
  Object? _error;

  Future<void> _signOut() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = await ref.read(authServiceProvider.future);
      await service.signOut();
      if (mounted) context.go('/start');
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final session = ref.watch(authSessionProvider).value;
    if (session == null || session == AuthSession.signedOut) {
      return const SizedBox.shrink();
    }
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null)
          Container(
            margin: const EdgeInsets.symmetric(vertical: RwSpace.sm),
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
        RwButton.secondary(
          label: s.authSignOut,
          icon: Icons.logout_rounded,
          fullWidth: true,
          onPressed: _signOut,
          loading: _busy,
          loadingLabel: s.authWorking,
        ),
      ],
    );
  }
}
