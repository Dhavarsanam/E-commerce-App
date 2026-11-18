import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../widgets/components.dart';
import '../../widgets/effects.dart';
import 'admin_dashboard.dart';

class AdminOrders extends StatefulWidget {
  const AdminOrders({super.key});

  @override
  State<AdminOrders> createState() => _AdminOrdersState();
}

class _AdminOrdersState extends State<AdminOrders> {
  OrderStatus? _filter;

  void _advance(Order o) {
    if (o.status == OrderStatus.delivered) return;
    HapticFeedback.mediumImpact();
    setState(() => o.status = OrderStatus.values[o.status.index + 1]);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('${o.id} → ${o.status.label}. Customer notified.')));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final orders = MockData.adminOrders.where((o) => _filter == null || o.status == _filter).toList();
    return Column(
      children: [
        TopBar(title: 'Orders', subtitle: 'Swipe right to advance status', showBack: false),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            children: [
              _FilterChip(
                label: 'All',
                on: _filter == null,
                color: p.accent,
                onTap: () => setState(() => _filter = null),
              ),
              for (final s in OrderStatus.values)
                _FilterChip(
                  label: s.label,
                  on: _filter == s,
                  color: statusColor(context, s),
                  onTap: () => setState(() => _filter = s),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.medium,
            child: orders.isEmpty
                ? const EmptyState(
                    key: ValueKey('e'),
                    icon: Icons.inbox_rounded,
                    title: 'No orders here',
                    body: 'Orders in this stage will appear here.',
                  )
                : ListView.builder(
                    key: ValueKey(_filter),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 130),
                    itemCount: orders.length,
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      final c = statusColor(context, o.status);
                      return Reveal(
                        delay: Reveal.stagger(i),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Dismissible(
                            key: ValueKey('${o.id}-${o.status.index}'),
                            direction: o.status == OrderStatus.delivered
                                ? DismissDirection.none
                                : DismissDirection.startToEnd,
                            confirmDismiss: (_) async {
                              _advance(o);
                              return false; // keep the row; it just changes status
                            },
                            background: Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [p.success, p.success.withValues(alpha: 0)]),
                                borderRadius: BorderRadius.circular(Radii.lg),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fast_forward_rounded, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Advance',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: BorderRadius.circular(Radii.lg),
                                border: Border.all(color: p.stroke),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: c.withValues(alpha: 0.15),
                                    child: Text(o.customer[0], style: context.text.titleMedium?.copyWith(color: c)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(o.customer, style: context.text.titleSmall),
                                        Text(
                                          '${o.id} · ${o.items.first.product.name}${o.items.first.qty > 1 ? ' ×${o.items.first.qty}' : ''}',
                                          overflow: TextOverflow.ellipsis,
                                          style: context.text.bodySmall?.copyWith(color: p.textMuted),
                                        ),
                                        const SizedBox(height: 8),
                                        AnimatedSwitcher(
                                          duration: Motion.medium,
                                          transitionBuilder: (w, a) => ScaleTransition(
                                            scale: a,
                                            child: FadeTransition(opacity: a, child: w),
                                          ),
                                          child: Pill(
                                            o.status.label,
                                            key: ValueKey(o.status),
                                            color: c,
                                            icon: o.status.icon,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    money(o.total),
                                    style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.on, required this.color, required this.onTap});
  final String label;
  final bool on;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.medium,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: on ? color : p.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: on ? Colors.transparent : p.stroke),
            boxShadow: on
                ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                : const [],
          ),
          child: Text(
            label,
            style: context.text.labelLarge?.copyWith(
              // Dark text on light fills (e.g. the yellow "Packed" chip) for contrast.
              color: on ? (color.computeLuminance() > 0.35 ? Colors.black87 : Colors.white) : p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
