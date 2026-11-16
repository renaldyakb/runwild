import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/account_actions.dart';
import '../application/initial_profile.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  var _goal = ProfileGoal.sehat;
  var _level = ProfileLevel.pemula;
  var _sessions = ProfileLimits.initialSessions;
  var _saving = false;
  var _failed = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || _form.currentState?.validate() != true) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await ref
          .read(initialProfileRepositoryProvider)
          .save(
            name: _name.text.trim(),
            goal: _goal,
            level: _level,
            sessions: _sessions,
          );
      if (mounted) context.go('/');
    } on Exception {
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final profile = ref.watch(initialProfileExistsProvider);
    final exists = profile.asData?.value == true;
    final goals = [
      (ProfileGoal.sehat, s.profileGoalHealth),
      (ProfileGoal.lari5k, s.profileGoal5k),
      (ProfileGoal.lari10k, s.profileGoal10k),
      (ProfileGoal.turunBb, s.profileGoalWeight),
      (ProfileGoal.lainnya, s.profileGoalOther),
    ];
    final levels = [
      (ProfileLevel.pemula, s.profileLevelBeginner),
      (ProfileLevel.kembali, s.profileLevelReturning),
      (ProfileLevel.rutin, s.profileLevelRegular),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(s.profileSetupTitle)),
      body: RwPage(
        children: [
          if (exists) ...[
            Text(s.profileSetupAlreadySaved),
            const SizedBox(height: RwSpace.md),
            RwButton.primary(
              label: s.backHome,
              onPressed: () => context.go('/'),
            ),
          ] else if (profile.isLoading) ...[
            Semantics(liveRegion: true, child: Text(s.profileSetupLoading)),
            const SizedBox(height: RwSpace.md),
            ExcludeSemantics(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.outlineVariant,
                child: const SizedBox(height: RwSpace.xs),
              ),
            ),
          ] else if (profile.hasError) ...[
            Semantics(liveRegion: true, child: Text(s.profileSetupReadError)),
            const SizedBox(height: RwSpace.md),
            RwButton.primary(
              label: s.retry,
              onPressed: () => ref.invalidate(initialProfileExistsProvider),
            ),
            const SizedBox(height: RwSpace.md),
            const AccountActions(showLinkOptions: false),
          ] else ...[
            Form(
              key: _form,
              child: TextFormField(
                controller: _name,
                enabled: !_saving,
                maxLength: ProfileLimits.nameLength,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: s.profileSetupName),
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? s.profileSetupNameRequired
                    : null,
              ),
            ),
            RwSectionTitle(s.profileSetupGoal),
            IgnorePointer(
              ignoring: _saving,
              child: Wrap(
                spacing: RwSpace.xs,
                runSpacing: RwSpace.xs,
                children: [
                  for (final (value, label) in goals)
                    RwChip(
                      label: label,
                      selected: _goal == value,
                      onSelected: (_) {
                        if (!_saving) setState(() => _goal = value);
                      },
                    ),
                ],
              ),
            ),
            RwSectionTitle(s.profileSetupLevel),
            Wrap(
              spacing: RwSpace.xs,
              runSpacing: RwSpace.xs,
              children: [
                for (final (value, label) in levels)
                  RwChip(
                    label: label,
                    selected: _level == value,
                    onSelected: (_) {
                      if (!_saving) setState(() => _level = value);
                    },
                  ),
              ],
            ),
            RwSectionTitle(s.profileSetupWeekly),
            Row(
              children: [
                IconButton(
                  tooltip: s.profileSetupFewer,
                  onPressed: _saving || _sessions <= ProfileLimits.minSessions
                      ? null
                      : () => setState(() => _sessions--),
                  icon: const Icon(Icons.remove),
                ),
                Semantics(liveRegion: true, child: Text('$_sessions')),
                IconButton(
                  tooltip: s.profileSetupMore,
                  onPressed: _saving || _sessions >= ProfileLimits.maxSessions
                      ? null
                      : () => setState(() => _sessions++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: RwSpace.lg),
            if (_failed) ...[
              Semantics(liveRegion: true, child: Text(s.profileSetupSaveError)),
              const SizedBox(height: RwSpace.md),
            ],
            RwButton.primary(
              label: s.profileSetupSave,
              onPressed: _save,
              loading: _saving,
              loadingLabel: s.authWorking,
            ),
            const SizedBox(height: RwSpace.md),
            if (!_saving) const AccountActions(showLinkOptions: false),
          ],
        ],
      ),
    );
  }
}
