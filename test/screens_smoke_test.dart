import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project4/core/theme.dart';
import 'package:project4/data/mock_data.dart';
import 'package:project4/screens/admin/admin_shell.dart';
import 'package:project4/screens/auth_screen.dart';
import 'package:project4/screens/cart_screen.dart';
import 'package:project4/screens/checkout_screen.dart';
import 'package:project4/screens/home_screen.dart';
import 'package:project4/screens/main_shell.dart';
import 'package:project4/screens/notifications_screen.dart';
import 'package:project4/screens/order_success_screen.dart';
import 'package:project4/screens/orders_screen.dart';
import 'package:project4/screens/product_detail_screen.dart';
import 'package:project4/screens/splash_screen.dart';
import 'package:project4/state/app_state.dart';

/// Renders every screen at phone size in both themes and fails on any
/// layout overflow or exception.
void main() {
  AppTheme.useGoogleFonts = false;

  Future<void> show(WidgetTester t, Widget page, {required Brightness b, AppState? state}) async {
    t.view.physicalSize = const Size(390 * 3, 844 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final s = state ?? (AppState()..signIn('Alex'));
    await t.pumpWidget(
      AppScope(
        state: s,
        child: MaterialApp(theme: AppTheme.build(b), home: page),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> teardown(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 5));
  }

  for (final b in Brightness.values) {
    final order = MockData.orders().first;
    final pages = <String, Widget Function()>{
      'auth': () => const AuthScreen(),
      'shell': () => const MainShell(),
      'detail': () => ProductDetailScreen(product: MockData.products.first),
      'detail-sizes': () => ProductDetailScreen(product: MockData.byId('p2')),
      'notifications': () => const NotificationsScreen(),
      'orders': () => const OrdersScreen(),
      'tracking': () => TrackingScreen(order: order),
      'success': () => OrderSuccessScreen(order: order),
      'admin': () => const AdminShell(),
    };
    pages.forEach((name, build) {
      testWidgets('$name renders (${b.name})', (t) async {
        await show(t, build(), b: b);
        expect(t.takeException(), isNull);
        await teardown(t);
      });
    });

    testWidgets('splash â†’ onboarding (${b.name})', (t) async {
      await show(t, const SplashScreen(), b: b);
      await t.pump(const Duration(seconds: 2));
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('Skip'), findsOneWidget);
      expect(t.takeException(), isNull);
      await teardown(t);
    });

    testWidgets('shell tabs (${b.name})', (t) async {
      final s = AppState()..signIn('Alex');
      s.addToCart(MockData.byId('p2'), size: '9');
      s.addToCart(MockData.byId('p3'));
      await show(t, const MainShell(), b: b, state: s);
      for (final label in ['Explore', 'Saved', 'Bag', 'Me', 'Home']) {
        // Tap by tab index position: find the nav icons.
        final idx = ['Home', 'Explore', 'Saved', 'Bag', 'Me'].indexOf(label);
        final w = t.view.physicalSize.width / t.view.devicePixelRatio;
        await t.tapAt(Offset(16 + (w - 32) / 5 * (idx + 0.5), 844 - 16 - 35));
        for (var i = 0; i < 4; i++) {
          await t.pump(const Duration(milliseconds: 300));
        }
        expect(t.takeException(), isNull, reason: label);
      }
      await teardown(t);
    });

    testWidgets('checkout flow (${b.name})', (t) async {
      final s = AppState()..signIn('Alex');
      s.addToCart(MockData.byId('p1'));
      await show(t, const CheckoutScreen(), b: b, state: s);
      for (var step = 0; step < 2; step++) {
        await t.tap(find.text('Continue'));
        for (var i = 0; i < 4; i++) {
          await t.pump(const Duration(milliseconds: 300));
        }
        expect(t.takeException(), isNull, reason: 'step $step');
      }
      expect(find.text('Pay now'), findsOneWidget);
      await teardown(t);
    });

    testWidgets('add to bag animation (${b.name})', (t) async {
      final s = AppState()..signIn('Alex');
      await show(
        t,
        ProductDetailScreen(product: MockData.products.first),
        b: b,
        state: s,
      );
      await t.tap(find.text('Add to bag'));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 250));
      }
      expect(s.cartCount, 1);
      expect(t.takeException(), isNull);
      await teardown(t);
    });

    testWidgets('bag: swipe to delete, undo, and promo entry (${b.name})', (t) async {
      final s = AppState()..addToCart(MockData.byId('p1'));
      await show(t, const CartScreen(standalone: true), b: b, state: s);

      // Invalid then valid promo code.
      await t.enterText(find.byType(TextField), 'WRONG');
      await t.tap(find.text('Apply'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('That code isn\'t valid'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'lumiere10');
      await t.tap(find.text('Apply'));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(s.promoCode, 'LUMIERE10');
      expect(find.text('Promo LUMIERE10'), findsOneWidget);

      // Swipe the item away, then undo.
      await t.drag(find.text('Aura Max Headphones'), const Offset(-400, 0));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(s.cart, isEmpty);
      await t.tap(find.text('UNDO'));
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(s.cartCount, 1);
      expect(t.takeException(), isNull);
      await teardown(t);
    });

    testWidgets('after paying, back returns to the app root, not the bag (${b.name})', (t) async {
      final s = AppState()..addToCart(MockData.byId('p1'));
      await show(t, const Scaffold(body: Center(child: Text('ROOT'))), b: b, state: s);
      final nav = t.state<NavigatorState>(find.byType(Navigator));
      nav.push(MaterialPageRoute(builder: (_) => const CartScreen(standalone: true)));
      nav.push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 300));
      }
      for (final label in ['Continue', 'Continue', 'Pay now']) {
        await t.tap(find.text(label));
        for (var i = 0; i < 4; i++) {
          await t.pump(const Duration(milliseconds: 300));
        }
      }
      await t.pump(const Duration(seconds: 2)); // simulated gateway
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('Order confirmed'), findsOneWidget);
      nav.pop();
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 300));
      }
      expect(find.text('ROOT'), findsOneWidget);
      expect(find.text('Your bag'), findsNothing);
      expect(t.takeException(), isNull);
      await teardown(t);
    });

    testWidgets('switching tabs fully fades out the previous tab (${b.name})', (t) async {
      await show(t, const MainShell(), b: b);
      final w = t.view.physicalSize.width / t.view.devicePixelRatio;
      await t.tapAt(Offset(16 + (w - 32) / 5 * 1.5, 844 - 16 - 35)); // Explore
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
      final homeFade = t.renderObject<RenderAnimatedOpacity>(
        find.ancestor(of: find.byType(HomeScreen), matching: find.byType(AnimatedOpacity)).first,
      );
      expect(homeFade.opacity.value, 0, reason: 'Home must be invisible once Explore is selected');
      expect(t.takeException(), isNull);
      await teardown(t);
    });

    testWidgets('photo gallery opens zoom viewer and drags closed (${b.name})', (t) async {
      await show(t, ProductDetailScreen(product: MockData.products.first), b: b);
      await t.tapAt(const Offset(195, 200)); // hero photo
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Pinch to zoom · swipe down to close'), findsOneWidget);
      await t.dragFrom(const Offset(195, 300), const Offset(0, 300));
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(find.text('Pinch to zoom · swipe down to close'), findsNothing);
      expect(t.takeException(), isNull);
      await teardown(t);
    });
  }
}
