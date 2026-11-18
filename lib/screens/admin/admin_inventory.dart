import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../widgets/components.dart';
import '../../widgets/effects.dart';
import '../../widgets/product_visual.dart';

class AdminInventory extends StatefulWidget {
  const AdminInventory({super.key});

  @override
  State<AdminInventory> createState() => _AdminInventoryState();
}

class _AdminInventoryState extends State<AdminInventory> {
  final Map<String, int> _stock = {for (final p in MockData.products) p.id: p.stock};
  final Set<String> _hidden = {};
  String _q = '';

  void _openAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final p = context.palette;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Glass(
            radius: Radii.xl,
            opacity: 0.94,
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
                Text('New product', style: context.text.headlineSmall),
                const SizedBox(height: 18),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: p.accent.withValues(alpha: 0.5)),
                    color: p.accent.withValues(alpha: 0.06),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: p.accent, size: 32),
                        const SizedBox(height: 6),
                        Text('Upload images or 3D model', style: context.text.labelLarge?.copyWith(color: p.accent)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const TextField(decoration: InputDecoration(hintText: 'Product name')),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: 'Price'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(hintText: 'Stock'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                GradientButton(
                  label: 'Publish product',
                  icon: Icons.rocket_launch_rounded,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(
                      this.context,
                    ).showSnackBar(const SnackBar(content: Text('Product saved as draft (demo)')));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final items = MockData.products
        .where((x) => _q.isEmpty || x.name.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    final totalUnits = _stock.values.fold(0, (a, b) => a + b);
    return Column(
      children: [
        TopBar(
          title: 'Inventory',
          subtitle: '${MockData.products.length} products · $totalUnits units',
          showBack: false,
          actions: [IconBubble(icon: Icons.add_rounded, onTap: _openAdd)],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search inventory',
              prefixIcon: Icon(Icons.search_rounded, color: p.textMuted),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
            itemCount: items.length,
            itemBuilder: (context, i) => Reveal(
              key: ValueKey(items[i].id),
              delay: Reveal.stagger(i, ms: 45),
              child: _InventoryTile(
                product: items[i],
                stock: _stock[items[i].id]!,
                active: !_hidden.contains(items[i].id),
                onStock: (v) => setState(() => _stock[items[i].id] = v.clamp(0, 999)),
                onActive: (v) => setState(() => v ? _hidden.remove(items[i].id) : _hidden.add(items[i].id)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.product,
    required this.stock,
    required this.active,
    required this.onStock,
    required this.onActive,
  });
  final Product product;
  final int stock;
  final bool active;
  final ValueChanged<int> onStock;
  final ValueChanged<bool> onActive;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final level = (stock / 30).clamp(0.0, 1.0);
    final color = stock < 5 ? p.danger : (stock < 10 ? p.warning : p.success);
    return AnimatedOpacity(
      duration: Motion.medium,
      opacity: active ? 1 : 0.5,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.lg),
          border: Border.all(color: p.stroke),
        ),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: ProductPhoto(product: product, width: 60, radius: 16, vignette: false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                      Text(
                        'SKU ${product.id.toUpperCase()}-${product.brand.substring(0, 3)} · ${money(product.price)}',
                        style: context.text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: active,
                  activeTrackColor: p.accent,
                  onChanged: (v) {
                    HapticFeedback.selectionClick();
                    onActive(v);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Stock', style: context.text.labelSmall?.copyWith(color: p.textMuted)),
                          const SizedBox(width: 6),
                          AnimatedSwitcher(
                            duration: Motion.fast,
                            child: Text(
                              '$stock',
                              key: ValueKey(stock),
                              style: context.text.labelLarge?.copyWith(color: color),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LayoutBuilder(
                        builder: (context, c) => Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(color: p.surfaceHigh, borderRadius: BorderRadius.circular(6)),
                            ),
                            AnimatedContainer(
                              duration: Motion.slow,
                              curve: Motion.emphasized,
                              height: 6,
                              width: c.maxWidth * level,
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                QtyStepper(compact: true, value: stock, onChanged: onStock),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
