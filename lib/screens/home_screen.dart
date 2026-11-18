import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import '../widgets/product_visual.dart';
import 'notifications_screen.dart';
import 'product_detail_screen.dart';

void openProduct(BuildContext context, Product p, {String heroPrefix = 'grid'}) {
  AppScope.read(context).viewed(p);
  Navigator.of(context).push(premiumRoute(ProductDetailScreen(product: p, heroPrefix: heroPrefix)));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSearch});
  final VoidCallback onSearch;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scroll = ScrollController();
  String _cat = 'all';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() => setState(() {}));
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final products = _cat == 'all'
        ? state.recommendations
        : MockData.products.where((x) => x.categoryId == _cat).toList();

    return Stack(
      children: [
        CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: top + 76)),
            SliverToBoxAdapter(
              child: Reveal(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Pressable(
                    onTap: widget.onSearch,
                    scale: 0.98,
                    child: Glass(
                      radius: Radii.md,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: p.textMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text('Search 12,000+ products', style: TextStyle(color: p.textMuted)),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: p.brandGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            SliverToBoxAdapter(
              child: Reveal(
                delay: Reveal.stagger(1),
                child: _HeroCarousel(parallax: offset),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 26)),
            SliverToBoxAdapter(
              child: Reveal(
                delay: Reveal.stagger(2),
                child: _CategoryStrip(selected: _cat, onSelect: (c) => setState(() => _cat = c)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Reveal(delay: Reveal.stagger(3), child: const _FlashSale()),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: SectionHeader(
                _cat == 'all' ? 'Picked for you' : MockData.categories.firstWhere((c) => c.id == _cat).name,
                subtitle: _cat == 'all' ? 'Based on what you love' : '${products.length} curated pieces',
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 14)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.64,
                ),
                delegate: SliverChildBuilderDelegate((context, i) {
                  if (_loading) return const _SkeletonCard();
                  final prod = products[i];
                  return Reveal(
                    key: ValueKey('$_cat-${prod.id}'),
                    delay: Reveal.stagger(i % 6, ms: 70),
                    child: ProductCard(
                      product: prod,
                      heroPrefix: 'home',
                      onTap: () => openProduct(context, prod, heroPrefix: 'home'),
                    ),
                  );
                }, childCount: _loading ? 4 : products.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 130)),
          ],
        ),
        // Collapsing glass header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _Header(scrolled: offset > 10, unread: state.unread, name: state.userName ?? 'Guest'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scrolled, required this.unread, required this.name});
  final bool scrolled;
  final int unread;
  final String name;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' : (hour < 18 ? 'Good afternoon' : 'Good evening');
    final content = Padding(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 10, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(shape: BoxShape.circle, gradient: p.auroraGradient),
            child: CircleAvatar(
              radius: 21,
              backgroundColor: p.surfaceHigh,
              child: Text(name[0], style: context.text.titleMedium),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greet, style: context.text.bodySmall?.copyWith(color: p.textMuted)),
                Text('$name ✦', style: context.text.titleLarge),
              ],
            ),
          ),
          IconBubble(
            icon: Icons.notifications_none_rounded,
            badge: unread,
            onTap: () => Navigator.of(context).push(premiumRoute(const NotificationsScreen())),
          ),
        ],
      ),
    );
    return AnimatedContainer(
      duration: Motion.medium,
      decoration: BoxDecoration(
        boxShadow: scrolled ? [BoxShadow(color: p.shadow.withValues(alpha: 0.2), blurRadius: 20)] : const [],
      ),
      child: scrolled ? Glass(radius: 0, opacity: 0.7, child: content) : content,
    );
  }
}

/// 3D cover-flow banners with auto-advance and parallax product art.
class _HeroCarousel extends StatefulWidget {
  const _HeroCarousel({required this.parallax});
  final double parallax;

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  final _pc = PageController(viewportFraction: 0.86, initialPage: 1000);
  double _page = 1000;
  Timer? _timer;

