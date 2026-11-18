import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import 'orders_screen.dart';

class OrderSuccessScreen extends StatefulWidget {
  const OrderSuccessScreen({super.key, required this.order});
  final Order order;

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with TickerProviderStateMixin {
  late final _check = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();
  late final _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();
  final _pieces = List.generate(90, (i) => _Confetto(math.Random(i)));

  @override
  void dispose() {
    _check.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = [p.accent, p.accent2, p.accent3, p.gold, p.success];
    return Scaffold(
      body: AuroraBackground(
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _confetti,
                  builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _confetti.value, colors)),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _check,
                      builder: (context, _) {
                        final s = Curves.elasticOut.transform((_check.value * 1.5).clamp(0, 1));
                        final draw = Curves.easeOutCubic.transform(((_check.value - 0.3) / 0.7).clamp(0, 1));
                        return Transform.scale(
                          scale: s,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: p.brandGradient,
                              boxShadow: [
                                BoxShadow(color: p.accent.withValues(alpha: 0.6), blurRadius: 60),
                                BoxShadow(
                                  color: p.accent2.withValues(alpha: 0.4),
                                  blurRadius: 100,
                                  spreadRadius: 10 * draw,
                                ),
                              ],
                            ),
                            child: CustomPaint(painter: _CheckPainter(draw)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    Reveal(
                      delay: const Duration(milliseconds: 500),
                      child: Text('Order confirmed', style: context.text.displaySmall, textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 12),
                    Reveal(
                      delay: const Duration(milliseconds: 650),
                      child: Text(
                        'Thank you! ${widget.order.id} is being prepared with care.\nWe\'ll notify you at every step.',
                        textAlign: TextAlign.center,
                        style: context.text.bodyLarge?.copyWith(color: p.textSecondary, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Reveal(
                      delay: const Duration(milliseconds: 800),
                      child: Glass(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            _stat(context, 'Total paid', money(widget.order.total)),
                            Container(width: 1, height: 36, color: p.stroke),
                            _stat(context, 'Arrives', 'Fri, 2–4 PM'),
                            Container(width: 1, height: 36, color: p.stroke),
                            _stat(context, 'Points', '+${widget.order.total.round()}'),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    Reveal(
                      delay: const Duration(milliseconds: 950),
                      child: GradientButton(
                        label: 'Track order',
                        icon: Icons.near_me_rounded,
                        onTap: () =>
                            Navigator.of(context).pushReplacement(premiumRoute(TrackingScreen(order: widget.order))),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                      child: Text('Continue shopping', style: TextStyle(color: p.textSecondary)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String k, String v) => Expanded(
    child: Column(
      children: [
        Text(k, style: context.text.labelSmall?.copyWith(color: context.palette.textMuted)),
        const SizedBox(height: 4),
        Text(v, style: context.text.titleSmall),
      ],
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.3, size.height * 0.52)
      ..lineTo(size.width * 0.45, size.height * 0.66)
      ..lineTo(size.width * 0.72, size.height * 0.38);
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CheckPainter o) => o.t != t;
}

class _Confetto {
  _Confetto(math.Random r)
    : x = r.nextDouble(),
      delay = r.nextDouble() * 0.3,
      speed = 0.6 + r.nextDouble() * 0.8,
      drift = (r.nextDouble() - 0.5) * 0.3,
      spin = r.nextDouble() * 10,
      size = 6 + r.nextDouble() * 8,
      color = r.nextInt(5),
      circle = r.nextBool();
  final double x, delay, speed, drift, spin, size;
  final int color;
  final bool circle;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.t, this.colors);
  final List<_Confetto> pieces;
  final double t;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final c in pieces) {
      final lt = ((t - c.delay) / (1 - c.delay)).clamp(0.0, 1.0);
      if (lt == 0) continue;
      final y = -40 + lt * c.speed * size.height * 1.2;
      final x = (c.x + c.drift * lt + math.sin(lt * 10 + c.spin) * 0.02) * size.width;
      final paint = Paint()..color = colors[c.color].withValues(alpha: (1 - lt).clamp(0, 1));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(lt * c.spin);
      if (c.circle) {
        canvas.drawCircle(Offset.zero, c.size / 2.5, paint);
      } else {
        // Fake 3D tumble by squashing the rectangle over time.
        canvas.scale(1, math.cos(lt * c.spin * 3));
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.45),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => o.t != t;
}
