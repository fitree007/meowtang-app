import 'package:flutter/material.dart';

/// Small, quiet entrance animations shared by the stats and premium screens.
///
/// Every effect plays once (when first built, or when [key]/value changes),
/// lasts under a second and is skipped when the OS asks for reduced motion.
class MeowFx {
  MeowFx._();

  static const Duration stagger = Duration(milliseconds: 60);
  static const Curve curve = Cubic(0.2, 0.7, 0.2, 1);

  static bool reduced(BuildContext context) => MediaQuery.maybeOf(context)?.disableAnimations ?? false;
}

/// Fades a card in while it rises 10px. Use [index] to stagger a list of cards.
class FxFadeUp extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration duration;

  const FxFadeUp({super.key, required this.child, this.index = 0, this.duration = const Duration(milliseconds: 420)});

  @override
  Widget build(BuildContext context) {
    if (MeowFx.reduced(context)) return child;
    final delay = MeowFx.stagger * index.clamp(0, 8);
    final total = duration + delay;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) {
        final v = MeowFx.curve.transform(((t - start) / (1 - start)).clamp(0.0, 1.0));
        return Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
        );
      },
      child: child,
    );
  }
}

/// Animates a 0..1 value from its previous value (0 on first build) to [value].
/// Handy for progress bars, rings and chart reveals.
class FxProgress extends StatelessWidget {
  final double value;
  final Duration duration;
  final Widget Function(BuildContext context, double value) builder;

  const FxProgress({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    if (MeowFx.reduced(context)) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: MeowFx.curve,
      builder: (context, v, _) => builder(context, v),
    );
  }
}

/// A rounded horizontal bar whose fill grows from the left.
class FxBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;

  const FxBar({super.key, required this.value, required this.color, required this.track, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(height / 2);
    return ClipRRect(
      borderRadius: r,
      child: Container(
        height: height,
        color: track,
        alignment: Alignment.centerLeft,
        child: FxProgress(
          value: value.clamp(0.0, 1.0),
          builder: (_, v) => FractionallySizedBox(
            widthFactor: v,
            child: Container(decoration: BoxDecoration(color: color, borderRadius: r)),
          ),
        ),
      ),
    );
  }
}

/// Scales a child down slightly while pressed.
class FxPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const FxPress({super.key, required this.child, this.onTap});

  @override
  State<FxPress> createState() => _FxPressState();
}

class _FxPressState extends State<FxPress> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _set(true),
      onTapUp: widget.onTap == null ? null : (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down && !MeowFx.reduced(context) ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}
