import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import '../widgets/product_visual.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product, this.heroPrefix = 'grid'});
  final Product product;
  final String heroPrefix;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> with TickerProviderStateMixin {
  final _gallery = PageController();
  double _galleryPage = 0;
  final _cartKey = GlobalKey();
  final _addKey = GlobalKey();
  final _scroll = ScrollController();
  int _swatch = 0;
  String? _size;
  int _qty = 1;
  bool _expanded = false;

  Product get p => widget.product;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() {}));
    if (p.sizes.isNotEmpty) _size = p.sizes[p.sizes.length ~/ 2];
    _gallery.addListener(() => setState(() => _galleryPage = _gallery.page ?? 0));
  }

  @override
  void dispose() {
    _gallery.dispose();
    _scroll.dispose();
    super.dispose();
  }

  int get _photoCount => math.max(1, p.photoCount);

  void _selectSwatch(int i) {
    setState(() => _swatch = i);
    if (p.images.length > 1 && _gallery.hasClients) {
      _gallery.animateToPage(i % p.images.length, duration: Motion.slow, curve: Motion.emphasized);
    }
  }

  void _openViewer(int start) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: Motion.slow,
        reverseTransitionDuration: Motion.medium,
        pageBuilder: (_, _, _) => _PhotoViewer(product: p, initial: start, heroTag: '${widget.heroPrefix}-${p.id}'),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
  }

  void _addToCart() {
    HapticFeedback.mediumImpact();
    AppScope.read(
      context,
    ).addToCart(p, size: _size, swatch: p.swatches.isEmpty ? null : p.swatches[_swatch], qty: _qty);
    _flyToCart();
  }

  /// Animates a glowing orb along a bezier from the CTA to the bag icon.
  void _flyToCart() {
    final overlay = Overlay.of(context);
    final from = (_addKey.currentContext!.findRenderObject() as RenderBox).localToGlobal(const Offset(60, 10));
    final cartBox = _cartKey.currentContext!.findRenderObject() as RenderBox;
    final to = cartBox.localToGlobal(cartBox.size.center(Offset.zero));
    final ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 850));
    final palette = context.palette;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: ctrl,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(ctrl.value);
          final control = Offset((from.dx + to.dx) / 2, math.min(from.dy, to.dy) - 220);
          final pos = Offset(
            math.pow(1 - t, 2) * from.dx + 2 * (1 - t) * t * control.dx + t * t * to.dx,
            math.pow(1 - t, 2) * from.dy + 2 * (1 - t) * t * control.dy + t * t * to.dy,
          );
          final s = 1 - 0.6 * t;
          return Positioned(
            left: pos.dx - 26 * s,
            top: pos.dy - 26 * s,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: t * math.pi * 2,
                // A circular "thumbnail" of the photo flies into the bag, ringed in brand gradient.
                child: Container(
                  width: 60 * s,
                  height: 60 * s,
                  padding: EdgeInsets.all(3 * s),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: palette.brandGradient,
                    boxShadow: [BoxShadow(color: palette.accent2.withValues(alpha: 0.7), blurRadius: 20)],
                  ),
                  child: ClipOval(
                    child: ProductPhoto(product: p, index: _galleryPage.round(), width: 60, vignette: false),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    overlay.insert(entry);
    ctrl.forward().then((_) {
      entry.remove();
      ctrl.dispose();
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          duration: const Duration(seconds: 3),
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: palette.success),
              const SizedBox(width: 10),
              Expanded(child: Text('${p.name} added to bag')),
            ],
          ),
          action: SnackBarAction(
            label: 'VIEW',
            textColor: palette.accent,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.of(context).push(premiumRoute(const CartScreen(standalone: true)));
            },
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    final state = AppScope.of(context);
    final size = MediaQuery.sizeOf(context);
    final heroH = size.height * 0.5;
    final off = _scroll.hasClients ? _scroll.offset : 0.0;
    final similar =
        MockData.products.where((x) => x.id != p.id && (x.categoryId == p.categoryId || x.brand == p.brand)).toList()
          ..addAll(MockData.products.where((x) => x.id != p.id && x.categoryId != p.categoryId).take(3));

    return Scaffold(
      body: AuroraBackground(
        intensity: 0.5,
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: heroH,
                    child: Transform.translate(
                      // Parallax: hero scrolls slower than content and stretches on overscroll.
                      offset: Offset(0, off > 0 ? off * 0.45 : 0),
                      child: Transform.scale(
                        scale: off < 0 ? 1 + (-off / 600) : 1,
                        alignment: Alignment.bottomCenter,
                        child: Hero(
                          tag: '${widget.heroPrefix}-${p.id}',
                          // During the flight show a plain photo; the gallery owns a PageController
                          // that must not be attached twice.
                          flightShuttleBuilder: (_, anim, _, _, _) => AnimatedBuilder(
                            animation: anim,
                            builder: (context, _) => ProductPhoto(
                              product: p,
                              width: 200, // same URL as the card, so it's already cached

                              radius: Radii.md * (1 - anim.value),
                              vignette: false,
                            ),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              PageView.builder(
                                controller: _gallery,
                                itemCount: _photoCount,
                                itemBuilder: (context, i) {
                                  final delta = (_galleryPage - i).clamp(-1.0, 1.0);
                                  return GestureDetector(
                                    onTap: () => _openViewer(i),
                                    // 3D page turn: the outgoing photo hinges away while
                                    // the image inside slides the other way for depth.
                                    child: Transform(
                                      alignment: delta > 0 ? Alignment.centerRight : Alignment.centerLeft,
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.0012)
                                        ..rotateY(-delta * 0.9),
                                      child: ProductPhoto(
                                        product: p,
                                        index: i,
                                        width: 600,
                                        alignment: Alignment(delta * 0.8, 0),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Top scrim keeps the floating glass buttons legible on bright photos.
                              const Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 140,
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Color(0x73000000), Color(0x00000000)],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_photoCount > 1)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 48,
                                  child: IgnorePointer(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(_photoCount, (i) {
                                        final f = (1 - (_galleryPage - i).abs()).clamp(0.0, 1.0);
                                        return Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          width: 7 + 18 * f,
                                          height: 7,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(7),
                                            color: Colors.white.withValues(alpha: 0.45 + 0.55 * f),
                                            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 6)],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    transform: Matrix4.translationValues(0, -32, 0),
                    decoration: BoxDecoration(
                      color: pal.bg,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
                      boxShadow: [
                        BoxShadow(
                          color: pal.shadow.withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: pal.textMuted.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Reveal(
                          child: Row(
                            children: [
                              Text(
                                p.brand,
                                style: context.text.labelMedium?.copyWith(color: pal.accent, letterSpacing: 2),
                              ),
                              const SizedBox(width: 8),
                              if (p.tag != null) Pill(p.tag!),
                              const Spacer(),
                              Icon(Icons.photo_library_outlined, size: 16, color: pal.textMuted),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Tap to zoom',
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.labelSmall?.copyWith(color: pal.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Reveal(
                          delay: Reveal.stagger(1),
                          child: Text(p.name, style: context.text.headlineMedium),
                        ),
                        const SizedBox(height: 10),
                        Reveal(
                          delay: Reveal.stagger(2),
                          child: Row(
                            children: [
                              RatingStars(rating: p.rating, size: 16),
                              const SizedBox(width: 6),
                              Text('${p.rating}', style: context.text.labelLarge),
                              Expanded(
                                child: Text(
                                  '  ·  ${p.reviews} reviews',
                                  overflow: TextOverflow.ellipsis,
                                  style: context.text.bodySmall?.copyWith(color: pal.textMuted),
                                ),
                              ),
                              if (p.stock < 8)
                                Pill(
                                  'Only ${p.stock} left',
                                  color: pal.warning,
                                  icon: Icons.local_fire_department_rounded,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Reveal(
                          delay: Reveal.stagger(3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (p.oldPrice != null)
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              money(p.oldPrice! * _qty),
                                              overflow: TextOverflow.ellipsis,
                                              style: context.text.titleMedium?.copyWith(
                                                color: pal.textMuted,
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Pill('SAVE ${p.discountPercent}%', color: pal.success),
                                        ],
                                      ),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedCount(
                                        value: p.price * _qty,
                                        prefix: '\$',
                                        style: context.text.displaySmall?.copyWith(fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              QtyStepper(value: _qty, onChanged: (v) => setState(() => _qty = v.clamp(1, 9))),
                            ],
                          ),
                        ),
                        if (p.swatches.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          Text('Finish', style: context.text.titleMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(p.swatches.length, (i) {
                              final on = i == _swatch;
                              return Pressable(
                                onTap: () => _selectSwatch(i),
                                child: AnimatedContainer(
                                  duration: Motion.medium,
                                  curve: Motion.emphasized,
                                  margin: const EdgeInsets.only(right: 14),
                                  padding: EdgeInsets.all(on ? 4 : 0),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: on ? pal.accent : Colors.transparent, width: 2),
                                  ),
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        center: const Alignment(-0.4, -0.4),
                                        colors: [Color.lerp(p.swatches[i], Colors.white, 0.35)!, p.swatches[i]],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: p.swatches[i].withValues(alpha: 0.5),
                                          blurRadius: on ? 14 : 4,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedOpacity(
                                      duration: Motion.fast,
                                      opacity: on ? 1 : 0,
                                      child: Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: p.swatches[i].computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                        if (p.sizes.isNotEmpty) ...[
                          const SizedBox(height: 26),
                          Row(
                            children: [
                              Text('Size', style: context.text.titleMedium),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => showComingSoon(
                                  context,
                                  title: 'Size guide',
                                  icon: Icons.straighten_rounded,
                                  body: 'Fit notes and measurements for ${p.name} are being prepared by the studio.',
                                ),
                                child: Text('Size guide', style: context.text.labelLarge?.copyWith(color: pal.accent)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: p.sizes.map((s) {
                              final on = s == _size;
                              return Pressable(
                                onTap: () => setState(() => _size = s),
                                child: AnimatedContainer(
                                  duration: Motion.medium,
                                  curve: Motion.emphasized,
                                  width: 54,
                                  height: 54,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: on ? pal.brandGradient : null,
                                    color: on ? null : pal.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: on ? Colors.transparent : pal.stroke),
                                    boxShadow: on
                                        ? [
                                            BoxShadow(
                                              color: pal.accent.withValues(alpha: 0.4),
                                              blurRadius: 14,
                                              offset: const Offset(0, 6),
                                            ),
                                          ]
                                        : const [],
                                  ),
                                  child: Text(
                                    s,
                                    style: context.text.titleSmall?.copyWith(
                                      color: on ? Colors.white : pal.textPrimary,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        const SizedBox(height: 26),
                        Text('Details', style: context.text.titleMedium),
                        const SizedBox(height: 8),
                        AnimatedCrossFade(
                          duration: Motion.medium,
                          sizeCurve: Motion.emphasized,
                          crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          firstChild: Text(
                            p.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.bodyMedium?.copyWith(color: pal.textSecondary, height: 1.6),
                          ),
                          secondChild: Text(
                            p.description,
                            style: context.text.bodyMedium?.copyWith(color: pal.textSecondary, height: 1.6),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _expanded = !_expanded),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Text(
                              _expanded ? 'Show less' : 'Read more',
                              style: context.text.labelLarge?.copyWith(color: pal.accent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            for (final (icon, label) in [
                              (Icons.local_shipping_outlined, 'Free express\nover \$250'),
                              (Icons.autorenew_rounded, '30-day\nreturns'),
                              (Icons.verified_user_outlined, '2-year\nwarranty'),
                            ])
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: pal.surface,
                                    borderRadius: BorderRadius.circular(Radii.md),
                                    border: Border.all(color: pal.stroke),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(icon, color: pal.accent),
                                      const SizedBox(height: 6),
                                      Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        style: context.text.labelSmall?.copyWith(color: pal.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _Reviews(product: p),
                        const SizedBox(height: 26),
                        Text('Sold by', style: context.text.titleMedium),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: pal.surface,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border.all(color: pal.stroke),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: pal.auroraGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.vendor, style: context.text.titleSmall),
                                    Text(
                                      'Verified vendor · 98% positive',
                                      style: context.text.bodySmall?.copyWith(color: pal.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.verified_rounded, color: pal.accent),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Plain flow layout: an earlier sliver paints *over* later ones,
                // so pulling this section upward hid its heading under "Sold by".
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 130), // clears the sticky purchase bar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader('You may also like'),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 270,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            physics: const BouncingScrollPhysics(),
                            itemCount: similar.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 14),
                            itemBuilder: (context, i) => ProductCard(
                              width: 172,
                              product: similar[i],
                              heroPrefix: 'sim-${p.id}',
                              onTap: () {
                                state.viewed(similar[i]);
                                Navigator.of(context).push(
                                  premiumRoute(ProductDetailScreen(product: similar[i], heroPrefix: 'sim-${p.id}')),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Top bar that gains a glass background as you scroll.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Stack(
                children: [
                  // Frosted backdrop fades in with the title so content never
                  // collides with the buttons while scrolling.
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: Motion.medium,
                        opacity: off > heroH * 0.6 ? 1 : 0,
                        child: const Glass(radius: 0, opacity: 0.78, child: SizedBox.expand()),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 8, 16, 10),
                    child: Row(
                      children: [
                        IconBubble(icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                        Expanded(
                          child: AnimatedOpacity(
                            duration: Motion.medium,
                            opacity: off > heroH * 0.6 ? 1 : 0,
                            child: Text(
                              p.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall,
                            ),
                          ),
                        ),
                        HeartButton(productId: p.id, size: 48),
                        const SizedBox(width: 10),
                        KeyedSubtree(
                          key: _cartKey,
                          child: IconBubble(
                            icon: Icons.shopping_bag_outlined,
                            badge: state.cartCount,
                            onTap: () => Navigator.of(context).push(premiumRoute(const CartScreen(standalone: true))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Sticky purchase bar
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.paddingOf(context).bottom + 16,
              child: Glass(
                radius: 34,
                opacity: 0.8,
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total', style: context.text.labelSmall?.copyWith(color: pal.textMuted)),
                          AnimatedCount(
                            value: p.price * _qty,
                            prefix: '\$',
                            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: KeyedSubtree(
                        key: _addKey,
                        child: GradientButton(label: 'Add to bag', icon: Icons.shopping_bag_rounded, onTap: _addToCart),
                      ),
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
}

class _Reviews extends StatelessWidget {
  const _Reviews({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final pal = context.palette;
    const dist = [0.78, 0.14, 0.05, 0.02, 0.01];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: context.text.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Column(
              children: [
                Text('${product.rating}', style: context.text.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
                RatingStars(rating: product.rating),
                const SizedBox(height: 4),
                Text('${product.reviews} ratings', style: context.text.labelSmall?.copyWith(color: pal.textMuted)),
              ],
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Column(
                children: List.generate(5, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Text('${5 - i}', style: context.text.labelSmall?.copyWith(color: pal.textMuted)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                Container(height: 6, color: pal.surfaceHigh),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: dist[i]),
                                  duration: Duration(milliseconds: 900 + i * 120),
                                  curve: Motion.emphasized,
                                  builder: (context, v, _) => FractionallySizedBox(
                                    widthFactor: v,
                                    child: Container(height: 6, decoration: BoxDecoration(gradient: pal.brandGradient)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final (name, text, r) in [
          ('Sofia M.', 'Absolutely stunning quality. The packaging alone felt like a luxury experience.', 5.0),
          ('James K.', 'Exceeded expectations — fast delivery and exactly as pictured.', 4.5),
        ])
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: pal.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: pal.stroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: pal.surfaceHigh,
                      child: Text(name[0], style: context.text.labelMedium),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(name, overflow: TextOverflow.ellipsis, style: context.text.labelLarge),
                    ),
                    RatingStars(rating: r, size: 12),
                  ],
                ),
                const SizedBox(height: 8),
                Text(text, style: context.text.bodySmall?.copyWith(color: pal.textSecondary, height: 1.5)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Fullscreen photo viewer: pinch to zoom, swipe between photos and
/// drag down to dismiss (the backdrop fades as you pull).
class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.product, required this.initial, required this.heroTag});
  final Product product;
  final int initial;
  final String heroTag;

  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _pc = PageController(initialPage: widget.initial);
  late int _index = widget.initial;
  double _drag = 0;
  bool _zoomed = false;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final count = math.max(1, p.photoCount);
    final fade = (1 - _drag.abs() / 400).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: fade),
      body: GestureDetector(
        onVerticalDragUpdate: _zoomed ? null : (d) => setState(() => _drag += d.delta.dy),
        onVerticalDragEnd: _zoomed
            ? null
            : (d) {
                if (_drag.abs() > 120 || d.velocity.pixelsPerSecond.dy.abs() > 900) {
                  Navigator.pop(context);
                } else {
                  setState(() => _drag = 0);
                }
              },
        child: Stack(
          children: [
            AnimatedContainer(
              duration: _drag == 0 ? Motion.medium : Duration.zero,
              curve: Motion.emphasized,
              transform: Matrix4.translationValues(0, _drag, 0)
                ..scaleByDouble(0.85 + 0.15 * fade, 0.85 + 0.15 * fade, 1, 1),
              transformAlignment: Alignment.center,
              child: PageView.builder(
                controller: _pc,
                physics: _zoomed ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                itemCount: count,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final photo = InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    onInteractionUpdate: (d) {
                      final z = d.scale > 1.01;
                      if (z != _zoomed) setState(() => _zoomed = z);
                    },
                    onInteractionEnd: (_) => setState(() => _zoomed = false),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: ProductPhoto(product: p, index: i, width: 900, fit: BoxFit.contain, vignette: false),
                      ),
                    ),
                  );
                  return i == widget.initial
                      ? Hero(
                          tag: widget.heroTag,
                          flightShuttleBuilder: (_, _, _, _, _) =>
                              ProductPhoto(product: p, index: i, width: 600, vignette: false),
                          child: photo,
                        )
                      : photo;
                },
              ),
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 16,
              right: 16,
              child: Opacity(
                opacity: fade,
                child: Row(
                  children: [
                    IconBubble(icon: Icons.close_rounded, color: Colors.white, onTap: () => Navigator.pop(context)),
                    const Spacer(),
                    Glass(
                      radius: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text(
                        '${_index + 1} / $count',
                        style: context.text.labelLarge?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 24,
              child: Opacity(
                opacity: fade,
                child: Text(
                  'Pinch to zoom · swipe down to close',
                  textAlign: TextAlign.center,
                  style: context.text.labelSmall?.copyWith(color: Colors.white60),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
