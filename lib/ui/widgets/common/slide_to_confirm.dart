// lib/ui/widgets/common/slide_to_confirm.dart

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../constants/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../tools/app_text_style.dart';

/// A track the person drags across to confirm an action that shouldn't
/// happen by accident, such as checking in.
///
/// [onConfirmed] runs once per completed drag. While it runs the knob shows
/// a spinner and the slider ignores input; when it returns true the knob
/// shows a tick, otherwise it springs back. A drag released before 90 %
/// springs back without firing. When [isLocked], dragging or tapping shakes
/// the track and calls [onLockedTap] instead.
///
/// With accessible navigation on (screen readers, switch access), it
/// renders as a plain button.
class SlideToConfirm extends StatefulWidget {
  /// Creates the slider.
  const SlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.isLocked = false,
    this.lockedLabel,
    this.onLockedTap,
  });

  /// Text on the track, for example "Slide to check in".
  final String label;

  /// The action. Returns whether it succeeded.
  final Future<bool> Function() onConfirmed;

  /// Whether the action is unavailable right now.
  final bool isLocked;

  /// Text shown instead of [label] while locked.
  final String? lockedLabel;

  /// Called when the person tries the slider while it is locked.
  final VoidCallback? onLockedTap;

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

enum _Phase { idle, submitting, done }

class _SlideToConfirmState extends State<SlideToConfirm>
    with TickerProviderStateMixin {
  static const double _height = 56;
  static const double _padding = 4;
  static const double _knob = _height - _padding * 2;
  static const double _commitAt = 0.9;
  static const Duration _doneHold = Duration(milliseconds: 700);

  late final AnimationController _position = AnimationController(vsync: this);
  late final AnimationController _shake = AnimationController(vsync: this);
  late final Animation<double> _shakeOffset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
  ]).animate(_shake);

  _Phase _phase = _Phase.idle;
  bool _isPastHint = false;
  double _travel = 1;

  bool get _isBusy => _phase != _Phase.idle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shake.duration = AppMotion.of(context).slow;
  }

  @override
  void dispose() {
    _position.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onLocked() {
    HapticFeedback.lightImpact();
    if (_shake.duration != Duration.zero) _shake.forward(from: 0);
    widget.onLockedTap?.call();
  }

  void _onDragStart(DragStartDetails details) {
    if (widget.isLocked && !_isBusy) _onLocked();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.isLocked || _isBusy) return;
    _position.value += details.delta.dx / _travel;
    final isPastHint = _position.value >= _commitAt;
    if (isPastHint && !_isPastHint) HapticFeedback.selectionClick();
    _isPastHint = isPastHint;
  }

  void _onDragEnd(DragEndDetails details) {
    if (widget.isLocked || _isBusy) return;
    _isPastHint = false;
    if (_position.value >= _commitAt) {
      _confirm();
    } else {
      _springBack(details.velocity.pixelsPerSecond.dx / _travel);
    }
  }

  void _springBack([double velocity = 0]) {
    if (AppMotion.of(context).slow == Duration.zero) {
      _position.value = 0;
      return;
    }
    // Critically damped: glides home without overshooting into the
    // track's start and stopping dead.
    _position.animateWith(
      SpringSimulation(
        SpringDescription.withDampingRatio(mass: 1, stiffness: 380),
        _position.value,
        0,
        velocity,
      ),
    );
  }

  Future<void> _confirm() async {
    if (_isBusy) return;
    setState(() => _phase = _Phase.submitting);
    HapticFeedback.mediumImpact();
    final motion = AppMotion.of(context);
    await _position.animateTo(
      1,
      duration: motion.fast,
      curve: AppMotion.standard,
    );
    final isConfirmed = await widget.onConfirmed();
    if (!mounted) return;
    if (!isConfirmed) {
      setState(() => _phase = _Phase.idle);
      _springBack();
      return;
    }
    setState(() => _phase = _Phase.done);
    await Future<void>.delayed(_doneHold);
    if (!mounted) return;
    setState(() => _phase = _Phase.idle);
    // Glide back while the (possibly new) label fades in.
    await _position.animateTo(
      0,
      duration: AppMotion.of(context).slow,
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final label =
        widget.isLocked ? widget.lockedLabel ?? widget.label : widget.label;
    if (MediaQuery.accessibleNavigationOf(context)) {
      return _AccessibleButton(
        label: label,
        isBusy: _isBusy,
        onPressed: widget.isLocked ? _onLocked : _confirm,
      );
    }
    return Semantics(
      button: true,
      enabled: !widget.isLocked,
      label: label,
      onTap: widget.isLocked ? _onLocked : _confirm,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _shakeOffset,
        builder: (context, child) => Transform.translate(
          offset: Offset(_shakeOffset.value, 0),
          child: child,
        ),
        child: GestureDetector(
          onTap: widget.isLocked ? _onLocked : null,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: LayoutBuilder(
            builder: (context, constraints) {
              _travel = constraints.maxWidth - _knob - _padding * 2;
              return _Track(
                position: _position,
                travel: _travel,
                label: label,
                isLocked: widget.isLocked,
                phase: _phase,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({
    required this.position,
    required this.travel,
    required this.label,
    required this.isLocked,
    required this.phase,
  });

  final Animation<double> position;
  final double travel;
  final String label;
  final bool isLocked;
  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    return AnimatedContainer(
      duration: motion.base,
      curve: AppMotion.standard,
      height: _SlideToConfirmState._height,
      decoration: BoxDecoration(
        color: isLocked ? Palette.line : Palette.brand,
        borderRadius: const BorderRadius.all(
          Radius.circular(_SlideToConfirmState._height / 2),
        ),
      ),
      child: AnimatedBuilder(
        animation: position,
        builder: (context, _) {
          final value = position.value.clamp(0.0, 1.0);
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - value * 1.4).clamp(0.0, 1.0),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: _SlideToConfirmState._knob,
                  ),
                  child: Text(
                    label,
                    style: AppTextStyle.button.copyWith(
                      color: isLocked ? Palette.inkMuted : Palette.onBrand,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _SlideToConfirmState._padding + value * travel,
                top: _SlideToConfirmState._padding,
                child: _Knob(isLocked: isLocked, phase: phase),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.isLocked, required this.phase});

  final bool isLocked;
  final _Phase phase;

  @override
  Widget build(BuildContext context) {
    final motion = AppMotion.of(context);
    final color = isLocked ? Palette.inkMuted : Palette.brand;
    final Widget content = switch (phase) {
      _Phase.submitting => motion.canLoop
          ? SizedBox.square(
              key: const ValueKey('spinner'),
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: color),
            )
          : Icon(
              Icons.hourglass_top_rounded,
              key: const ValueKey('wait'),
              color: color,
            ),
      _Phase.done => Icon(
          Icons.check_rounded,
          key: const ValueKey('done'),
          color: color,
        ),
      _Phase.idle => Icon(
          isLocked ? Icons.lock_rounded : Icons.arrow_forward_rounded,
          key: ValueKey(isLocked ? 'lock' : 'arrow'),
          color: color,
        ),
    };
    return Container(
      width: _SlideToConfirmState._knob,
      height: _SlideToConfirmState._knob,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Palette.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Palette.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: AnimatedSwitcher(
        duration: motion.fast,
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: content,
      ),
    );
  }
}

class _AccessibleButton extends StatelessWidget {
  const _AccessibleButton({
    required this.label,
    required this.isBusy,
    required this.onPressed,
  });

  final String label;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _SlideToConfirmState._height,
      child: FilledButton(
        onPressed: isBusy ? null : onPressed,
        child: Text(label),
      ),
    );
  }
}
