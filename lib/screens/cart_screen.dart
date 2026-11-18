import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import '../widgets/product_visual.dart';
import 'checkout_screen.dart';
import 'home_screen.dart';
import 'main_shell.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, this.standalone = false});

  /// True when pushed as its own route (from product detail).
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    final body = Column(
      children: [
        TopBar(
          title: 'Your bag',
          subtitle: '${state.cartCount} item${state.cartCount == 1 ? '' : 's'}',
          showBack: standalone,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.slow,
            child: state.cart.isEmpty
                ? EmptyState(
                    key: const ValueKey('empty'),
                    icon: Icons.shopping_bag_outlined,
                    title: 'Your bag is empty',
                    body: 'Discover pieces you\'ll love and they\'ll appear here.',
                    action: 'Start shopping',
                    onAction: () {
                      if (standalone) {
                        Navigator.pop(context);
                      } else {
                        MainShell.goTo(context, 0);
                      }
                    },
                  )
                : ListView(
                    key: const ValueKey('list'),
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 8, 16, standalone ? 40 : 130),
                    children: [
                      for (var i = 0; i < state.cart.length; i++)
                        Reveal(
                          key: ObjectKey(state.cart[i]),
                          delay: Reveal.stagger(i),
                          axis: Axis.horizontal,
                          child: _CartTile(item: state.cart[i], index: i),
                        ),
                      const SizedBox(height: 8),
                      _FreeShippingMeter(subtotal: state.subtotal),
                      const SizedBox(height: 16),
                      const _PromoField(),
                      const SizedBox(height: 16),
                      Glass(
                        radius: Radii.lg,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _row(context, 'Subtotal', state.subtotal),
                            _row(context, 'Shipping', state.shipping, freeIfZero: true),
                            if (state.discount > 0)
                              _row(context, 'Member discount (10%)', -state.discount, color: p.success),
                            if (state.promoDiscount > 0)
                              _row(context, 'Promo ${state.promoCode}', -state.promoDiscount, color: p.success),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),
                            Row(
                              children: [
                                Text('Total', style: context.text.titleLarge),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerRight,
                                    child: AnimatedCount(
                                      value: state.total,
                                      prefix: '\$',
                                      decimals: 2,
                                      style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            GradientButton(
                              label: 'Checkout',
                              icon: Icons.lock_rounded,
                              onTap: () => Navigator.of(context).push(premiumRoute(const CheckoutScreen())),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
    return standalone ? Scaffold(body: AuroraBackground(intensity: 0.5, child: body)) : body;
  }

  Widget _row(BuildContext context, String label, double v, {bool freeIfZero = false, Color? color}) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
          ),
          freeIfZero && v == 0
              ? Text('FREE', style: context.text.labelLarge?.copyWith(color: p.success))
              : AnimatedCount(
                  value: v.abs(),
                  prefix: v < 0 ? '−\$' : '\$',
                  decimals: 2,
                  style: context.text.titleSmall?.copyWith(color: color),
                ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.item, required this.index});
  final CartItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = AppScope.read(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ObjectKey(item),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          state.removeFromCart(item);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(
              SnackBar(
                persist: false,
                duration: const Duration(seconds: 4),
                content: Text('${item.product.name} removed'),
                action: SnackBarAction(
                  label: 'UNDO',
                  textColor: p.accent,
                  onPressed: () => state.insertCartItem(index, item),
                ),
              ),
            );
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.transparent, p.danger.withValues(alpha: 0.85)]),
            borderRadius: BorderRadius.circular(Radii.lg),
          ),
          child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 28),
        ),
        child: Pressable(
          scale: 0.98,
          onTap: () => openProduct(context, item.product, heroPrefix: 'cart'),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              border: Border.all(color: p.stroke),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Hero(
                    tag: 'cart-${item.product.id}',
                    child: ProductPhoto(
                      product: item.product,
                      // With per-finish photography, show the photo matching the chosen finish.
                      index: item.swatch == null || item.product.images.length < 2
                          ? 0
                          : item.product.swatches.indexOf(item.swatch!).clamp(0, 99),
                      width: 92,
                      radius: Radii.md,
                      vignette: false,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.brand,
                        style: context.text.labelSmall?.copyWith(color: p.textMuted, letterSpacing: 1.4),
                      ),
                      Text(
                        item.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (item.swatch != null) ...[
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: item.swatch,
                                shape: BoxShape.circle,
                                border: Border.all(color: p.stroke),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (item.size != null)
                            Text('Size ${item.size}', style: context.text.bodySmall?.copyWith(color: p.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          AnimatedCount(
                            value: item.total,
                            prefix: '\$',
                            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          QtyStepper(compact: true, value: item.qty, onChanged: (v) => state.setQty(item, v)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FreeShippingMeter extends StatelessWidget {
  const _FreeShippingMeter({required this.subtotal});
  final double subtotal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const goal = 250.0;
    final f = (subtotal / goal).clamp(0.0, 1.0);
    final done = f >= 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: p.stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.celebration_rounded : Icons.local_shipping_outlined,
                color: done ? p.success : p.accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  child: Text(
                    done
                        ? 'You\'ve unlocked free express shipping!'
                        : 'Add ${money(goal - subtotal)} more for free shipping',
                    key: ValueKey(done),
                    style: context.text.bodySmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, c) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(color: p.surfaceHigh, borderRadius: BorderRadius.circular(8)),
                  ),
                  AnimatedContainer(
                    duration: Motion.xslow,
                    curve: Motion.emphasized,
                    height: 8,
                    width: c.maxWidth * f,
                    decoration: BoxDecoration(
                      gradient: done ? LinearGradient(colors: [p.success, p.success]) : p.brandGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: (done ? p.success : p.accent).withValues(alpha: 0.5), blurRadius: 8),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PromoField extends StatefulWidget {
  const _PromoField();

  @override
  State<_PromoField> createState() => _PromoFieldState();
}

class _PromoFieldState extends State<_PromoField> {
  final _code = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply(AppState state) {
    HapticFeedback.selectionClick();
    if (state.promoCode != null) {
      state.removePromo();
      _code.clear();
      return;
    }
    final ok = state.applyPromo(_code.text);
    setState(() => _invalid = !ok);
    if (ok) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = AppScope.of(context);
    final applied = state.promoCode != null;
    final border = applied ? p.success : (_invalid ? p.danger : p.stroke);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: Motion.medium,
          padding: const EdgeInsets.fromLTRB(16, 4, 6, 4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(Icons.confirmation_number_outlined, color: applied ? p.success : p.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: applied
                    ? Text(
                        '${state.promoCode} applied · 10% off',
                        style: context.text.titleSmall?.copyWith(color: p.success),
                      )
                    : TextField(
                        controller: _code,
                        textCapitalization: TextCapitalization.characters,
                        onChanged: (_) {
                          if (_invalid) setState(() => _invalid = false);
                        },
                        onSubmitted: (_) => _apply(state),
                        decoration: InputDecoration(
                          hintText: 'Promo code (try LUMIERE10)',
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintStyle: TextStyle(color: p.textMuted),
                        ),
                      ),
              ),
              TextButton(
                onPressed: () => _apply(state),
                child: Text(
                  applied ? 'Remove' : 'Apply',
                  style: TextStyle(color: p.accent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: Motion.medium,
          child: _invalid
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, top: 6),
                  child: Text('That code isn\'t valid', style: context.text.bodySmall?.copyWith(color: p.danger)),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
