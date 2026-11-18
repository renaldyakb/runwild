import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/constants/interval_limits.dart';
import '../../../design/components/rw_button.dart';
import '../../../design/components/rw_chip.dart';
import '../../../design/components/rw_page.dart';
import '../../../design/tokens/rw_tokens.dart';
import '../../../domain/interval/interval_config.dart';
import '../../../domain/interval/interval_engine.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/interval_presets.dart';
import '../application/interval_selection.dart';
import '../application/run_journal.dart';

String _summary(AppLocalizations s, IntervalConfig config) {
  final rounds = config.rounds;
  if (rounds == null) {
    return s.intervalSummaryFree(config.run.inSeconds, config.walk.inSeconds);
  }
  final duration = IntervalEngine(
    config: config,
    clock: () => Duration.zero,
  ).trainingDuration!;
  return s.intervalSummary(
    duration.inMinutes,
    duration.inSeconds % Duration.secondsPerMinute,
    rounds,
    config.run.inSeconds,
  );
}

class IntervalOptions extends ConsumerWidget {
  const IntervalOptions({required this.enabled, super.key});
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final config = ref.watch(intervalSelectionProvider);
    final selection = ref.read(intervalSelectionProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.intervalMode,
          style: const TextStyle(
            fontFamily: RwType.family,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: RwSpace.xs),
        RwSegmentedControl<bool>(
          items: [
            RwSegmentItem(
              value: false,
              label: s.intervalFree,
              icon: Icons.directions_run_rounded,
            ),
            RwSegmentItem(
              value: true,
              label: s.intervalMode,
              icon: Icons.timer_outlined,
            ),
          ],
          selectedValue: config != null,
          onChanged: (isInterval) {
            if (!enabled) return;
            if (isInterval) {
              selection.select(intervalPreset(IntervalPreset.beginner));
            } else {
              selection.select(null);
            }
          },
        ),
        if (config != null) ...[
          const SizedBox(height: RwSpace.sm),
          Container(
            padding: const EdgeInsets.all(RwSpace.sm),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(RwRadius.md),
              border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _summary(s, config),
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: RwColors.ink950,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  s.intervalNoAudio,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 12,
                    color: RwColors.mutedTextOnLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RwSpace.sm),
          RwButton.secondary(
            label: s.intervalConfigure,
            icon: Icons.tune_rounded,
            onPressed: !enabled
                ? null
                : () async {
                    final result = await showModalBottomSheet<IntervalConfig>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => IntervalEditor(initial: config),
                    );
                    if (result != null && context.mounted) {
                      selection.select(result);
                    }
                  },
          ),
        ],
      ],
    );
  }
}

class IntervalEditor extends ConsumerStatefulWidget {
  const IntervalEditor({required this.initial, super.key});
  final IntervalConfig initial;

  @override
  ConsumerState<IntervalEditor> createState() => _IntervalEditorState();
}

