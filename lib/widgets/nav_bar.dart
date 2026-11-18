import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'effects.dart';

class NavItem {
  const NavItem(this.icon, this.activeIcon, this.label, {this.badge = 0});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int badge;
}

/// Floating glass dock with a liquid gradient indicator that slides
/// and stretches between tabs.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key, required this.items, required this.index, required this.onChanged});
  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottom > 0 ? bottom : 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: p.shadow.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: Glass(
          radius: 32,
          blur: 28,
          opacity: context.isDark ? 0.72 : 0.82,
          child: SizedBox(
            height: 70,
            child: LayoutBuilder(
              builder: (context, c) {
                final w = c.maxWidth / items.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: Motion.slow,
                      curve: Motion.emphasized,
                      left: index * w + 8,
                      top: 10,
                      width: w - 16,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: p.brandGradient,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: p.accent.withValues(alpha: 0.55),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: List.generate(items.length, (i) {
                        final it = items[i];
                        final active = i == index;
                        return Expanded(
                          child: Pressable(
                            onTap: () => onChanged(i),
                            scale: 0.85,
                            child: SizedBox(
                              height: 70,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      AnimatedSwitcher(
                                        duration: Motion.medium,
                                        transitionBuilder: (c, a) => ScaleTransition(
                                          scale: CurvedAnimation(parent: a, curve: Motion.spring),
                                          child: c,
                                        ),
                                        child: Icon(
                                          active ? it.activeIcon : it.icon,
                                          key: ValueKey(active),
                                          size: 24,
                                          color: active ? Colors.white : p.textSecondary,
                                        ),
                                      ),
                                      if (it.badge > 0)
                                        Positioned(
                                          right: -8,
                                          top: -6,
                                          child: TweenAnimationBuilder<double>(
                                            key: ValueKey(it.badge),
                                            tween: Tween(begin: 0.4, end: 1),
                                            duration: Motion.slow,
                                            curve: Motion.spring,
                                            builder: (context, s, child) => Transform.scale(scale: s, child: child),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: active ? Colors.white : p.accent2,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${it.badge}',
                                                style: TextStyle(
                                                  color: active ? p.accent2 : Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  AnimatedSize(
                                    duration: Motion.medium,
                                    curve: Motion.emphasized,
                                    child: active
                                        ? Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              it.label,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          )
                                        : const SizedBox(width: 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
