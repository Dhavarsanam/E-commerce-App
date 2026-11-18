import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import '../widgets/product_visual.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _step = 0;
  int _address = 0;
  int _method = 0;
  int _delivery = 0;
  bool _placing = false;
  List<CartItem>? _frozenItems;
  double? _frozenTotal;
  final _cardNumber = TextEditingController(text: '4242 4242 4242 4242');
  final _cardName = TextEditingController(text: 'ALEX MORGAN');
  final _expiry = TextEditingController(text: '08/29');
  final _cvv = TextEditingController();
  final _cvvFocus = FocusNode();

  static const _steps = ['Delivery', 'Payment', 'Review'];

  @override
  void initState() {
    super.initState();
    for (final c in [_cardNumber, _cardName, _expiry, _cvv]) {
      c.addListener(() => setState(() {}));
    }
    _cvvFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_cardNumber, _cardName, _expiry, _cvv]) {
      c.dispose();
    }
    _cvvFocus.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() => _placing = true);
    await Future.delayed(const Duration(milliseconds: 1800)); // simulated gateway
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final state = AppScope.read(context);
    // Freeze the summary so it doesn't empty out while the success page animates in.
    _frozenItems = List.of(state.cart);
    _frozenTotal = state.total;
    final order = state.placeOrder(deliveryFee: _deliveryFee);
    // Drop the purchase flow (product → bag → checkout) so "back" from the
    // confirmation or tracking returns to the main app, not an empty bag.
    Navigator.of(context).pushAndRemoveUntil(premiumRoute(OrderSuccessScreen(order: order)), (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final state = AppScope.of(context);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        body: AuroraBackground(
          intensity: 0.5,
          child: Column(
            children: [
              TopBar(title: 'Checkout', subtitle: 'Secured with 256-bit encryption'),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: _Stepper(step: _step, labels: _steps),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.slow,
                  switchInCurve: Motion.emphasized,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.15, 0), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                      children: switch (_step) {
                        0 => _delivery0(context),
                        1 => _payment(context),
                        _ => _review(context, state),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.paddingOf(context).bottom + 16),
          child: Glass(
            radius: 34,
            opacity: 0.8,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: context.text.labelSmall?.copyWith(color: p.textMuted)),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: AnimatedCount(
                            value: (_frozenTotal ?? state.total) + _deliveryFee,
                            prefix: '\$',
                            decimals: 2,
                            style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: GradientButton(
                    label: _step == 2 ? 'Pay now' : 'Continue',
                    icon: _step == 2 ? Icons.lock_rounded : Icons.arrow_forward_rounded,
                    loading: _placing,
                    onTap: _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _delivery0(BuildContext context) {
    final p = context.palette;
    const addresses = [
      ('Home', '221B Baker Street, London NW1 6XE', Icons.home_rounded),
      ('Studio', '14 Rue de Rivoli, 75004 Paris', Icons.work_rounded),
    ];
    const speeds = [('Standard', '3–5 business days', 'Free'), ('Express', 'Tomorrow by 12 PM', '\$18')];
    return [
      Text('Ship to', style: context.text.titleMedium),
      const SizedBox(height: 12),
      for (var i = 0; i < addresses.length; i++)
        Reveal(
          delay: Reveal.stagger(i),
          child: _SelectTile(
            selected: _address == i,
            onTap: () => setState(() => _address = i),
            icon: addresses[i].$3,
            title: addresses[i].$1,
            subtitle: addresses[i].$2,
          ),
        ),
      Pressable(
        onTap: () => showComingSoon(
          context,
          title: 'New address',
          icon: Icons.add_location_alt_rounded,
          body: 'Address search with autocomplete arrives with the maps integration.',
        ),
        child: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.md),
            border: Border.all(color: p.accent.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_location_alt_outlined, color: p.accent),
              const SizedBox(width: 8),
              Text('Add new address', style: context.text.labelLarge?.copyWith(color: p.accent)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 26),
      Text('Delivery speed', style: context.text.titleMedium),
      const SizedBox(height: 12),
      for (var i = 0; i < speeds.length; i++)
        Reveal(
          delay: Reveal.stagger(i + 2),
          child: _SelectTile(
            selected: _delivery == i,
            onTap: () => setState(() => _delivery = i),
            icon: i == 0 ? Icons.local_shipping_outlined : Icons.rocket_launch_outlined,
            title: speeds[i].$1,
            subtitle: speeds[i].$2,
            trailing: speeds[i].$3,
          ),
        ),
    ];
  }

  List<Widget> _payment(BuildContext context) {
    const methods = [
      ('Card', Icons.credit_card_rounded),
      ('Apple Pay', Icons.apple_rounded),
      ('UPI', Icons.qr_code_2_rounded),
      ('Cash', Icons.payments_outlined),
    ];
    return [
      SizedBox(
        height: 84,
        child: Row(
          children: List.generate(methods.length, (i) {
            final on = i == _method;
            final p = context.palette;
            return Expanded(
              child: Pressable(
                onTap: () => setState(() => _method = i),
                child: AnimatedContainer(
                  duration: Motion.medium,
                  curve: Motion.emphasized,
                  margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                  decoration: BoxDecoration(
                    gradient: on ? p.brandGradient : null,
                    color: on ? null : p.surface,
                    borderRadius: BorderRadius.circular(Radii.md),
                    border: Border.all(color: on ? Colors.transparent : p.stroke),
                    boxShadow: on
                        ? [
                            BoxShadow(
                              color: p.accent.withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : const [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(methods[i].$2, color: on ? Colors.white : p.textSecondary),
                      const SizedBox(height: 6),
                      Text(
                        methods[i].$1,
                        style: context.text.labelSmall?.copyWith(color: on ? Colors.white : p.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      const SizedBox(height: 24),
      AnimatedSwitcher(
        duration: Motion.medium,
        child: _method == 0
            ? Column(
                key: const ValueKey('card'),
                children: [
                  CreditCard3D(
                    number: _cardNumber.text,
                    name: _cardName.text,
                    expiry: _expiry.text,
                    cvv: _cvv.text,
                    flipped: _cvvFocus.hasFocus,
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _cardNumber,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Card number',
                      prefixIcon: Icon(Icons.credit_card_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cardName,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Name on card',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expiry,
                          decoration: const InputDecoration(hintText: 'MM/YY', prefixIcon: Icon(Icons.event_rounded)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _cvv,
                          focusNode: _cvvFocus,
                          obscureText: true,
                          maxLength: 3,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'CVV',
                            counterText: '',
                            prefixIcon: Icon(Icons.password_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            : Container(
                key: ValueKey(_method),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(Radii.lg),
                  border: Border.all(color: context.palette.stroke),
                ),
                child: Column(
                  children: [
                    Icon(methods[_method].$2, size: 56, color: context.palette.accent),
                    const SizedBox(height: 12),
                    Text('Pay with ${methods[_method].$1}', style: context.text.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'You\'ll confirm the payment on the next step.',
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: context.palette.textMuted),
                    ),
                  ],
                ),
              ),
      ),
    ];
  }

  List<Widget> _review(BuildContext context, AppState appState) {
    final p = context.palette;
    final cart = _frozenItems ?? appState.cart;
    return [
      Text('Order summary', style: context.text.titleMedium),
      const SizedBox(height: 12),
      for (var i = 0; i < cart.length; i++)
        Reveal(
          delay: Reveal.stagger(i),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: p.stroke),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: ProductPhoto(product: cart[i].product, width: 56, radius: 14, vignette: false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cart[i].product.name, style: context.text.titleSmall),
                      Text(
                        'Qty ${cart[i].qty}${cart[i].size != null ? ' · Size ${cart[i].size}' : ''}',
                        style: context.text.bodySmall?.copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(money(cart[i].total), style: context.text.titleSmall),
              ],
            ),
          ),
        ),
      const SizedBox(height: 14),
      Glass(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _kv(context, 'Deliver to', _address == 0 ? 'Home' : 'Studio'),
            _kv(context, 'Delivery', _delivery == 0 ? 'Standard · Free' : 'Express · \$18'),
            _kv(context, 'Payment', ['Card •••• ${_last4()}', 'Apple Pay', 'UPI', 'Cash on delivery'][_method]),
          ],
        ),
      ),
      const SizedBox(height: 14),
      // Price breakdown, so the amount on the Pay button is fully explained.
      Glass(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _kv(context, 'Subtotal', money(appState.subtotal)),
            if (appState.discount > 0) _kv(context, 'Member discount', '−${money(appState.discount)}'),
            if (appState.promoDiscount > 0)
              _kv(context, 'Promo ${appState.promoCode}', '−${money(appState.promoDiscount)}'),
            _kv(
              context,
              'Delivery',
              appState.shipping + _deliveryFee == 0 ? 'Free' : money(appState.shipping + _deliveryFee),
            ),
            const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Divider()),
            _kv(context, 'Total', money((_frozenTotal ?? appState.total) + _deliveryFee)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Icon(Icons.shield_outlined, size: 16, color: p.success),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Payments are processed by a PCI-DSS certified gateway. We never store your card.',
              style: context.text.bodySmall?.copyWith(color: p.textMuted),
            ),
          ),
        ],
      ),
    ];
  }

  double get _deliveryFee => _delivery == 1 ? 18 : 0;

  String _last4() {
    final d = _cardNumber.text.replaceAll(' ', '');
    return d.length >= 4 ? d.substring(d.length - 4) : d;
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(k, style: context.text.bodyMedium?.copyWith(color: context.palette.textSecondary)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(v, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
        ),
      ],
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.step, required this.labels});
  final int step;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: List.generate(labels.length * 2 - 1, (k) {
        if (k.isOdd) {
          final i = k ~/ 2;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: p.surfaceHigh, borderRadius: BorderRadius.circular(3)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AnimatedFractionallySizedBox(
                  duration: Motion.slow,
                  curve: Motion.emphasized,
                  widthFactor: step > i ? 1 : 0,
                  child: Container(
                    decoration: BoxDecoration(gradient: p.brandGradient, borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ),
            ),
          );
        }
        final i = k ~/ 2;
        final done = step > i;
        final active = step == i;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Motion.slow,
              curve: Motion.emphasized,
              width: active ? 38 : 32,
              height: active ? 38 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done || active ? p.brandGradient : null,
                color: done || active ? null : p.surfaceHigh,
                boxShadow: active ? [BoxShadow(color: p.accent.withValues(alpha: 0.5), blurRadius: 14)] : const [],
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: Motion.medium,
                  transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                  child: done
                      ? const Icon(Icons.check_rounded, key: ValueKey('d'), color: Colors.white, size: 18)
                      : Text(
                          '${i + 1}',
                          key: ValueKey('n$i'),
                          style: context.text.labelLarge?.copyWith(color: active ? Colors.white : p.textMuted),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(labels[i], style: context.text.labelSmall?.copyWith(color: active ? p.textPrimary : p.textMuted)),
          ],
        );
      }),
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.selected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final bool selected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: AnimatedContainer(
        duration: Motion.medium,
        curve: Motion.emphasized,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.1) : p.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: selected ? p.accent : p.stroke, width: selected ? 1.6 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected ? p.accent : p.surfaceHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: selected ? Colors.white : p.textSecondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleSmall),
                  const SizedBox(height: 2),
                  Text(subtitle, style: context.text.bodySmall?.copyWith(color: p.textMuted)),
                ],
              ),
            ),
            if (trailing != null) ...[Text(trailing!, style: context.text.labelLarge), const SizedBox(width: 10)],
            AnimatedContainer(
              duration: Motion.medium,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? p.accent : p.textMuted, width: selected ? 7 : 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Credit card that renders live input, tilts in 3D and flips to show the
/// CVV strip when the CVV field gains focus.
class CreditCard3D extends StatelessWidget {
  const CreditCard3D({
    super.key,
    required this.number,
    required this.name,
    required this.expiry,
    required this.cvv,
    required this.flipped,
  });
  final String number;
  final String name;
  final String expiry;
  final String cvv;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: flipped ? math.pi : 0),
      duration: const Duration(milliseconds: 700),
      curve: Motion.emphasized,
      builder: (context, angle, _) {
        final showBack = angle > math.pi / 2;
        return TiltCard(
          radius: 24,
          maxTilt: 0.18,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: AspectRatio(
              aspectRatio: 1.586,
              child: showBack
                  ? Transform(alignment: Alignment.center, transform: Matrix4.rotationY(math.pi), child: _back(context))
                  : _front(context),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _deco(BuildContext context) => BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2B1B6B), Color(0xFF7C5CFF), Color(0xFFFF5C8A)],
      stops: [0, 0.6, 1],
    ),
    boxShadow: [
      BoxShadow(color: context.palette.accent.withValues(alpha: 0.45), blurRadius: 30, offset: const Offset(0, 16)),
    ],
  );

  Widget _front(BuildContext context) {
    final digits = number.replaceAll(' ', '');
    final masked = List.generate(16, (i) => i < digits.length ? (i < 12 && i >= 4 ? '•' : digits[i]) : '•').join();
    final grouped = [for (var i = 0; i < 16; i += 4) masked.substring(i, i + 4)].join('  ');
    const white = TextStyle(color: Colors.white);
    return Container(
      decoration: _deco(context),
      padding: const EdgeInsets.all(22),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('LUMIÈRE', style: white.copyWith(letterSpacing: 4, fontWeight: FontWeight.w300)),
                  const Spacer(),
                  const Icon(Icons.contactless_rounded, color: Colors.white70),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(colors: [Color(0xFFF3DB9A), Color(0xFFB8913F)]),
                ),
              ),
              const Spacer(),
              FittedBox(
                child: Text(
                  grouped,
                  style: white.copyWith(fontSize: 21, letterSpacing: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARD HOLDER',
                          style: white.copyWith(fontSize: 9, color: Colors.white60, letterSpacing: 1),
                        ),
                        Text(
                          name.isEmpty ? 'YOUR NAME' : name.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: white.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EXPIRES', style: white.copyWith(fontSize: 9, color: Colors.white60, letterSpacing: 1)),
                      Text(expiry.isEmpty ? 'MM/YY' : expiry, style: white.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 44,
                    height: 28,
                    child: Stack(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEB001B).withValues(alpha: 0.9),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF79E1B).withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _back(BuildContext context) {
    return Container(
      decoration: _deco(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 26),
          Container(height: 44, color: Colors.black87),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Expanded(child: Container(height: 38, color: Colors.white70)),
                Container(
                  width: 64,
                  height: 38,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Text(
                    cvv.isEmpty ? 'CVV' : '•' * cvv.length,
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w700, letterSpacing: 2),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'This card is property of Lumière. Demo only.',
              style: TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
