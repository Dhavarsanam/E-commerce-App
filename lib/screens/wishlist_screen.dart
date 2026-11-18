import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import 'home_screen.dart';
import 'main_shell.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = MockData.products.where((p) => state.isWished(p.id)).toList();
    return Column(
      children: [
        TopBar(
          title: 'Saved',
          subtitle: '${items.length} piece${items.length == 1 ? '' : 's'} you love',
          showBack: false,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.slow,
            child: items.isEmpty
                ? EmptyState(
                    key: const ValueKey('empty'),
                    icon: Icons.favorite_border_rounded,
                    title: 'Nothing saved yet',
                    body: 'Tap the heart on anything you love to keep it here.',
                    action: 'Explore products',
                    onAction: () => MainShell.goTo(context, 1),
                  )
                : GridView.builder(
                    key: const ValueKey('grid'),
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.64,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) => Reveal(
                      key: ValueKey(items[i].id),
                      delay: Reveal.stagger(i),
                      child: ProductCard(
                        product: items[i],
                        heroPrefix: 'wish',
                        onTap: () => openProduct(context, items[i], heroPrefix: 'wish'),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
