import 'package:flutter_test/flutter_test.dart';
import 'package:project4/data/mock_data.dart';
import 'package:project4/state/app_state.dart';

void main() {
  test('cart totals, shipping and discount', () {
    final s = AppState();
    expect(s.cartCount, 0);
    s.addToCart(MockData.byId('p6')); // $78
    expect(s.shipping, 12);
    s.addToCart(MockData.byId('p3')); // $1290
    expect(s.cartCount, 2);
    expect(s.shipping, 0);
    expect(s.discount, closeTo(136.8, 0.001));
    final order = s.placeOrder();
    expect(s.cart, isEmpty);
    expect(s.orders.first.id, order.id);
  });

  test('promo code changes the total and is single-use', () {
    final s = AppState()..addToCart(MockData.byId('p1')); // $349, free shipping, no member discount
    expect(s.total, 349);
    expect(s.applyPromo('nope'), isFalse);
    expect(s.total, 349);
    expect(s.applyPromo(' lumiere10 '), isTrue);
    expect(s.total, closeTo(314.1, 0.001));
    s.removePromo();
    expect(s.total, 349);
    s.applyPromo('LUMIERE10');
    final order = s.placeOrder();
    expect(order.total, closeTo(314.1, 0.001));
    expect(s.promoCode, isNull);
  });

  test('express delivery fee is included in the placed order', () {
    final s = AppState()..addToCart(MockData.byId('p1')); // $349
    final order = s.placeOrder(deliveryFee: 18);
    expect(order.total, 367);
  });

  test('wishlist toggles', () {
    final s = AppState();
    final before = s.isWished('p1');
    s.toggleWish('p1');
    expect(s.isWished('p1'), !before);
  });
}
