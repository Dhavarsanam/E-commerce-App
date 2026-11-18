import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/charts.dart';
import '../../widgets/components.dart';
import '../../widgets/effects.dart';
import '../../widgets/product_visual.dart';
import '../main_shell.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _range = 1;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = AppScope.of(context).userName ?? 'Admin';
    final mult = [0.25, 1.0, 3.1][_range];
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 12, 16, 130),
      children: [
        Reveal(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vendor console',
                      style: context.text.bodySmall?.copyWith(color: p.textMuted, letterSpacing: 1.2),
                    ),
                    GradientText('Hello, $name', style: context.text.headlineMedium),
                  ],
                ),
              ),
              IconBubble(
                icon: Icons.storefront_rounded,
                onTap: () => Navigator.of(context).pushAndRemoveUntil(premiumRoute(const MainShell()), (_) => false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Reveal(
          delay: Reveal.stagger(1),
          child: _RangeTabs(
            index: _range,
            labels: const ['Week', 'Month', 'Quarter'],
            onChanged: (i) => setState(() => _range = i),
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          padding: EdgeInsets.zero, // don't inherit safe-area padding (caused a gap)
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: [
            _Kpi(
              i: 0,
              label: 'Revenue',
              value: 128450 * mult,
              prefix: '\$',
              delta: 18.2,
              icon: Icons.payments_rounded,
              color: p.accent,
            ),
            _Kpi(
              i: 1,
              label: 'Orders',
              value: 1842 * mult,
              delta: 9.4,
              icon: Icons.shopping_bag_rounded,
              color: p.accent2,
            ),
            _Kpi(
              i: 2,
              label: 'Conversion',
              value: 4.8,
              suffix: '%',
              decimals: 1,
              delta: 0.6,
              icon: Icons.trending_up_rounded,
              color: p.success,
            ),
            _Kpi(
              i: 3,
              label: 'Avg. order',
              value: 69.7,
              prefix: '\$',
              decimals: 1,
              delta: -2.1,
              icon: Icons.receipt_rounded,
              color: p.accent3,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: Reveal.stagger(5),
          child: _Panel(
            title: 'Revenue',
            trailing: Pill('+18.2%', color: p.success, icon: Icons.arrow_upward_rounded),
            child: AreaChart(key: ValueKey(_range), values: MockData.revenue.map((v) => v * mult).toList()),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: Reveal.stagger(6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _Panel(
                  title: 'By weekday',
                  child: BarChart(
                    key: ValueKey('b$_range'),
                    values: MockData.weekdaySales,
                    labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
                    height: 150,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: Reveal.stagger(7),
          child: _Panel(
            title: 'Sales by category',
            child: Row(
              children: [
                DonutChart(
                  key: ValueKey('d$_range'),
                  size: 140,
                  segments: [
                    DonutSegment('Tech', 42, p.accent),
                    DonutSegment('Fashion', 24, p.accent2),
                    DonutSegment('Watches', 18, p.gold),
                    DonutSegment('Home', 16, p.success),
                  ],
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedCount(value: 1842 * mult, style: context.text.titleLarge),
                      Text('units', style: context.text.labelSmall?.copyWith(color: p.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (final (l, v, c) in [
                        ('Tech', 42, p.accent),
                        ('Fashion', 24, p.accent2),
                        ('Watches', 18, p.gold),
                        ('Home', 16, p.success),
                      ])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(l, style: context.text.bodySmall)),
                              Text('$v%', style: context.text.labelLarge),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: Reveal.stagger(8),
          child: _Panel(
            title: 'Top products',
            child: Column(
              children: [
                for (final (i, prod) in MockData.products.take(4).indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Text('${i + 1}', style: context.text.titleMedium?.copyWith(color: p.textMuted)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 46,
                          height: 46,
                          child: ProductPhoto(product: prod, width: 46, radius: 12, vignette: false),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod.name, style: context.text.titleSmall, overflow: TextOverflow.ellipsis),
                              Text(
                                '${(prod.reviews * 0.4 * mult).round()} sold',
                                style: context.text.bodySmall?.copyWith(color: p.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(compactMoney(prod.price * prod.reviews * 0.4 * mult), style: context.text.titleSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delay: Reveal.stagger(9),
          child: _Panel(
            title: 'Low stock alerts',
            trailing: Pill('${MockData.products.where((x) => x.stock < 8).length}', color: p.warning),
            child: Column(
              children: [
                for (final prod in MockData.products.where((x) => x.stock < 8))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.warning_amber_rounded, color: p.warning),
                    title: Text(prod.name, style: context.text.titleSmall),
                    subtitle: Text(
                      '${prod.stock} units left',
                      style: context.text.bodySmall?.copyWith(color: p.textMuted),
                    ),
                    trailing: TextButton(
                      onPressed: () => showComingSoon(
                        context,
                        title: 'Restock ${prod.name}',
                        icon: Icons.local_shipping_rounded,
                        body: 'Purchase orders to suppliers will be raised from here once inventory sync is live.',
                      ),
                      child: Text('Restock', style: TextStyle(color: p.accent)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeTabs extends StatelessWidget {
  const _RangeTabs({required this.index, required this.labels, required this.onChanged});
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      radius: 18,
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: 40,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth / labels.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: Motion.slow,
                  curve: Motion.emphasized,
                  left: index * w,
                  width: w,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(gradient: p.brandGradient, borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.medium,
                              style: context.text.labelLarge!.copyWith(color: i == index ? Colors.white : p.textMuted),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.i,
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.color,
    this.prefix = '',
    this.suffix = '',
    this.decimals = 0,
  });
  final int i;
  final String label;
  final double value;
  final double delta;
  final IconData icon;
  final Color color;
  final String prefix;
  final String suffix;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final up = delta >= 0;
    return Reveal(
      delay: Reveal.stagger(i + 2, ms: 70),
      child: TiltCard(
        maxTilt: 0.14,
        child: Container(
          padding: const EdgeInsets.all(14),
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
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const Spacer(),
                  Sparkline(values: MockData.revenue.sublist(i, i + 7), color: color, width: 54, height: 22),
                ],
              ),
              const Spacer(),
              FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: AnimatedCount(
                  value: value,
                  prefix: prefix,
                  suffix: suffix,
                  decimals: decimals,
                  style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(color: p.textMuted),
                    ),
                  ),
                  Icon(
                    up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                    size: 12,
                    color: up ? p.success : p.danger,
                  ),
                  Text('${delta.abs()}%', style: context.text.labelSmall?.copyWith(color: up ? p.success : p.danger)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(18),
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
              Text(title, style: context.text.titleMedium),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Status colour helper shared by admin screens.
Color statusColor(BuildContext context, OrderStatus s) {
  final p = context.palette;
  return switch (s) {
    OrderStatus.placed => p.accent3,
    OrderStatus.packed => p.warning,
    OrderStatus.shipped => p.accent,
    OrderStatus.outForDelivery => p.accent2,
    OrderStatus.delivered => p.success,
  };
}
