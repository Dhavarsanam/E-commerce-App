import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../data/models.dart';

/// Single source of UI state. Pure frontend — no persistence yet.
class AppState extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  String? userName;
  final List<CartItem> cart = [];
  final Set<String> wishlist = {'p3', 'p6'};
  final List<Order> orders = MockData.orders();
  final List<AppNotification> notifications = MockData.notifications();
  final List<String> recentlyViewed = [];

  bool get signedIn => userName != null;
  int get cartCount => cart.fold(0, (s, i) => s + i.qty);
  double get subtotal => cart.fold(0.0, (s, i) => s + i.total);
  double get shipping => subtotal == 0 || subtotal > 250 ? 0 : 12;
  double get discount => subtotal > 500 ? subtotal * 0.1 : 0;

  /// Applied promo code (demo: LUMIERE10 = 10% off the subtotal).
  String? promoCode;
  double get promoDiscount => promoCode == null ? 0 : subtotal * 0.1;
  double get total => subtotal + shipping - discount - promoDiscount;

  /// Returns false when the code isn't recognised.
  bool applyPromo(String code) {
    final c = code.trim().toUpperCase();
    if (c != 'LUMIERE10') return false;
    promoCode = c;
    notifyListeners();
    return true;
  }

  void removePromo() {
    promoCode = null;
    notifyListeners();
  }

  int get unread => notifications.where((n) => !n.read).length;

  /// "Personalised" picks: products from categories the user looked at,
  /// falling back to top rated.
  List<Product> get recommendations {
    final seenCats = recentlyViewed.map((id) => MockData.byId(id).categoryId).toSet();
    final list = [...MockData.products]
      ..sort((a, b) {
        final sa = (seenCats.contains(a.categoryId) ? 1 : 0) + a.rating / 10;
        final sb = (seenCats.contains(b.categoryId) ? 1 : 0) + b.rating / 10;
        return sb.compareTo(sa);
      });
    return list.where((p) => !recentlyViewed.take(1).contains(p.id)).take(6).toList();
  }

  void signIn(String name) {
    userName = name.isEmpty ? 'Guest' : name;
    notifyListeners();
  }

  void signOut() {
    userName = null;
    notifyListeners();
  }

  void toggleTheme() {
    themeMode = themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void viewed(Product p) {
    recentlyViewed
      ..remove(p.id)
      ..insert(0, p.id);
    if (recentlyViewed.length > 10) recentlyViewed.removeLast();
  }

  void addToCart(Product p, {String? size, Color? swatch, int qty = 1}) {
    final existing = cart.where((i) => i.product.id == p.id && i.size == size).firstOrNull;
    if (existing != null) {
      existing.qty += qty;
    } else {
      cart.add(CartItem(product: p, qty: qty, size: size, swatch: swatch));
    }
    notifyListeners();
  }

  void setQty(CartItem item, int qty) {
    if (qty <= 0) {
      cart.remove(item);
    } else {
      item.qty = qty;
    }
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    cart.remove(item);
    notifyListeners();
  }

  void insertCartItem(int index, CartItem item) {
    cart.insert(index.clamp(0, cart.length), item);
    notifyListeners();
  }

  bool isWished(String id) => wishlist.contains(id);

  void toggleWish(String id) {
    wishlist.contains(id) ? wishlist.remove(id) : wishlist.add(id);
    notifyListeners();
  }

  /// [deliveryFee] covers paid options picked at checkout (e.g. Express), so
  /// the order records exactly what the customer was charged.
  Order placeOrder({double deliveryFee = 0}) {
    final order = Order(
      id: 'LUM-${48300 + orders.length}',
      items: cart.map((i) => CartItem(product: i.product, qty: i.qty, size: i.size)).toList(),
      date: DateTime.now(),
      status: OrderStatus.placed,
      total: total + deliveryFee,
    );
    orders.insert(0, order);
    cart.clear();
    promoCode = null; // single-use

    notifications.insert(
      0,
      AppNotification(
        NotificationKind.order,
        'Order confirmed 🎉',
        '${order.id} is being prepared by our studio.',
        'now',
      ),
    );
    notifyListeners();
    return order;
  }

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Read without subscribing to rebuilds (for callbacks).
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
