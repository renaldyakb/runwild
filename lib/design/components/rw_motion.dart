import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

/// Animasi masuk halus (fade + slide ringan) untuk kartu dan bagian layar.
/// Otomatis menampilkan konten secara instan saat "Kurangi gerakan" aktif.
class RwEntrance extends StatefulWidget {
  const RwEntrance({
    required this.child,
    this.order = 0,
    this.offsetY = 14,
    super.key,
  });

  final Widget child;
  final int order;
  final double offsetY;

  @override
  State<RwEntrance> createState() => _RwEntranceState();
}

class _RwEntranceState extends State<RwEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: RwMotion.page);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _opacity = curved;
    _slide = Tween<Offset>(
      begin: Offset(0, widget.offsetY),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    final delayMs = (widget.order * 55).clamp(0, 220);
    if (delayMs == 0) {
      unawaited(_controller.forward());
    } else {
      _delayTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted) unawaited(_controller.forward());
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(offset: _slide.value, child: child),
      ),
    );
  }
}

/// Animasi hitung angka halus untuk metrik utama (jarak di Ringkasan & Progress).
class RwCountUp extends StatelessWidget {
  const RwCountUp({
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 420),
    super.key,
  });

  final double value;
  final Widget Function(BuildContext context, double animatedValue) builder;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return builder(context, value);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, current, _) => builder(context, current),
    );
  }
}

/// Efek tekan mikro (scale 0.975) pada kartu interaktif untuk umpan balik sentuh.
class RwPressScale extends StatefulWidget {
  const RwPressScale({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<RwPressScale> createState() => _RwPressScaleState();
}

class _RwPressScaleState extends State<RwPressScale> {
  bool _pressed = false;

  void _setPressed(bool next) {
    if (!widget.enabled || _pressed == next) return;
    setState(() => _pressed = next);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: RwMotion.micro,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Transisi skala & pudar cepat untuk momen bernyawa: countdown 3-2-1 dan
/// pergantian fase interval (LARI <-> JALAN).
class RwPhaseSwitcher extends StatelessWidget {
  const RwPhaseSwitcher({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduced ? Duration.zero : RwMotion.transition,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        if (reduced) return child;
        final scale = Tween<double>(begin: 0.94, end: 1.0).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: child,
    );
  }
}
