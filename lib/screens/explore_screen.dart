import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import 'home_screen.dart';

enum SortBy { relevance, priceLow, priceHigh, rating }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _q = TextEditingController();
  final _focus = FocusNode();
  String _cat = 'all';
  RangeValues _price = const RangeValues(0, 1500);
  SortBy _sort = SortBy.relevance;
  final _recent = ['headphones', 'chrono', 'runner', 'serum'];

  @override
  void initState() {
    super.initState();
    _q.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  List<Product> get _results {
    final q = _q.text.trim().toLowerCase();
    final list = MockData.products.where((p) {
      final matchQ =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.brand.toLowerCase().contains(q) ||
          p.categoryId.contains(q);
      final matchC = _cat == 'all' || p.categoryId == _cat;
      final matchP = p.price >= _price.start && p.price <= _price.end;
      return matchQ && matchC && matchP;
    }).toList();
    switch (_sort) {
      case SortBy.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
      case SortBy.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
      case SortBy.rating:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case SortBy.relevance:
        break;
    }
    return list;
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          final p = context.palette;
          void both(VoidCallback f) {
            setSheet(f);
            setState(() {});
          }

          return Glass(
            radius: Radii.xl,
            opacity: 0.92,
            padding: EdgeInsets.fromLTRB(24, 14, 24, MediaQuery.paddingOf(context).bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: p.textMuted, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Filters', style: context.text.headlineSmall),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text('Price range', style: context.text.titleMedium),
                    const Spacer(),
                    Text(
                      '${money(_price.start)} – ${money(_price.end)}',
                      style: context.text.labelLarge?.copyWith(color: p.accent),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: p.accent,
                    inactiveTrackColor: p.surfaceHigh,
                    thumbColor: Colors.white,
                    overlayColor: p.accent.withValues(alpha: 0.2),
                    trackHeight: 5,
                  ),
                  child: RangeSlider(
                    values: _price,
                    min: 0,
                    max: 1500,
                    divisions: 30,
                    onChanged: (v) => both(() => _price = v),
                  ),
                ),
                const SizedBox(height: 14),
                Text('Sort by', style: context.text.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final (s, label) in [
                      (SortBy.relevance, 'Relevance'),
                      (SortBy.priceLow, 'Price: Low → High'),
                      (SortBy.priceHigh, 'Price: High → Low'),
                      (SortBy.rating, 'Top rated'),
                    ])
                      _Chip(label: label, on: _sort == s, onTap: () => both(() => _sort = s)),
                  ],
                ),
                const SizedBox(height: 28),
                GradientButton(label: 'Show ${_results.length} results', onTap: () => Navigator.pop(context)),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final results = _results;
    final searching = _focus.hasFocus && _q.text.isEmpty;
    return Column(
      children: [
        const TopBar(title: 'Explore', showBack: false),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: Motion.medium,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.md),
                    boxShadow: _focus.hasFocus
                        ? [BoxShadow(color: p.accent.withValues(alpha: 0.3), blurRadius: 20)]
                        : const [],
                  ),
                  child: TextField(
                    controller: _q,
                    focusNode: _focus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty && !_recent.contains(v.trim())) {
                        setState(() => _recent.insert(0, v.trim()));
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Search products, brands…',
                      prefixIcon: Icon(Icons.search_rounded, color: _focus.hasFocus ? p.accent : p.textMuted),
                      suffixIcon: _q.text.isEmpty
                          ? Icon(Icons.mic_none_rounded, color: p.textMuted)
                          : IconButton(
                              onPressed: _q.clear,
                              icon: Icon(Icons.close_rounded, color: p.textMuted),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Pressable(
                onTap: _openFilters,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: p.brandGradient,
                    borderRadius: BorderRadius.circular(Radii.md),
                    boxShadow: [
                      BoxShadow(color: p.accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: const Icon(Icons.tune_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              for (final c in MockData.categories)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Chip(label: c.name, icon: c.icon, on: _cat == c.id, onTap: () => setState(() => _cat = c.id)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: Motion.medium,
          curve: Motion.emphasized,
          child: searching
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent searches', style: context.text.labelLarge?.copyWith(color: p.textMuted)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final r in _recent)
                            ActionChip(
                              avatar: Icon(Icons.history_rounded, size: 16, color: p.textMuted),
                              label: Text(r),
                              backgroundColor: p.surface,
                              side: BorderSide(color: p.stroke),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              onPressed: () {
                                _q.text = r;
                                _q.selection = TextSelection.collapsed(offset: r.length);
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: Motion.medium,
                child: Text(
                  '${results.length} results',
                  key: ValueKey(results.length),
                  style: context.text.labelLarge?.copyWith(color: p.textSecondary),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.medium,
            child: results.isEmpty
                ? const EmptyState(
                    key: ValueKey('none'),
                    icon: Icons.search_off_rounded,
                    title: 'Nothing found',
                    body: 'Try a different keyword or widen your filters.',
                  )
                : GridView.builder(
                    key: ValueKey('$_cat-${_sort.name}-${_q.text}-${_price.start}-${_price.end}'),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 130),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.64,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, i) => Reveal(
                      delay: Reveal.stagger(i % 8, ms: 50),
                      child: ProductCard(
                        product: results[i],
                        heroPrefix: 'explore',
                        onTap: () => openProduct(context, results[i], heroPrefix: 'explore'),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.on, required this.onTap, this.icon});
  final String label;
  final bool on;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: on ? p.brandGradient : null,
          color: on ? null : p.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: on ? Colors.transparent : p.stroke),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: on ? Colors.white : p.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(label, style: context.text.labelLarge?.copyWith(color: on ? Colors.white : p.textSecondary)),
          ],
        ),
      ),
    );
  }
}
