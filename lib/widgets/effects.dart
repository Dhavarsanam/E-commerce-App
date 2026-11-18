import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

/// Slowly drifting, blurred colour orbs used as a living backdrop.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child, this.intensity = 1});
  final Widget child;
  final double intensity;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = (context.isDark ? 0.55 : 0.35) * widget.intensity;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: p.bg)),
        Positioned.fill(
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value * 2 * math.pi;
                return CustomPaint(
                  painter: _OrbPainter([
                    _Orb(
                      Offset(0.15 + 0.12 * math.sin(t), 0.12 + 0.06 * math.cos(t)),
                      0.55,
                      p.accent.withValues(alpha: a),
                    ),
                    _Orb(
                      Offset(0.9 + 0.08 * math.cos(t * 1.3), 0.3 + 0.1 * math.sin(t)),
                      0.45,
                      p.accent2.withValues(alpha: a * 0.8),
                    ),
                    _Orb(
                      Offset(0.4 + 0.15 * math.sin(t * 0.7), 0.95 + 0.05 * math.cos(t)),
                      0.5,
                      p.accent3.withValues(alpha: a * 0.5),
                    ),
                  ]),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Orb {
  const _Orb(this.center, this.radius, this.color);
  final Offset center;
  final double radius;
  final Color color;
}

class _OrbPainter extends CustomPainter {
  _OrbPainter(this.orbs);
  final List<_Orb> orbs;

  @override
  void paint(Canvas canvas, Size size) {
    for (final o in orbs) {
      final c = Offset(o.center.dx * size.width, o.center.dy * size.height);
      final r = o.radius * size.width;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [o.color, o.color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbPainter old) => true;
}

/// Frosted glass surface with a hairline highlight border.
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = Radii.lg,
    this.padding = EdgeInsets.zero,
    this.blur = 22,
    this.opacity,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final double? opacity;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: opacity == null ? p.glass : p.surface.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: p.stroke),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: context.isDark ? 0.08 : 0.5),
                Colors.white.withValues(alpha: context.isDark ? 0.01 : 0.15),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Springy press feedback with a light haptic tick.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.95, this.haptic = true});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down ? Motion.fast : Motion.slow,
        curve: _down ? Curves.easeOut : Motion.spring,
        child: widget.child,
      ),
    );
  }
}

/// Interactive 3D tilt: the child leans toward the finger with perspective
/// and a moving specular glare, then springs back on release.
class TiltCard extends StatefulWidget {
  const TiltCard({super.key, required this.child, this.maxTilt = 0.22, this.radius = Radii.lg, this.glare = true});
  final Widget child;
  final double maxTilt;
  final double radius;
  final bool glare;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with SingleTickerProviderStateMixin {
  Offset _tilt = Offset.zero; // -1..1
  Offset _from = Offset.zero;
  late final AnimationController _spring;

  @override
  void initState() {
    super.initState();
    _spring = AnimationController(vsync: this, duration: Motion.xslow)
      ..addListener(
        () => setState(() => _tilt = Offset.lerp(_from, Offset.zero, Motion.spring.transform(_spring.value))!),
      );
  }

  void _update(Offset local, Size size) {
    _spring.stop();
    setState(() {
      _tilt = Offset(
        ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
        ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
      );
    });
  }

  void _release() {
    _from = _tilt;
    _spring.forward(from: 0);
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth.isFinite ? c.maxWidth : 200, c.maxHeight.isFinite ? c.maxHeight : 200);
        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateX(-_tilt.dy * widget.maxTilt)
          ..rotateY(_tilt.dx * widget.maxTilt);
        return Listener(
          onPointerDown: (e) => _update(e.localPosition, size),
          onPointerMove: (e) => _update(e.localPosition, size),
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: MouseRegion(
            onHover: (e) => _update(e.localPosition, size),
            onExit: (_) => _release(),
            child: Transform(
              alignment: Alignment.center,
              transform: m,
              child: Stack(
                children: [
                  widget.child,
                  if (widget.glare)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(widget.radius),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment(_tilt.dx, _tilt.dy),
                                radius: 1.1,
                                colors: [
                                  Colors.white.withValues(alpha: 0.18 * _tilt.distance.clamp(0, 1)),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Staggered entrance: fades, lifts and de-blurs into place.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
    this.axis = Axis.vertical,
  });
  final Widget child;
  final Duration delay;
  final double offset;
  final Axis axis;

  /// Convenience for list positions.
  static Duration stagger(int i, {int ms = 60, int base = 0}) => Duration(milliseconds: base + i * ms);

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.slow + const Duration(milliseconds: 200));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Motion.decelerate.transform(_c.value);
        final d = (1 - t) * widget.offset;
        return Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(
            offset: widget.axis == Axis.vertical ? Offset(0, d) : Offset(d, 0),
            child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
          ),
        );
      },
    );
  }
}

/// Skeleton loading shimmer.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});
  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment(-1.5 + 3 * _c.value, 0),
          end: Alignment(-0.5 + 3 * _c.value, 0),
          colors: [p.surfaceHigh, p.textMuted.withValues(alpha: 0.35), p.surfaceHigh],
        ).createShader(r),
        child: child,
      ),
    );
  }
}

class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.gradient});
  final String text;
  final TextStyle? style;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => (gradient ?? context.palette.auroraGradient).createShader(r),
      child: Text(text, style: style),
    );
  }
}

/// Number that rolls smoothly to its new value.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    this.style,
    this.prefix = '',
    this.decimals = 0,
    this.suffix = '',
  });
  final double value;
  final TextStyle? style;
  final String prefix;
  final String suffix;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: Motion.xslow,
      curve: Motion.emphasized,
      builder: (context, v, _) => Text('$prefix${_fmt(v, decimals)}$suffix', style: style),
    );
  }

  static String _fmt(double v, int decimals) {
    final s = v.toStringAsFixed(decimals);
    final parts = s.split('.');
    final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
    return parts.length > 1 ? '$whole.${parts[1]}' : whole;
  }
}

String money(double v) => '\$${AnimatedCount._fmt(v, v == v.roundToDouble() ? 0 : 2)}';

/// Short form for summary figures: $1.23M, $302K, $940.
String compactMoney(double v) {
  if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
  if (v >= 1e4) return '\$${(v / 1e3).toStringAsFixed(0)}K';
  return money(v.roundToDouble());
}

/// Premium route: fade + scale + slight lift.
Route<T> premiumRoute<T>(Widget page, {bool fullscreenDialog = false}) {
  return PageRouteBuilder<T>(
    fullscreenDialog: fullscreenDialog,
    transitionDuration: const Duration(milliseconds: 520),
    reverseTransitionDuration: const Duration(milliseconds: 380),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (context, a, sa, child) {
      final curved = CurvedAnimation(parent: a, curve: Motion.emphasized, reverseCurve: Curves.easeInCubic);
      final out = CurvedAnimation(parent: sa, curve: Motion.emphasized);
      return AnimatedBuilder(
        animation: Listenable.merge([curved, out]),
        child: child,
        builder: (context, child) => Opacity(
          opacity: curved.value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - curved.value)),
            child: Transform.scale(scale: (0.94 + 0.06 * curved.value) * (1 - 0.05 * out.value), child: child),
          ),
        ),
      );
    },
  );
}
