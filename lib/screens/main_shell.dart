import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/effects.dart';
import '../widgets/nav_bar.dart';
import 'cart_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

/// Root of the shopper experience. Tabs stay alive and cross-fade with a
/// subtle depth zoom when switching.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static void goTo(BuildContext context, int tab) => context.findAncestorStateOfType<_MainShellState>()?._go(tab);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final pages = [
      HomeScreen(onSearch: () => _go(1)),
      const ExploreScreen(),
      const WishlistScreen(),
      const CartScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      extendBody: true,
      body: AuroraBackground(
        intensity: 0.6,
        child: Stack(
          children: [
            for (var i = 0; i < pages.length; i++)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: i != _index,
                  // The fade/scale must sit OUTSIDE TickerMode: muting tickers
                  // around them froze the outgoing tab's fade-out, leaving it
                  // visible underneath the new tab.
                  child: AnimatedOpacity(
                    duration: Motion.medium,
                    curve: Motion.smooth,
                    opacity: i == _index ? 1 : 0,
                    child: AnimatedScale(
                      duration: Motion.slow,
                      curve: Motion.emphasized,
                      scale: i == _index ? 1 : 0.97,
                      child: TickerMode(enabled: i == _index, child: pages[i]),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: FloatingNavBar(
        index: _index,
        onChanged: _go,
        items: [
          const NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
          const NavItem(Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
          NavItem(Icons.favorite_border_rounded, Icons.favorite_rounded, 'Saved', badge: state.wishlist.length),
          NavItem(Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Bag', badge: state.cartCount),
          const NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Me'),
        ],
      ),
    );
  }
}
