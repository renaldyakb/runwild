import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../tokens/rw_tokens.dart';

class RwHoldToFinishButton extends StatefulWidget {
  const RwHoldToFinishButton({
    required this.label,
    required this.onHoldCompleted,
    this.onTapShort,
    this.holdDuration = const Duration(milliseconds: 1500),
    super.key,
  });

  final String label;
  final VoidCallback onHoldCompleted;
  final VoidCallback? onTapShort;
  final Duration holdDuration;

  @override
  State<RwHoldToFinishButton> createState() => _RwHoldToFinishButtonState();
}

class _RwHoldToFinishButtonState extends State<RwHoldToFinishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isHolding = false;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _didComplete = true;
        HapticFeedback.heavyImpact();
        widget.onHoldCompleted();
        _controller.reset();
        if (mounted) {
          setState(() => _isHolding = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    _didComplete = false;
    setState(() => _isHolding = true);
    HapticFeedback.selectionClick();
    _controller.forward(from: 0);
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (!_didComplete && _controller.isAnimating) {
      _controller.reverse();
    }
    if (mounted) {
      setState(() => _isHolding = false);
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    if (!_didComplete) {
      final wasShort = _controller.value < 0.25;
      _controller.reverse();
      if (mounted) {
        setState(() => _isHolding = false);
      }
      if (wasShort) {
        widget.onTapShort?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.label}. Tahan 1,5 detik untuk mengakhiri sesi',
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final progress = _controller.value;

            return ClipRRect(
              borderRadius: BorderRadius.circular(RwRadius.pill),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Latar Tombol
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF2EA),
                      borderRadius: BorderRadius.circular(RwRadius.pill),
                      border: Border.all(
                        color: _isHolding
                            ? RwColors.danger500
                            : const Color(0xFFE2E6DC),
                        width: 1.5,
                      ),
                    ),
                  ),

                  // Progres Bar Pengisian (Merah Atletis / Danger)
                  if (progress > 0)
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: RwColors.danger500.withValues(alpha: 0.18),
                            border: Border(
                              right: BorderSide(
                                color: RwColors.danger500,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Konten Teks & Icon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stop_rounded,
                          size: 18,
                          color: _isHolding
                              ? RwColors.danger500
                              : RwColors.ink950,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _isHolding
                                ? 'Tahan ${((1 - progress) * 1.5).toStringAsFixed(1)}s…'
                                : widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: RwType.family,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: _isHolding
                                  ? RwColors.danger500
                                  : RwColors.ink950,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
