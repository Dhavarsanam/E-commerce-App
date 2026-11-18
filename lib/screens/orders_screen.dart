import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import '../widgets/product_visual.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    return Scaffold(
      body: AuroraBackground(
        intensity: 0.5,
        child: Column(
          children: [
            const TopBar(title: 'My orders'),
            Expanded(
              child: state.orders.isEmpty
                  ? const EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'No orders yet',
                      body: 'Your purchases will show up here.',
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      itemCount: state.orders.length,
                      itemBuilder: (context, i) {
                        final o = state.orders[i];
                        final delivered = o.status == OrderStatus.delivered;
                        return Reveal(
                          delay: Reveal.stagger(i),
                          child: Pressable(
                            scale: 0.98,
                            onTap: () => Navigator.of(context).push(premiumRoute(TrackingScreen(order: o))),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: BorderRadius.circular(Radii.lg),
                                border: Border.all(color: p.stroke),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          o.id,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.text.titleSmall,
                                        ),
                                      ),
                                      Pill(
                                        o.status.label,
                                        color: delivered ? p.success : p.accent,
                                        icon: o.status.icon,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${o.date.day}/${o.date.month}/${o.date.year} · ${o.items.length} item${o.items.length == 1 ? '' : 's'}',
                                    style: context.text.bodySmall?.copyWith(color: p.textMuted),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      // Overlapping stack of product thumbnails.
                                      SizedBox(
                                        height: 56,
                                        width: 56 + (math.min(o.items.length, 3) - 1) * 34.0,
                                        child: Stack(
                                          children: [
                                            for (var k = 0; k < math.min(o.items.length, 3); k++)
                                              Positioned(
                                                left: k * 34.0,
                                                child: Container(
                                                  width: 56,
                                                  height: 56,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(16),
                                                    border: Border.all(color: p.surface, width: 3),
                                                  ),
                                                  child: ProductPhoto(
                                                    product: o.items[k].product,
                                                    width: 56,
                                                    radius: 13,
                                                    vignette: false,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('Total', style: context.text.labelSmall?.copyWith(color: p.textMuted)),
                                          Text(
                                            money(o.total),
                                            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  _MiniProgress(status: o.status),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final f = (status.index + 1) / OrderStatus.values.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(height: 6, color: p.surfaceHigh),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: f),
            duration: const Duration(milliseconds: 1200),
            curve: Motion.emphasized,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(height: 6, decoration: BoxDecoration(gradient: p.brandGradient)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Live tracking: stylised map with an animated courier, ETA card and
/// a vertical timeline that fills as statuses complete.
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key, required this.order});
  final Order order;

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = widget.order;
    final progress = (o.status.index) / (OrderStatus.values.length - 1);
    return Scaffold(
      body: AuroraBackground(
        intensity: 0.5,
        child: Column(
          children: [
            TopBar(title: 'Track order', subtitle: o.id),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                children: [
                  Reveal(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.xl),
                      child: Container(
                        height: 240,
                        color: p.surface,
                        child: AnimatedBuilder(
                          animation: _c,
                          builder: (context, _) => CustomPaint(
                            painter: _MapPainter(
                              t: o.status == OrderStatus.delivered ? 1 : progress * 0.85 + 0.1 * _c.value,
                              pulse: _c.value,
                              route: p.accent,
                              route2: p.accent2,
                              grid: p.stroke,
                              bg: p.surfaceHigh,
                            ),
                            size: Size.infinite,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Reveal(
                    delay: Reveal.stagger(1),
                    child: Glass(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: p.brandGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(o.status.icon, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.status.label, style: context.text.titleMedium),
                                Text(
                                  o.status == OrderStatus.delivered
                                      ? 'Delivered to your door'
                                      : 'Estimated arrival · Today, 2–4 PM',
                                  style: context.text.bodySmall?.copyWith(color: p.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconBubble(
                            icon: Icons.call_rounded,
                            size: 44,
                            color: p.success,
                            onTap: () => showComingSoon(
                              context,
                              title: 'Call your courier',
                              icon: Icons.call_rounded,
                              body: 'Masked calling to your courier unlocks when live delivery tracking is connected.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Journey', style: context.text.titleMedium),
                  const SizedBox(height: 12),
                  for (final s in OrderStatus.values)
                    Reveal(
                      delay: Reveal.stagger(s.index + 2, ms: 90),
                      child: _TimelineRow(status: s, current: o.status, placedAt: o.date),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.status, required this.current, required this.placedAt});
  final OrderStatus status;
  final OrderStatus current;
  final DateTime placedAt;

  /// When this step happened, derived from the real order time (never in the future).
  String _stepTime() {
    const offsets = [Duration.zero, Duration(hours: 5), Duration(hours: 22), Duration(hours: 46), Duration(hours: 50)];
    final now = DateTime.now();
    var t = placedAt.add(offsets[status.index]);
    if (t.isAfter(now)) t = now.subtract(Duration(minutes: 20 * (current.index - status.index)));
    final hm = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    if (status == OrderStatus.placed && now.difference(t).inMinutes < 2) return 'Just now';
    if (day == today) return 'Today, $hm';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday, $hm';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[t.weekday - 1]}, $hm';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final done = status.index <= current.index;
    final active = status == current;
    final last = status == OrderStatus.values.last;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                _Dot(done: done, active: active),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 3,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: status.index < current.index ? p.brandGradient : null,
                        color: status.index < current.index ? null : p.surfaceHigh,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 26, top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.label,
                          style: context.text.titleSmall?.copyWith(color: done ? p.textPrimary : p.textMuted),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          done ? _stepTime() : 'Upcoming',
                          style: context.text.bodySmall?.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(status.icon, color: done ? p.accent : p.textMuted.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot({required this.done, required this.active});
  final bool done;
  final bool active;

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    if (widget.active) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 30,
      height: 30,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            if (widget.active)
              Container(
                width: 30 * (0.6 + 0.6 * _c.value),
                height: 30 * (0.6 + 0.6 * _c.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.accent.withValues(alpha: 0.4 * (1 - _c.value)),
                ),
              ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.done ? p.brandGradient : null,
                color: widget.done ? null : p.surfaceHigh,
                border: Border.all(color: p.bg, width: 3),
              ),
              child: widget.done && !widget.active
                  ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.t,
    required this.pulse,
    required this.route,
    required this.route2,
    required this.grid,
    required this.bg,
  });
  final double t;
  final double pulse;
  final Color route;
  final Color route2;
  final Color grid;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    // Streets
    final street = Paint()
      ..color = bg
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < 5; i++) {
      canvas.drawLine(Offset(0, size.height * i / 5), Offset(size.width, size.height * i / 5 + 20), street);
    }
    for (var i = 1; i < 6; i++) {
      canvas.drawLine(Offset(size.width * i / 6, 0), Offset(size.width * i / 6 - 30, size.height), street);
    }
    // Blocks
    final block = Paint()..color = grid;
    final r = math.Random(3);
    for (var i = 0; i < 14; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            r.nextDouble() * size.width,
            r.nextDouble() * size.height,
            20 + r.nextDouble() * 30,
            14 + r.nextDouble() * 20,
          ),
          const Radius.circular(4),
        ),
        block,
      );
    }
    // Route
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.9,
        size.width * 0.35,
        size.height * 0.3,
        size.width * 0.55,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.6,
        size.width * 0.75,
        size.height * 0.15,
        size.width * 0.9,
        size.height * 0.22,
      );
    final m = path.computeMetrics().first;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = route.withValues(alpha: 0.25),
    );
    canvas.drawPath(
      m.extractPath(0, m.length * t.clamp(0, 1)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [route, route2]).createShader(Offset.zero & size),
    );
    // Destination pin with pulse
    final dest = m.getTangentForOffset(m.length)!.position;
    canvas.drawCircle(dest, 10 + 18 * pulse, Paint()..color = route2.withValues(alpha: 0.3 * (1 - pulse)));
    canvas.drawCircle(dest, 9, Paint()..color = route2);
    canvas.drawCircle(dest, 4, Paint()..color = Colors.white);
    // Courier
    final pos = m.getTangentForOffset(m.length * t.clamp(0, 1))!.position;
    canvas.drawCircle(pos, 18, Paint()..color = route.withValues(alpha: 0.25));
    canvas.drawCircle(pos, 11, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 7, Paint()..color = route);
    // Origin
    final origin = m.getTangentForOffset(0)!.position;
    canvas.drawCircle(origin, 6, Paint()..color = route);
  }

  @override
  bool shouldRepaint(covariant _MapPainter o) => o.t != t || o.pulse != pulse;
}