class _IntervalEditorState extends ConsumerState<IntervalEditor> {
  final _form = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  late bool _walkFirst;
  late bool _freeRounds;
  final _name = TextEditingController();
  int? _savedId;
  bool _busy = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    final config = widget.initial;
    _freeRounds = config.rounds == null;
    _fields = [
      for (final number in [
        config.warmup.inSeconds,
        config.run.inSeconds,
        config.walk.inSeconds,
        config.rounds ?? IntervalLimits.minimumRounds,
        config.cooldown.inSeconds,
      ])
        TextEditingController(text: '$number'),
    ];
    _walkFirst = config.startWithWalk;
  }

  @override
  void dispose() {
    _name.dispose();
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await action();
      if (mounted) {
        _savedId = null;
        _name.clear();
      }
    } on Exception {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = _savedId;
    if (_busy || id == null) return;
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(s.intervalDeletePrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.runCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: RwColors.danger500),
            child: Text(s.intervalDelete),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _mutate(() => ref.read(savedIntervalsProvider.notifier).delete(id));
  }

  IntervalConfig? get _config {
    final warmup = int.tryParse(_fields[0].text);
    final run = int.tryParse(_fields[1].text);
    final walk = int.tryParse(_fields[2].text);
    final cooldown = int.tryParse(_fields[4].text);
    if (warmup == null || run == null || walk == null || cooldown == null) {
      return null;
    }
    final rounds = _freeRounds ? null : int.tryParse(_fields[3].text);
    if (!_freeRounds && rounds == null) return null;
    final config = (
      warmup: Duration(seconds: warmup),
      run: Duration(seconds: run),
      walk: Duration(seconds: walk),
      rounds: rounds,
      startWithWalk: _walkFirst,
      cooldown: Duration(seconds: cooldown),
    );
    try {
      IntervalEngine(config: config, clock: () => Duration.zero);
      return config;
    } on ArgumentError {
      return null;
    }
  }

  void _preset(IntervalPreset preset) {
    final config = intervalPreset(preset);
    _savedId = null;
    _name.clear();
    _load(config);
  }

  void _load(IntervalConfig config) {
    setState(() {
      _fields[0].text = '${config.warmup.inSeconds}';
      _fields[1].text = '${config.run.inSeconds}';
      _fields[2].text = '${config.walk.inSeconds}';
      _fields[3].text = '${config.rounds ?? IntervalLimits.minimumRounds}';
      _fields[4].text = '${config.cooldown.inSeconds}';
      _walkFirst = config.startWithWalk;
      _freeRounds = config.rounds == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final config = _config;
    final saved = ref.watch(savedIntervalsProvider);
    final hasAccount = ref.read(runOwnerProvider)() != null;

    final presetLabels = [
      s.intervalBeginner,
      s.intervalClassic,
      s.intervalFiveOne,
      s.intervalLevelUp,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: RwPage(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.intervalConfigure,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: RwSpace.sm),

          // Pilihan Preset Cepat (Grid Simetris 2 Baris)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF2EA),
              borderRadius: BorderRadius.circular(RwRadius.md),
              border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
            ),
            child: Row(
              children: [
                for (var i = 0; i < IntervalPreset.values.length; i++)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _preset(IntervalPreset.values[i]),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              config == intervalPreset(IntervalPreset.values[i])
                              ? RwColors.lime500
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(RwRadius.sm),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            presetLabels[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: RwType.family,
                              fontSize: 12,
                              fontWeight:
                                  config ==
                                      intervalPreset(IntervalPreset.values[i])
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color:
                                  config ==
                                      intervalPreset(IntervalPreset.values[i])
                                  ? RwColors.ink950
                                  : RwColors.mutedTextOnLight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: RwSpace.md),

          Form(
            key: _form,
            child: Column(
              children: [
                _SportIntervalField(
                  title: s.intervalRun,
                  labelText: s.intervalRunSeconds,
                  icon: Icons.directions_run_rounded,
                  controller: _fields[1],
                  min: IntervalLimits.minimumLeg.inSeconds,
                  max: IntervalLimits.maximumLeg.inSeconds,
                  step: 15,
                  quickValues: const [30, 60, 90, 120, 180],
                  isRound: false,
                  onChanged: () => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null ||
                            n < IntervalLimits.minimumLeg.inSeconds ||
                            n > IntervalLimits.maximumLeg.inSeconds
                        ? s.intervalRange(
                            IntervalLimits.minimumLeg.inSeconds,
                            IntervalLimits.maximumLeg.inSeconds,
                          )
                        : null;
                  },
                ),
                _SportIntervalField(
                  title: s.intervalWalk,
                  labelText: s.intervalWalkSeconds,
                  icon: Icons.directions_walk_rounded,
                  controller: _fields[2],
                  min: IntervalLimits.minimumLeg.inSeconds,
                  max: IntervalLimits.maximumLeg.inSeconds,
                  step: 15,
                  quickValues: const [30, 60, 90, 120, 180],
                  isRound: false,
                  onChanged: () => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null ||
                            n < IntervalLimits.minimumLeg.inSeconds ||
                            n > IntervalLimits.maximumLeg.inSeconds
                        ? s.intervalRange(
                            IntervalLimits.minimumLeg.inSeconds,
                            IntervalLimits.maximumLeg.inSeconds,
                          )
                        : null;
                  },
                ),
                _RoundsField(
                  controller: _fields[3],
                  isFree: _freeRounds,
                  onFreeChanged: (free) => setState(() => _freeRounds = free),
                  onChanged: () => setState(() {}),
                  validator: (v) {
                    if (_freeRounds) return null;
                    final n = int.tryParse(v ?? '');
                    return n == null ||
                            n < IntervalLimits.minimumRounds ||
                            n > IntervalLimits.maximumRounds
                        ? s.intervalRange(
                            IntervalLimits.minimumRounds,
                            IntervalLimits.maximumRounds,
                          )
                        : null;
                  },
                ),
                // Pemanasan & Pendinginan Ramping
                _SportIntervalField(
                  title: s.intervalWarmup,
                  labelText: s.intervalWarmupSeconds,
                  icon: Icons.fitness_center_rounded,
                  controller: _fields[0],
                  min: 0,
                  max: IntervalLimits.maximumPreparation.inSeconds,
                  step: 30,
                  quickValues: const [0, 120, 300],
                  isRound: false,
                  onChanged: () => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null ||
                            n < 0 ||
                            n > IntervalLimits.maximumPreparation.inSeconds
                        ? s.intervalRange(
                            0,
                            IntervalLimits.maximumPreparation.inSeconds,
                          )
                        : null;
                  },
                ),
                _SportIntervalField(
                  title: s.intervalCooldown,
                  labelText: s.intervalCooldownSeconds,
                  icon: Icons.self_improvement_rounded,
                  controller: _fields[4],
                  min: 0,
                  max: IntervalLimits.maximumPreparation.inSeconds,
                  step: 30,
                  quickValues: const [0, 120, 300],
                  isRound: false,
                  onChanged: () => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null ||
                            n < 0 ||
                            n > IntervalLimits.maximumPreparation.inSeconds
                        ? s.intervalRange(
                            0,
                            IntervalLimits.maximumPreparation.inSeconds,
                          )
                        : null;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    s.intervalStartWalk,
                    style: const TextStyle(
                      fontFamily: RwType.family,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  value: _walkFirst,
                  onChanged: (val) => setState(() => _walkFirst = val),
                ),
              ],
            ),
          ),

          // Total Durasi Sesi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(RwRadius.md),
              border: Border.all(
                color: config == null
                    ? RwColors.danger500
                    : const Color(0xFFE2E6DC),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  config == null
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  color: config == null ? RwColors.danger500 : RwColors.lime700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    config == null ? s.intervalInvalid : _summary(s, config),
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: config == null
                          ? RwColors.danger500
                          : RwColors.ink950,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: RwSpace.md),

          RwButton.primary(
            label: s.intervalApply,
            onPressed: config == null || _busy
                ? null
                : () {
                    if (_form.currentState?.validate() == true) {
                      Navigator.pop(context, config);
                    }
                  },
          ),
          const SizedBox(height: RwSpace.sm),

          // Preset Tersimpan (opsional jika login)
          if (hasAccount) ...[
            Text(
              s.intervalSaved,
              style: const TextStyle(
                fontFamily: RwType.family,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: RwSpace.xs),
            if (saved.isLoading) Text(s.intervalLoading),
            if (saved.hasError || _failed) Text(s.intervalSaveError),
            if (saved.hasError)
              RwButton.secondary(
                label: s.retry,
                onPressed: () => ref.invalidate(savedIntervalsProvider),
              ),
            if (saved.asData?.value.isEmpty ?? false)
              Text(
                s.intervalSavedEmpty,
                style: const TextStyle(
                  fontSize: 12,
                  color: RwColors.mutedTextOnLight,
                ),
              ),
            Wrap(
              spacing: RwSpace.xs,
              runSpacing: RwSpace.xs,
              children: [
                for (final preset in saved.asData?.value ?? <SavedInterval>[])
                  RwChip(
                    label: preset.name,
                    selected: _savedId == preset.id,
                    onSelected: _busy
                        ? null
                        : (_) {
                            _savedId = preset.id;
                            _name.text = preset.name;
                            _load(preset.config);
                          },
                  ),
              ],
            ),
            const SizedBox(height: RwSpace.xs),
            TextField(
              controller: _name,
              enabled: !_busy,
              maxLength: IntervalLimits.presetNameLength,
              decoration: InputDecoration(
                labelText: s.intervalName,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            RwButton.secondary(
              label: _savedId == null ? s.intervalSave : s.intervalUpdate,
              loading: _busy,
              onPressed: config == null || _name.text.trim().isEmpty || _busy
                  ? null
                  : () => _mutate(
                      () => ref
                          .read(savedIntervalsProvider.notifier)
                          .save(_name.text, config, id: _savedId),
                    ),
            ),
            if (_savedId != null) ...[
              const SizedBox(height: 6),
              RwButton.secondary(
                label: s.intervalDelete,
                onPressed: _busy ? null : _delete,
              ),
            ],
            const SizedBox(height: RwSpace.sm),
          ],
          RwButton.secondary(
            label: s.runCancel,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Komponen field waktu (stepper + quick chips) - Ramping & Segar
// ─────────────────────────────────────────────────────────────────────────────

class _SportIntervalField extends StatelessWidget {
  const _SportIntervalField({
    required this.title,
    required this.labelText,
    required this.icon,
    required this.controller,
    required this.min,
    required this.max,
    required this.step,
    required this.quickValues,
    required this.isRound,
    required this.onChanged,
    required this.validator,
  });

  final String title;
  final String labelText;
  final IconData icon;
  final TextEditingController controller;
  final int min;
  final int max;
  final int step;
  final List<int> quickValues;
  final bool isRound;
  final VoidCallback onChanged;
  final String? Function(String?) validator;

  void _step(int delta) {
    final current = int.tryParse(controller.text) ?? min;
    final next = (current + delta).clamp(min, max);
    controller.text = '$next';
    onChanged();
  }

  void _setExact(int value) {
    controller.text = '$value';
    onChanged();
  }

  String _formatValue(int val) {
    if (isRound) return '$val';
    final m = val ~/ 60;
    final s = val % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _formatChip(int val) {
    if (isRound) return '$val×';
    final m = val ~/ 60;
    final s = val % 60;
    if (m == 0) return '${s}d';
    if (s == 0) return '${m}m';
    return '${m}m ${s}d';
  }

  @override
  Widget build(BuildContext context) {
    final current = int.tryParse(controller.text);

    return Container(
      margin: const EdgeInsets.only(bottom: RwSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RwRadius.md),
        border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Field hanya untuk validasi Form; isinya tidak boleh terlihat. Tanpa clip,
          // label dan nilai TextFormField bocor sebagai angka mengambang di kartu.
          ExcludeSemantics(
            child: ClipRect(
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextFormField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: labelText,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: validator,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: RwColors.lime100,
                  borderRadius: BorderRadius.circular(RwRadius.sm),
                ),
                child: Icon(icon, size: 16, color: RwColors.lime700),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              // Nilai waktu
              Text(
                current == null ? '—' : _formatValue(current),
                style: const TextStyle(
                  fontFamily: RwType.family,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: RwColors.ink950,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Stepper minus
              IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF2EA),
                  foregroundColor: RwColors.ink950,
                  shape: const CircleBorder(),
                ),
                onPressed: current != null && current > min
                    ? () => _step(-step)
                    : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              const SizedBox(width: 6),
              // Quick values simetris
              Expanded(
                child: Row(
                  children: [
                    for (final val in quickValues)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: GestureDetector(
                            onTap: () => _setExact(val),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              decoration: BoxDecoration(
                                color: current == val
                                    ? RwColors.lime500
                                    : const Color(0xFFEFF2EA),
                                borderRadius: BorderRadius.circular(
                                  RwRadius.pill,
                                ),
                                border: Border.all(
                                  color: current == val
                                      ? RwColors.lime600
                                      : const Color(0xFFE2E6DC),
                                  width: 1,
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  _formatChip(val),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: RwType.family,
                                    fontSize: 10.5,
                                    fontWeight: current == val
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: RwColors.ink950,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Stepper plus
              IconButton(
                iconSize: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: RwColors.lime500,
                  foregroundColor: RwColors.ink950,
                  shape: const CircleBorder(),
                ),
                onPressed: current != null && current < max
                    ? () => _step(step)
                    : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Komponen field putaran dengan toggle Bebas/Terbatas
// ─────────────────────────────────────────────────────────────────────────────

class _RoundsField extends StatelessWidget {
  const _RoundsField({
    required this.controller,
    required this.isFree,
    required this.onFreeChanged,
    required this.onChanged,
    required this.validator,
  });

  final TextEditingController controller;
  final bool isFree;
  final ValueChanged<bool> onFreeChanged;
  final VoidCallback onChanged;
  final String? Function(String?) validator;

  void _step(int delta) {
    final current =
        int.tryParse(controller.text) ?? IntervalLimits.minimumRounds;
    final next = (current + delta).clamp(
      IntervalLimits.minimumRounds,
      IntervalLimits.maximumRounds,
    );
    controller.text = '$next';
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final current = int.tryParse(controller.text);

    return Container(
      margin: const EdgeInsets.only(bottom: RwSpace.sm),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RwRadius.md),
        border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Field hanya untuk validasi Form; isinya tidak boleh terlihat. Tanpa clip,
          // label dan nilai TextFormField bocor sebagai angka mengambang di kartu.
          ExcludeSemantics(
            child: ClipRect(
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextFormField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                    labelText: s.intervalRounds,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: validator,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: RwColors.lime100,
                  borderRadius: BorderRadius.circular(RwRadius.sm),
                ),
                child: const Icon(
                  Icons.repeat_rounded,
                  size: 16,
                  color: RwColors.lime700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.intervalRounds,
                  style: const TextStyle(
                    fontFamily: RwType.family,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              _RoundsToggle(
                isFree: isFree,
                onFreeChanged: onFreeChanged,
                freeLabel: s.intervalFreeRounds,
                limitedLabel: s.intervalLimitedRounds,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isFree) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '∞ ',
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: RwColors.lime700,
                    ),
                  ),
                  Text(
                    'Putaran Bebas (berhenti saat Anda mau)',
                    style: TextStyle(
                      fontFamily: RwType.family,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RwColors.mutedTextOnLight,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF2EA),
                    foregroundColor: RwColors.ink950,
                    shape: const CircleBorder(),
                  ),
                  onPressed:
                      current != null && current > IntervalLimits.minimumRounds
                      ? () => _step(-1)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      for (final val in const [4, 6, 8, 10, 12])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: GestureDetector(
                              onTap: () {
                                controller.text = '$val';
                                onChanged();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: current == val
                                      ? RwColors.lime500
                                      : const Color(0xFFEFF2EA),
                                  borderRadius: BorderRadius.circular(
                                    RwRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: current == val
                                        ? RwColors.lime600
                                        : const Color(0xFFE2E6DC),
                                    width: 1,
                                  ),
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '$val×',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: RwType.family,
                                      fontSize: 11,
                                      fontWeight: current == val
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: RwColors.ink950,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: RwColors.lime500,
                    foregroundColor: RwColors.ink950,
                    shape: const CircleBorder(),
                  ),
                  onPressed:
                      current != null && current < IntervalLimits.maximumRounds
                      ? () => _step(1)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle pill BEBAS ↔ TERBATAS
// ─────────────────────────────────────────────────────────────────────────────

class _RoundsToggle extends StatelessWidget {
  const _RoundsToggle({
    required this.isFree,
    required this.onFreeChanged,
    required this.freeLabel,
    required this.limitedLabel,
  });

  final bool isFree;
  final ValueChanged<bool> onFreeChanged;
  final String freeLabel;
  final String limitedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2EA),
        borderRadius: BorderRadius.circular(RwRadius.pill),
        border: Border.all(color: const Color(0xFFE2E6DC), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: freeLabel,
            selected: isFree,
            onTap: () => onFreeChanged(true),
          ),
          _ToggleOption(
            label: limitedLabel,
            selected: !isFree,
            onTap: () => onFreeChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? RwColors.lime500 : Colors.transparent,
          borderRadius: BorderRadius.circular(RwRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: RwType.family,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: RwColors.ink950,
          ),
        ),
      ),
    );
  }
}
