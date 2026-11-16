import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_card.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/account_actions.dart';
import '../../foundation/application/home_stats_provider.dart';
import '../application/initial_profile.dart';
import '../application/profile_service.dart';
import '../domain/user_profile.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSaving = false;

  Future<void> _updateProfile(UserProfile updated) async {
    final user = ref.read(currentProfileUserProvider);
    if (user.uid == null) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(user.uid!, updated);
      ref.invalidate(userProfileProvider);
      ref.invalidate(weekSummaryProvider);
      if (mounted) {
        final s = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileUpdateSuccess),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final s = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileUpdateError),
            backgroundColor: RwColors.danger500,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showEditNameDialog(UserProfile profile) async {
    final controller = TextEditingController(text: profile.displayName);
    final s = AppLocalizations.of(context);

    final newName = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(RwRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: RwSpace.screen,
          right: RwSpace.screen,
          top: RwSpace.md,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + RwSpace.screen,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E6DC),
                  borderRadius: BorderRadius.circular(RwRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: RwSpace.md),
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: RwColors.lime100,
                    borderRadius: BorderRadius.circular(RwRadius.md),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: RwColors.ink950,
                    size: 22,
                  ),
                ),
                const SizedBox(width: RwSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.profileEditNameDialog,
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: RwColors.ink950,
                        ),
                      ),
                      const Text(
                        'Nama yang tampil pada sesi lari & kartu bagikan.',
                        style: TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 12,
                          color: RwColors.mutedTextOnLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: RwSpace.lg),
            TextField(
              controller: controller,
              autofocus: true,
              maxLength: ProfileLimits.nameLength,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: RwColors.ink950,
              ),
              decoration: InputDecoration(
                labelText: s.profileSetupName,
                labelStyle: const TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 14,
                  color: RwColors.mutedTextOnLight,
                ),
                floatingLabelStyle: const TextStyle(
                  fontFamily: RwType.family,
                  fontWeight: FontWeight.w700,
                  color: RwColors.ink950,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                filled: true,
                fillColor: RwColors.paper50,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  borderSide: const BorderSide(color: Color(0xFFE2E6DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RwRadius.md),
                  borderSide: const BorderSide(
                    color: RwColors.lime600,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: RwSpace.md),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: RwColors.lime500,
                foregroundColor: RwColors.ink950,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(RwRadius.pill),
                ),
              ),
              onPressed: () {
                final val = controller.text.trim();
                if (val.isNotEmpty) Navigator.pop(ctx, val);
              },
              child: const Text(
                'Simpan',
                style: TextStyle(
                  fontFamily: RwType.family,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
            const SizedBox(height: RwSpace.xs),
            RwButton.secondary(
              label: s.runCancel,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );

    if (newName != null && newName != profile.displayName) {
      await _updateProfile(profile.copyWith(displayName: newName));
    }
  }

  Future<void> _handleDeleteAccount() async {
    final s = AppLocalizations.of(context);
    final user = ref.read(currentProfileUserProvider);
    if (user.uid == null) return;

    // ── Dialog Konfirmasi Tahap 1 ───────────────────────────────────────
    final confirmFirst = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: RwColors.danger500),
            const SizedBox(width: 8),
            Expanded(child: Text(s.profileDeleteAccountConfirmTitle)),
          ],
        ),
        content: Text(s.profileDeleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.runCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: RwColors.danger500),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );

    if (confirmFirst != true || !mounted) return;

    // ── Dialog Konfirmasi Tahap 2 (Ketik HAPUS) ─────────────────────────
    final confirmSecond = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DoubleConfirmDeleteDialog(
        onConfirm: () => Navigator.pop(ctx, true),
        onCancel: () => Navigator.pop(ctx, false),
      ),
    );

    if (confirmSecond != true || !mounted) return;

    // ── Eksekusi Penghapusan ────────────────────────────────────────────
    setState(() => _isSaving = true);
    try {
      await ref.read(profileRepositoryProvider).deleteAccount(user.uid!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileDeleteAccountSuccess),
            backgroundColor: RwColors.ink950,
          ),
        );
        context.go('/start');
      }
    } on ProfileAuthRecentLoginRequiredException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileDeleteAccountRecentLogin),
            backgroundColor: RwColors.danger500,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.profileDeleteAccountError),
            backgroundColor: RwColors.danger500,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final user = ref.watch(currentProfileUserProvider);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.profileTitle,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const _ProfileSkeleton(),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(RwSpace.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: RwColors.danger500,
                  ),
                  const SizedBox(height: RwSpace.md),
                  Text('Gagal memuat profil: $err'),
                  const SizedBox(height: RwSpace.md),
                  RwButton.secondary(
                    label: 'Coba Lagi',
                    onPressed: () => ref.invalidate(userProfileProvider),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            // Profil fallback jika user belum mengisi Firestore atau mode tamu
            final currentProfile =
                profile ??
                UserProfile(
                  displayName: user.displayName ?? 'Pelari Tamu',
                  email: user.email ?? '',
                  level: ProfileLevel.pemula,
                  goal: ProfileGoal.sehat,
                );

            return Stack(
              children: [
                RwPage(
                  children: [
                    // ── Header Profil Atletis ───────────────────────
                    _ProfileHeaderCard(
                      profile: currentProfile,
                      onEditName: () => _showEditNameDialog(currentProfile),
                    ),
                    const SizedBox(height: RwSpace.lg),

                    // ── Bagian 1: Data Diri & Target Lari ───────────
                    _SectionHeader(title: s.profileSectionAccount),
                    const SizedBox(height: RwSpace.xs),
                    RwCard(
                      padding: const EdgeInsets.all(RwSpace.md),
                      child: Column(
                        children: [
                          // Level Pengalaman
                          _SettingTile(
                            icon: Icons.speed_rounded,
                            title: s.profileSetupLevel,
                            subtitle: switch (currentProfile.level) {
                              ProfileLevel.pemula => s.profileLevelBeginner,
                              ProfileLevel.kembali => s.profileLevelReturning,
                              ProfileLevel.rutin => s.profileLevelRegular,
                            },
                            trailing: PopupMenuButton<ProfileLevel>(
                              initialValue: currentProfile.level,
                              onSelected: (lvl) {
                                _updateProfile(
                                  currentProfile.copyWith(level: lvl),
                                );
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: ProfileLevel.pemula,
                                  child: Text(s.profileLevelBeginner),
                                ),
                                PopupMenuItem(
                                  value: ProfileLevel.kembali,
                                  child: Text(s.profileLevelReturning),
                                ),
                                PopupMenuItem(
                                  value: ProfileLevel.rutin,
                                  child: Text(s.profileLevelRegular),
                                ),
                              ],
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: RwColors.ink500,
                              ),
                            ),
                          ),
                          const Divider(height: 1),

                          // Target Utama Lari
                          _SettingTile(
                            icon: Icons.flag_outlined,
                            title: s.profileSetupGoal,
                            subtitle: switch (currentProfile.goal) {
                              ProfileGoal.sehat => s.profileGoalHealth,
                              ProfileGoal.lari5k => s.profileGoal5k,
                              ProfileGoal.lari10k => s.profileGoal10k,
                              ProfileGoal.turunBb => s.profileGoalWeight,
                              ProfileGoal.lainnya => s.profileGoalOther,
                            },
                            trailing: PopupMenuButton<ProfileGoal>(
                              initialValue: currentProfile.goal,
                              onSelected: (g) {
                                _updateProfile(
                                  currentProfile.copyWith(goal: g),
                                );
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: ProfileGoal.sehat,
                                  child: Text(s.profileGoalHealth),
                                ),
                                PopupMenuItem(
                                  value: ProfileGoal.lari5k,
                                  child: Text(s.profileGoal5k),
                                ),
                                PopupMenuItem(
                                  value: ProfileGoal.lari10k,
                                  child: Text(s.profileGoal10k),
                                ),
                                PopupMenuItem(
                                  value: ProfileGoal.turunBb,
                                  child: Text(s.profileGoalWeight),
                                ),
                                PopupMenuItem(
                                  value: ProfileGoal.lainnya,
                                  child: Text(s.profileGoalOther),
                                ),
                              ],
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: RwColors.ink500,
                              ),
                            ),
                          ),
                          const Divider(height: 1),

                          // Target Sesi Mingguan
                          _SettingTile(
                            icon: Icons.calendar_today_rounded,
                            title: s.profileSetupWeekly,
                            subtitle:
                                '${currentProfile.weeklyGoalSessions} sesi per minggu',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed:
                                      currentProfile.weeklyGoalSessions >
                                          ProfileLimits.minSessions
                                      ? () {
                                          _updateProfile(
                                            currentProfile.copyWith(
                                              weeklyGoalSessions:
                                                  currentProfile
                                                      .weeklyGoalSessions -
                                                  1,
                                            ),
                                          );
                                        }
                                      : null,
                                ),
                                Text(
                                  '${currentProfile.weeklyGoalSessions}',
                                  style: const TextStyle(
                                    fontFamily: RwType.family,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed:
                                      currentProfile.weeklyGoalSessions <
                                          ProfileLimits.maxSessions
                                      ? () {
                                          _updateProfile(
                                            currentProfile.copyWith(
                                              weeklyGoalSessions:
                                                  currentProfile
                                                      .weeklyGoalSessions +
                                                  1,
                                            ),
                                          );
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RwSpace.lg),

                    // ── Bagian 2: Preferensi Lari & Suara ────────────
                    _SectionHeader(title: s.profileSectionRunSettings),
                    const SizedBox(height: RwSpace.xs),
                    RwCard(
                      padding: const EdgeInsets.all(RwSpace.md),
                      child: Column(
                        children: [
                          // Satuan
                          _SettingTile(
                            icon: Icons.straighten_rounded,
                            title: s.profileUnitsLabel,
                            subtitle: s.profileUnitsKm,
                            trailing: const Text(
                              'KM',
                              style: TextStyle(
                                fontFamily: RwType.family,
                                fontWeight: FontWeight.w800,
                                color: RwColors.ink700,
                              ),
                            ),
                          ),
                          const Divider(height: 1),

                          // Jeda Otomatis (Auto-Pause)
                          _SwitchSettingTile(
                            icon: Icons.pause_circle_outline_rounded,
                            title: s.profileAutoPause,
                            subtitle: s.profileAutoPauseDesc,
                            value: currentProfile.autoPause,
                            onChanged: (val) {
                              _updateProfile(
                                currentProfile.copyWith(autoPause: val),
                              );
                            },
                          ),
                          const Divider(height: 1),

                          // Panduan Suara
                          _SwitchSettingTile(
                            icon: Icons.volume_up_outlined,
                            title: s.profileVoiceCues,
                            subtitle: s.profileVoiceCuesDesc,
                            value: currentProfile.voice.enabled,
                            onChanged: (val) {
                              _updateProfile(
                                currentProfile.copyWith(
                                  voice: currentProfile.voice.copyWith(
                                    enabled: val,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),

                          // Getaran Haptik
                          _SwitchSettingTile(
                            icon: Icons.vibration_rounded,
                            title: s.profileHaptics,
                            subtitle: s.profileHapticsDesc,
                            value: currentProfile.voice.haptics,
                            onChanged: (val) {
                              _updateProfile(
                                currentProfile.copyWith(
                                  voice: currentProfile.voice.copyWith(
                                    haptics: val,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),

                          // Hitung Mundur Suara
                          _SwitchSettingTile(
                            icon: Icons.timer_outlined,
                            title: s.profileCountdownCue,
                            subtitle: 'Suara hitung mundur 3-2-1',
                            value: currentProfile.voice.countdownCue,
                            onChanged: (val) {
                              _updateProfile(
                                currentProfile.copyWith(
                                  voice: currentProfile.voice.copyWith(
                                    countdownCue: val,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),

                          // Tanda Putaran Interval
                          _SwitchSettingTile(
                            icon: Icons.repeat_rounded,
                            title: s.profileRoundCue,
                            subtitle: 'Suara instruksi saat pergantian ronde',
                            value: currentProfile.voice.roundCue,
                            onChanged: (val) {
                              _updateProfile(
                                currentProfile.copyWith(
                                  voice: currentProfile.voice.copyWith(
                                    roundCue: val,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RwSpace.lg),

                    // ── Bagian 3: Privasi Sesi ───────────────────────
                    _SectionHeader(title: s.profileSectionPrivacy),
                    const SizedBox(height: RwSpace.xs),
                    RwCard(
                      padding: const EdgeInsets.all(RwSpace.md),
                      child: Column(
                        children: [
                          _SwitchSettingTile(
                            icon: Icons.visibility_off_outlined,
                            title: s.profilePrivacyHideStartEnd,
                            subtitle: s.profilePrivacyHideStartEndDesc,
                            value: currentProfile.privacy.hideStartEnd,
                            onChanged: (val) {
                              _updateProfile(
                                currentProfile.copyWith(
                                  privacy: currentProfile.privacy.copyWith(
                                    hideStartEnd: val,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                          _SettingTile(
                            icon: Icons.lock_outline_rounded,
                            title: s.profilePrivacyVisibility,
                            subtitle: s.profilePrivacyPrivate,
                            trailing: const Icon(
                              Icons.check_circle_rounded,
                              color: RwColors.lime600,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RwSpace.lg),

                    // ── Bagian 4: Akun & Keamanan ────────────────────
                    _SectionHeader(title: s.profileSectionSecurity),
                    const SizedBox(height: RwSpace.xs),
                    const AccountActions(),
                    const SizedBox(height: RwSpace.md),

                    // Tombol Hapus Akun (Danger Zone T4.7)
                    RwCard(
                      padding: const EdgeInsets.all(RwSpace.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.delete_forever_rounded,
                                color: RwColors.danger500,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s.profileDeleteAccount,
                                style: const TextStyle(
                                  fontFamily: RwType.family,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: RwColors.danger500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: RwSpace.xs),
                          Text(
                            s.profileDeleteAccountConfirmBody,
                            style: const TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 12,
                              color: RwColors.mutedTextOnLight,
                            ),
                          ),
                          const SizedBox(height: RwSpace.md),
                          RwButton.secondary(
                            label: s.profileDeleteAccount,
                            icon: Icons.delete_forever_outlined,
                            onPressed: _handleDeleteAccount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: RwSpace.xl),
                  ],
                ),
                if (_isSaving)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(color: RwColors.lime500),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Widget Sub-komponen Profil ──────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontFamily: RwType.family,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: RwColors.mutedTextOnLight,
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile, required this.onEditName});

  final UserProfile profile;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final initial = profile.displayName.isNotEmpty
        ? profile.displayName[0].toUpperCase()
        : 'R';

    return RwCard(
      padding: const EdgeInsets.all(RwSpace.lg),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: RwColors.ink950,
              shape: BoxShape.circle,
              border: Border.all(color: RwColors.lime500, width: 2),
              boxShadow: [
                BoxShadow(
                  color: RwColors.lime500.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontFamily: RwType.family,
                  color: RwColors.lime500,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: RwSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.displayName,
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: RwColors.ink950,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: RwColors.ink500,
                      ),
                      onPressed: onEditName,
                      tooltip: 'Ubah nama',
                    ),
                  ],
                ),
                if (profile.email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    profile.email,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF2EA),
                        borderRadius: BorderRadius.circular(RwRadius.pill),
                        border: Border.all(
                          color: const Color(0xFFE2E6DC),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        switch (profile.level) {
                          ProfileLevel.pemula => 'PELARI PEMULA',
                          ProfileLevel.kembali => 'MULAI LAGI',
                          ProfileLevel.rutin => 'PELARI RUTIN',
                        },
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: RwColors.ink800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: RwColors.lime100,
                        borderRadius: BorderRadius.circular(RwRadius.pill),
                        border: Border.all(
                          color: RwColors.lime500.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        switch (profile.goal) {
                          ProfileGoal.sehat => 'SEHAT',
                          ProfileGoal.lari5k => 'TARGET 5K',
                          ProfileGoal.lari10k => 'TARGET 10K',
                          ProfileGoal.turunBb => 'TURUN BB',
                          ProfileGoal.lainnya => 'BEBAS',
                        },
                        style: const TextStyle(
                          fontFamily: RwType.family,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: RwColors.ink950,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: RwColors.ink800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: RwColors.ink950,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 12,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  const _SwitchSettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 22, color: RwColors.ink800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: RwColors.ink950,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 12,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: RwColors.lime500,
            activeTrackColor: RwColors.ink950,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _DoubleConfirmDeleteDialog extends StatefulWidget {
  const _DoubleConfirmDeleteDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  State<_DoubleConfirmDeleteDialog> createState() =>
      _DoubleConfirmDeleteDialogState();
}

class _DoubleConfirmDeleteDialogState
    extends State<_DoubleConfirmDeleteDialog> {
  final _controller = TextEditingController();
  bool _canDelete = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(s.profileDeleteAccountDoubleTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.profileDeleteAccountDoubleHint),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'HAPUS',
              border: OutlineInputBorder(),
            ),
            onChanged: (val) {
              setState(() {
                _canDelete = val.trim().toUpperCase() == 'HAPUS';
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: Text(s.runCancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: RwColors.danger500),
          onPressed: _canDelete ? widget.onConfirm : null,
          child: Text(s.profileDeleteAccountButton),
        ),
      ],
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: RwColors.lime500),
    );
  }
}