  static final _banners = [
    ('Midnight Drop', 'Up to 40% off\nstudio audio', 'p1'),
    ('Timeless', 'The Chrono\ncollection', 'p3'),
    ('Run further', 'Phantom X is\nfinally here', 'p2'),
  ];

  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _page = _pc.page ?? _page));
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pc.hasClients) _pc.nextPage(duration: const Duration(milliseconds: 900), curve: Motion.emphasized);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      children: [
        SizedBox(
          height: 228,
          child: PageView.builder(
            controller: _pc,
            itemBuilder: (context, index) {
              final i = index % _banners.length;
              final (eyebrow, title, pid) = _banners[i];
              final prod = MockData.byId(pid);
              final delta = (_page - index).clamp(-1.0, 1.0);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(delta * 0.45)
                  ..scaleByDouble(1 - delta.abs() * 0.1, 1 - delta.abs() * 0.1, 1, 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Pressable(
                    scale: 0.98,
                    onTap: () => openProduct(context, prod, heroPrefix: 'banner$index'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.xl),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Hero(
                              tag: 'banner$index-${prod.id}',
                              // Photo slides against the card as it rotates (parallax depth).
                              child: ProductPhoto(
                                product: prod,
                                width: 420,
                                radius: Radii.xl,
                                alignment: Alignment(delta.clamp(-1.0, 1.0), (widget.parallax / 400).clamp(-1.0, 1.0)),
                                kenBurns: delta.abs() < 0.01,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.72),
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                  stops: const [0, 0.5, 0.85],
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(22),
                            child: Transform.translate(
                              offset: Offset(delta * -40, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Pill(
                                    eyebrow.toUpperCase(),
                                    color: Colors.white.withValues(alpha: 0.22),
                                    filled: true,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.text.headlineSmall?.copyWith(color: Colors.white, height: 1.15),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Shop now', style: context.text.labelLarge?.copyWith(color: Colors.black)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.arrow_outward_rounded, size: 16, color: Colors.black),
                                      ],
                                    ),
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
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (i) {
            final cur = _page % _banners.length;
            var d = (cur - i).abs();
            d = math.min(d, _banners.length - d);
            final f = (1 - d).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6 + 18 * f,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Color.lerp(p.textMuted.withValues(alpha: 0.4), p.accent, f),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.selected, required this.onSelect});
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemCount: MockData.categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = MockData.categories[i];
          final on = c.id == selected;
          return Pressable(
            onTap: () => onSelect(c.id),
            child: Column(
              children: [
                AnimatedContainer(
                  duration: Motion.slow,
                  curve: Motion.emphasized,
                  width: 64,
                  height: 64,
                  transform: Matrix4.translationValues(0, on ? -4 : 0, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: on
                        ? LinearGradient(colors: c.colors, begin: Alignment.topLeft, end: Alignment.bottomRight)
                        : null,
                    color: on ? null : p.surface,
                    border: Border.all(color: on ? Colors.transparent : p.stroke),
                    boxShadow: on
                        ? [
                            BoxShadow(
                              color: c.colors.first.withValues(alpha: 0.5),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : const [],
                  ),
                  child: Icon(c.icon, color: on ? Colors.white : p.textSecondary, size: 26),
                ),
                const SizedBox(height: 8),
                AnimatedDefaultTextStyle(
                  duration: Motion.medium,
                  style: context.text.labelMedium!.copyWith(
                    color: on ? p.textPrimary : p.textMuted,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(c.name),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FlashSale extends StatefulWidget {
  const _FlashSale();

  @override
  State<_FlashSale> createState() => _FlashSaleState();
}

class _FlashSaleState extends State<_FlashSale> {
  late final DateTime _end = DateTime.now().add(const Duration(hours: 5, minutes: 42, seconds: 18));
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final left = _end.difference(DateTime.now());
    final parts = [left.inHours, left.inMinutes % 60, left.inSeconds % 60];
    final sale = MockData.products.where((x) => x.oldPrice != null).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.bolt_rounded, color: p.accent3),
              const SizedBox(width: 4),
              Expanded(
                child: Text('Flash sale', overflow: TextOverflow.ellipsis, style: context.text.titleLarge),
              ),
              for (var i = 0; i < 3; i++) ...[
                _FlipDigit(value: parts[i].toString().padLeft(2, '0')),
                if (i < 2)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(':', style: context.text.titleMedium?.copyWith(color: p.accent2)),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sale.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => Stack(
              children: [
                ProductCard(
                  width: 172,
                  product: sale[i],
                  heroPrefix: 'flash',
                  onTap: () => openProduct(context, sale[i], heroPrefix: 'flash'),
                ),
                Positioned(
                  left: 16,
                  bottom: 78,
                  child: Pill('-${sale[i].discountPercent}%', color: p.accent2, filled: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FlipDigit extends StatelessWidget {
  const _FlipDigit({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 34,
      height: 32,
      decoration: BoxDecoration(
        color: p.surfaceHigh,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: p.stroke),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: Motion.medium,
        transitionBuilder: (child, a) {
          final inbound = child.key == ValueKey(value);
          return AnimatedBuilder(
            animation: a,
            child: child,
            builder: (context, c) {
              final angle = (1 - a.value) * (math.pi / 2) * (inbound ? -1 : 1);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.006)
                  ..rotateX(angle),
                child: Opacity(opacity: a.value, child: c),
              );
            },
          );
        },
        child: Center(
          key: ValueKey(value),
          child: Text(
            value,
            style: context.text.titleSmall?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(color: p.surfaceHigh, borderRadius: BorderRadius.circular(8)),
    );
    return Shimmer(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: p.surface, borderRadius: BorderRadius.circular(Radii.lg)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: p.surfaceHigh, borderRadius: BorderRadius.circular(Radii.md)),
              ),
            ),
            const SizedBox(height: 12),
            bar(50, 10),
            const SizedBox(height: 8),
            bar(110, 14),
            const SizedBox(height: 8),
            bar(70, 16),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
