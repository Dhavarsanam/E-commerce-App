import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Smooth area chart that draws itself in, with a glowing end dot.
class AreaChart extends StatelessWidget {
  const AreaChart({super.key, required this.values, this.height = 180, this.color});
  final List<double> values;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1600),
      curve: Motion.emphasized,
      builder: (context, t, _) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _AreaPainter(values, t, color ?? p.accent, p.accent2, p.stroke)),
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.v, this.t, this.c1, this.c2, this.grid);
  final List<double> v;
  final double t;
  final Color c1;
  final Color c2;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = v.reduce(math.max) * 1.15;
    final minV = v.reduce(math.min) * 0.8;
    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gp);
    }

    Offset pt(int i) =>
        Offset(size.width * i / (v.length - 1), size.height - (v[i] - minV) / (maxV - minV) * size.height);

    final path = Path()..moveTo(pt(0).dx, pt(0).dy);
    for (var i = 1; i < v.length; i++) {
      final a = pt(i - 1), b = pt(i);
      final mx = (a.dx + b.dx) / 2;
      path.cubicTo(mx, a.dy, mx, b.dy, b.dx, b.dy);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c1.withValues(alpha: 0.45), c1.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [c1, c2]).createShader(Offset.zero & size),
    );
    canvas.restore();

    // End-point glow follows the reveal.
    final metric = path.computeMetrics().first;
    final tan = metric.getTangentForOffset(metric.length * t);
    if (tan != null) {
      canvas.drawCircle(tan.position, 12, Paint()..color = c2.withValues(alpha: 0.25));
      canvas.drawCircle(tan.position, 5, Paint()..color = Colors.white);
      canvas.drawCircle(tan.position, 3, Paint()..color = c2);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaPainter o) => o.t != t || o.v != v;
}

/// Bar chart with staggered spring-up bars and a highlighted peak.
class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values, required this.labels, this.height = 160});
  final List<double> values;
  final List<String> labels;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final maxV = values.reduce(math.max);
    final peak = values.indexOf(maxV);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: values[i] / maxV),
                      duration: Duration(milliseconds: 900 + i * 90),
                      curve: Curves.easeOutBack,
                      builder: (context, f, _) => FractionallySizedBox(
                        heightFactor: f.clamp(0.02, 1.05),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: i == peak
                                ? p.brandGradient
                                : LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [p.surfaceHigh, p.surfaceHigh.withValues(alpha: 0.4)],
                                  ),
                            boxShadow: i == peak
                                ? [
                                    BoxShadow(
                                      color: p.accent2.withValues(alpha: 0.45),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  labels[i],
                  style: context.text.labelSmall?.copyWith(color: i == peak ? p.textPrimary : p.textMuted),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class DonutSegment {
  const DonutSegment(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

/// Donut that sweeps in segment by segment.
class DonutChart extends StatelessWidget {
  const DonutChart({super.key, required this.segments, this.size = 150, this.center});
  final List<DonutSegment> segments;
  final double size;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1400),
      curve: Motion.emphasized,
      builder: (context, t, child) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _DonutPainter(segments, t, context.palette.surfaceHigh), child: child),
      ),
      child: Center(child: center),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.s, this.t, this.track);
  final List<DonutSegment> s;
  final double t;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.13;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - stroke / 2);
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );
    final total = s.fold(0.0, (a, b) => a + b.value);
    var start = -math.pi / 2;
    final gap = 0.06;
    for (final seg in s) {
      final sweep = (seg.value / total) * math.pi * 2 * t;
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(0, sweep - gap),
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = seg.color,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) => o.t != t;
}

/// Tiny inline trend line for stat tiles.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color, this.width = 70, this.height = 28});
  final List<double> values;
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: _SparkPainter(values, color)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.v, this.c);
  final List<double> v;
  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    final maxV = v.reduce(math.max), minV = v.reduce(math.min);
    final path = Path();
    for (var i = 0; i < v.length; i++) {
      final o = Offset(
        size.width * i / (v.length - 1),
        size.height - (v[i] - minV) / (maxV - minV + 0.001) * size.height,
      );
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = c,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
