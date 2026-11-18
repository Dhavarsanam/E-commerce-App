import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import 'effects.dart';

/// Real product photography with premium loading behaviour:
/// - shimmer skeleton while the photo downloads
/// - the photo fades in and settles from a slight zoom when ready
/// - optional slow "Ken Burns" drift for hero surfaces
/// - soft vignette so overlaid text and buttons stay legible
/// - falls back to the code-rendered [ProductArt] if the network fails
class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    super.key,
    required this.product,
    this.index = 0,
    this.width = 400,
    this.radius = 0,
    this.alignment = Alignment.center,
    this.vignette = true,
    this.kenBurns = false,
    this.fit = BoxFit.cover,
  });

  final Product product;
  final int index;

  /// Approximate rendered width in logical pixels, used to request a
  /// right-sized image from the CDN.
  final int width;
  final double radius;
  final Alignment alignment;
  final bool vignette;
  final bool kenBurns;
  final BoxFit fit;

  /// Width used by product cards; larger surfaces reuse it as a placeholder.
  static const _thumbWidth = 200;

  /// The exact provider [ProductPhoto] renders with, so [precache] hits the
  /// same image-cache entry.
  static ImageProvider provider(Product product, {int index = 0, int width = 400, required double dpr}) =>
      ResizeImage(NetworkImage(product.imageUrl(index, width: width)), width: (width * dpr).round());

  /// Downloads and decodes a photo ahead of time (e.g. during the splash)
  /// so it appears instantly when its screen opens.
  static Future<void> precache(BuildContext context, Product product, {int index = 0, int width = 400}) {
    if (product.images.isEmpty) return Future.value();
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return precacheImage(
      provider(product, index: index, width: width, dpr: dpr),
      context,
      onError: (_, _) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (product.images.isEmpty) {
      return LayoutBuilder(
        builder: (context, c) =>
            ProductArt(product: product, size: math.min(c.maxWidth, c.maxHeight) * 0.75, radius: radius),
      );
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    Widget image = Image(
      image: provider(product, index: index, width: width, dpr: dpr),
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.medium,
      frameBuilder: (context, child, frame, sync) {
        if (sync) return child;
        final ready = frame != null;
        return AnimatedOpacity(
          opacity: ready ? 1 : 0,
          duration: const Duration(milliseconds: 550),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: ready ? 1 : 1.08,
            duration: const Duration(milliseconds: 900),
            curve: const Cubic(0.2, 0.0, 0, 1.0),
            child: child,
          ),
        );
      },
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Stack(
              fit: StackFit.expand,
              children: [
                Shimmer(child: ColoredBox(color: Color.lerp(product.colors[1], Colors.black, 0.2)!)),
                child,
              ],
            ),
      errorBuilder: (context, _, _) => LayoutBuilder(
        builder: (context, c) =>
            ProductArt(product: product, size: math.min(c.maxWidth, c.maxHeight) * 0.75, radius: radius),
      ),
    );
    if (kenBurns) image = _KenBurns(child: image);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Static tint underneath so there's never a hard flash of empty space.
          // Skipped for letterboxed (contain) photos, where it would show as bars.
          if (fit == BoxFit.cover) ColoredBox(color: Color.lerp(product.colors[1], Colors.black, 0.2)!),
          // Progressive loading: large surfaces first show the small thumbnail
          // (usually already cached from the product card), then the sharp
          // version fades in over it.
          if (width > _thumbWidth)
            Image.network(
              product.imageUrl(index, width: _thumbWidth),
              fit: fit,
              alignment: alignment,
              cacheWidth: (_thumbWidth * dpr).round(),
              gaplessPlayback: true,
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          image,
          if (vignette)
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x14000000), Color(0x00000000), Color(0x00000000), Color(0x40000000)],
                    stops: [0, 0.25, 0.6, 1],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Very slow push-in and drift, like a camera move on a still photo.
class _KenBurns extends StatefulWidget {
  const _KenBurns({required this.child});
  final Widget child;

  @override
  State<_KenBurns> createState() => _KenBurnsState();
}

class _KenBurnsState extends State<_KenBurns> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
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
        final t = Curves.easeInOut.transform(_c.value);
        return Transform.scale(
          scale: 1.0 + 0.08 * t,
          alignment: Alignment(-0.3 + 0.6 * t, -0.2 + 0.3 * t),
          child: child,
        );
      },
    );
  }
}

/// A studio-lit, pseudo-3D product render built entirely from code:
/// gradient stage, rim light, floating hero object, contact shadow and
/// a floor reflection. [spin] rotates the object around its Y axis
/// (used by the 360° viewer); [float] enables the idle hover bob.
class ProductArt extends StatefulWidget {
  const ProductArt({
    super.key,
    required this.product,
    this.size = 120,
    this.spin = 0,
    this.float = true,
    this.tint,
    this.showStage = true,
    this.radius = 26,
  });

  final Product product;
  final double size;
  final double spin;
  final bool float;
  final Color? tint;
  final bool showStage;
  final double radius;

  @override
  State<ProductArt> createState() => _ProductArtState();
}

class _ProductArtState extends State<ProductArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));

  @override
  void initState() {
    super.initState();
    if (widget.float) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ProductArt old) {
    super.didUpdateWidget(old);
    if (widget.float == old.float) return;
    widget.float ? _c.repeat(reverse: true) : _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.product.colors;
    final top = Color.lerp(colors[0], widget.tint ?? colors[0], 0.6)!;
    final bottom = colors[1];
    final s = widget.size;

    final object = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final bob = Curves.easeInOut.transform(_c.value);
        final dy = -s * 0.06 * bob;
        final angle = widget.spin;
        // Foreshorten width as it spins to sell depth.
        final squash = 0.55 + 0.45 * math.cos(angle).abs();
        final facingBack = math.cos(angle) < 0;
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Contact shadow shrinks as the object lifts.
            Positioned(
              bottom: s * 0.08,
              child: Container(
                width: s * (0.62 - 0.1 * bob) * squash,
                height: s * 0.07,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(s),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45 - 0.15 * bob),
                      blurRadius: s * 0.12,
                      spreadRadius: s * 0.01,
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, dy),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(angle)
                  ..rotateX(0.12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow
                    Container(
                      width: s * 0.7,
                      height: s * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: top.withValues(alpha: 0.7), blurRadius: s * 0.4)],
                      ),
                    ),
                    // Depth layers for an extruded look
                    for (var i = 5; i >= 1; i--)
                      Transform.translate(
                        offset: Offset(i * 0.9 * (facingBack ? -1 : 1), i * 0.9),
                        child: Icon(
                          widget.product.icon,
                          size: s * 0.62,
                          color: Color.lerp(bottom, Colors.black, 0.4)!.withValues(alpha: 0.9),
                        ),
                      ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (r) => LinearGradient(
                        begin: Alignment(-1 + math.sin(angle), -1),
                        end: Alignment(1 + math.sin(angle), 1),
                        colors: [
                          Colors.white,
                          Color.lerp(top, Colors.white, 0.35)!,
                          top,
                          Color.lerp(top, Colors.black, 0.3)!,
                        ],
                        stops: const [0, 0.25, 0.6, 1],
                      ).createShader(r),
                      child: Icon(widget.product.icon, size: s * 0.62),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!widget.showStage) return SizedBox(width: s, height: s, child: object);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(top, Colors.white, 0.08)!, bottom],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Key light
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.8),
                  radius: 1.0,
                  colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
            // Floor
            Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: 0.35,
                widthFactor: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.25)],
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SizedBox(width: s, height: s, child: object),
            ),
          ],
        ),
      ),
    );
  }
}
