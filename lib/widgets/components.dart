import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import 'effects.dart';
import 'product_visual.dart';

/// Primary CTA: gradient fill, soft coloured glow and a periodic light sweep.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.height = 60,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final double height;
  final bool expand;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> with SingleTickerProviderStateMixin {
  late final _shine = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = widget.onTap != null && !widget.loading;
    return Pressable(
      onTap: enabled ? widget.onTap : null,
      scale: 0.97,
      child: AnimatedOpacity(
        duration: Motion.fast,
        opacity: widget.onTap == null ? 0.5 : 1,
        child: Container(
          height: widget.height,
          width: widget.expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(horizontal: widget.label.isEmpty ? 0 : 20),
          decoration: BoxDecoration(
            gradient: p.brandGradient,
            borderRadius: BorderRadius.circular(widget.height / 2),
            boxShadow: [
              BoxShadow(color: p.accent.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10)),
              BoxShadow(color: p.accent2.withValues(alpha: 0.25), blurRadius: 40, offset: const Offset(0, 18)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.height / 2),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shine,
                    builder: (context, _) {
                      final t = Curves.easeInOut.transform((_shine.value * 1.6).clamp(0, 1));
                      return FractionalTranslation(
                        translation: Offset(-1.2 + 2.4 * t, 0),
                        child: Transform.rotate(
                          angle: 0.4,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.28),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                AnimatedSwitcher(
                  duration: Motion.medium,
                  transitionBuilder: (c, a) => ScaleTransition(
                    scale: a,
                    child: FadeTransition(opacity: a, child: c),
                  ),
                  child: widget.loading
                      ? const SizedBox(
                          key: ValueKey('l'),
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                        )
                      : FittedBox(
                          key: ValueKey('t${widget.label}'),
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) Icon(widget.icon, color: Colors.white, size: 20),
                              if (widget.icon != null && widget.label.isNotEmpty) const SizedBox(width: 10),
                              if (widget.label.isNotEmpty)
                                Text(
                                  widget.label,
                                  maxLines: 1,
                                  style: context.text.titleMedium?.copyWith(color: Colors.white, letterSpacing: 0.3),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round glass icon button with optional animated badge.
class IconBubble extends StatelessWidget {
  const IconBubble({super.key, required this.icon, this.onTap, this.badge = 0, this.size = 48, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final int badge;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: 0.88,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Glass(
              radius: size / 2,
              blur: 16,
              child: SizedBox(
                width: size,
                height: size,
                child: Icon(icon, size: size * 0.46, color: color ?? p.textPrimary),
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: AnimatedSwitcher(
                duration: Motion.medium,
                transitionBuilder: (c, a) => ScaleTransition(
                  scale: CurvedAnimation(parent: a, curve: Motion.spring),
                  child: c,
                ),
                child: badge == 0
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(badge),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 20),
                        decoration: BoxDecoration(
                          gradient: p.brandGradient,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: p.bg, width: 2),
                        ),
                        child: Text(
                          '$badge',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wishlist heart with a particle burst + elastic pop.
class HeartButton extends StatefulWidget {
  const HeartButton({super.key, required this.productId, this.size = 40});
  final String productId;
  final double size;

  @override
  State<HeartButton> createState() => _HeartButtonState();
}

class _HeartButtonState extends State<HeartButton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    final on = state.isWished(widget.productId);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        final willBeOn = !on;
        state.toggleWish(widget.productId);
        if (willBeOn) _c.forward(from: 0);
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final pop = _c.isAnimating ? 1 + 0.35 * math.sin(t * math.pi) : 1.0;
            return CustomPaint(
              painter: _BurstPainter(t, p.accent2, p.accent3, _c.isAnimating),
              child: Glass(
                radius: widget.size / 2,
                blur: 12,
                child: Center(
                  child: Transform.scale(
                    scale: pop,
                    child: Icon(
                      on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      size: widget.size * 0.5,
                      color: on ? p.accent2 : Colors.white,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.a, this.b, this.active);
  final double t;
  final Color a;
  final Color b;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (!active) return;
    final c = size.center(Offset.zero);
    final eased = Curves.easeOut.transform(t);
    final r = size.width * (0.4 + 0.6 * eased);
    for (var i = 0; i < 10; i++) {
      final ang = i / 10 * 2 * math.pi;
      final o = c + Offset(math.cos(ang), math.sin(ang)) * r;
      canvas.drawCircle(o, 3 * (1 - eased), Paint()..color = (i.isEven ? a : b).withValues(alpha: 1 - eased));
    }
    canvas.drawCircle(
      c,
      size.width * 0.5 * eased,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - eased)
        ..color = a.withValues(alpha: (1 - eased) * 0.8),
    );
  }

  @override
  bool shouldRepaint(covariant _BurstPainter old) => old.t != t;
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = 14});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final g = context.palette.gold;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        return Icon(
          fill >= 0.75 ? Icons.star_rounded : (fill >= 0.25 ? Icons.star_half_rounded : Icons.star_outline_rounded),
          size: size,
          color: g,
        );
      }),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.subtitle});
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.bodySmall?.copyWith(color: p.textMuted)),
                ],
              ],
            ),
          ),
          if (action != null)
            Pressable(
              onTap: onAction,
              child: Row(
                children: [
                  Text(action!, style: context.text.labelLarge?.copyWith(color: p.accent)),
                  Icon(Icons.chevron_right_rounded, color: p.accent, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class QtyStepper extends StatelessWidget {
  const QtyStepper({super.key, required this.value, required this.onChanged, this.compact = false});
  final int value;
  final ValueChanged<int> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = compact ? 30.0 : 40.0;
    Widget btn(IconData i, int d) => Pressable(
      onTap: () => onChanged(value + d),
      scale: 0.85,
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          color: p.surfaceHigh,
          shape: BoxShape.circle,
          border: Border.all(color: p.stroke),
        ),
        child: Icon(i, size: s * 0.5, color: p.textPrimary),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        btn(Icons.remove_rounded, -1),
        SizedBox(
          width: compact ? 30 : 40,
          child: AnimatedSwitcher(
            duration: Motion.medium,
            transitionBuilder: (c, a) => SlideTransition(
              position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(a),
              child: FadeTransition(opacity: a, child: c),
            ),
            child: Text('$value', key: ValueKey(value), textAlign: TextAlign.center, style: context.text.titleMedium),
          ),
        ),
        btn(Icons.add_rounded, 1),
      ],
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color, this.icon, this.filled = false});
  final String label;
  final Color? color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? c : c.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: c.withValues(alpha: filled ? 0 : 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 12, color: filled ? Colors.white : c), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(
              color: filled ? Colors.white : c,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// Catalogue card: 3D tilt, floating product render, wishlist burst,
/// quick-add button and Hero hand-off to the detail page.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap, this.heroPrefix = 'grid', this.width});
  final Product product;
  final VoidCallback onTap;
  final String heroPrefix;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = Pressable(
      onTap: onTap,
      scale: 0.97,
      child: TiltCard(
        maxTilt: 0.16,
        child: Container(
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(Radii.lg),
            border: Border.all(color: p.stroke),
            boxShadow: [
              BoxShadow(color: p.shadow.withValues(alpha: 0.25), blurRadius: 24, offset: const Offset(0, 12)),
            ],
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: '$heroPrefix-${product.id}',
                        child: ProductPhoto(product: product, width: 200, radius: Radii.md + 2),
                      ),
                    ),
                    if (product.tag != null)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Pill(product.tag!, color: Colors.black.withValues(alpha: 0.35), filled: true),
                      ),
                    Positioned(right: 6, top: 6, child: HeartButton(productId: product.id, size: 34)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 10, 4, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand,
                      style: context.text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4),
                    ),
                    const SizedBox(height: 2),
                    Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 6,
                            children: [
                              Text(
                                money(product.price),
                                style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              if (product.oldPrice != null)
                                Text(
                                  money(product.oldPrice!),
                                  style: context.text.bodySmall?.copyWith(
                                    color: p.textMuted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _QuickAdd(product: product),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return width == null ? card : SizedBox(width: width, child: card);
  }
}

class _QuickAdd extends StatefulWidget {
  const _QuickAdd({required this.product});
  final Product product;

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      scale: 0.8,
      onTap: () async {
        HapticFeedback.mediumImpact();
        AppScope.read(context).addToCart(
          widget.product,
          size: widget.product.sizes.isEmpty ? null : widget.product.sizes[widget.product.sizes.length ~/ 2],
        );
        setState(() => _done = true);
        await Future.delayed(const Duration(milliseconds: 1200));
        if (mounted) setState(() => _done = false);
      },
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          gradient: _done ? LinearGradient(colors: [p.success, p.success]) : p.brandGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: (_done ? p.success : p.accent).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: Motion.medium,
          transitionBuilder: (c, a) => RotationTransition(
            turns: Tween(begin: 0.5, end: 1.0).animate(a),
            child: ScaleTransition(scale: a, child: c),
          ),
          child: Icon(
            _done ? Icons.check_rounded : Icons.add_rounded,
            key: ValueKey(_done),
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

/// Generic glass app bar row used by inner pages.
class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.title, this.actions = const [], this.showBack = true, this.subtitle});
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 8),
      child: Row(
        children: [
          if (showBack) ...[
            IconBubble(icon: Icons.arrow_back_ios_new_rounded, size: 44, onTap: () => Navigator.maybePop(context)),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.headlineSmall),
                if (subtitle != null)
                  Text(subtitle!, style: context.text.bodySmall?.copyWith(color: context.palette.textMuted)),
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1100),
              curve: Motion.spring,
              builder: (context, v, child) => Transform.scale(scale: v, child: child),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: p.brandGradient,
                  boxShadow: [BoxShadow(color: p.accent.withValues(alpha: 0.5), blurRadius: 50)],
                ),
                child: Icon(icon, size: 52, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              body,
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 28),
              GradientButton(label: action!, onTap: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

/// Polished placeholder for actions that need the backend (addresses, saved
/// cards, support chat…), so no tap in the app is ever a dead end.
Future<void> showComingSoon(BuildContext context, {required String title, required IconData icon, String? body}) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) {
      final p = context.palette;
      return Glass(
        radius: Radii.xl,
        opacity: 0.94,
        padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.paddingOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: p.textMuted, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 24),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: Motion.slow,
              curve: Motion.spring,
              builder: (context, s, child) => Transform.scale(scale: s, child: child),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: p.brandGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: p.accent.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, style: context.text.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              body ?? 'This part of the experience is being crafted and will arrive with the next release.',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            GradientButton(label: 'Got it', onTap: () => Navigator.pop(context)),
          ],
        ),
      );
    },
  );
}
