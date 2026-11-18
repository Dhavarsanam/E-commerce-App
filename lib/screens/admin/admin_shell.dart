import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/effects.dart';
import '../../widgets/nav_bar.dart';
import 'admin_dashboard.dart';
import 'admin_inventory.dart';
import 'admin_orders.dart';

/// Vendor / admin console: sales analytics, inventory and fulfilment.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [AdminDashboard(), AdminInventory(), AdminOrders()];
    return Scaffold(
      extendBody: true,
      body: AuroraBackground(
        intensity: 0.45,
        child: AnimatedSwitcher(
          duration: Motion.medium,
          switchInCurve: Motion.emphasized,
          transitionBuilder: (c, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.97, end: 1.0).animate(a), child: c),
          ),
          child: KeyedSubtree(key: ValueKey(_i), child: pages[_i]),
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        index: _i,
        onChanged: (i) => setState(() => _i = i),
        items: const [
          NavItem(Icons.space_dashboard_outlined, Icons.space_dashboard_rounded, 'Overview'),
          NavItem(Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Inventory'),
          NavItem(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Orders', badge: 2),
        ],
      ),
    );
  }
}
