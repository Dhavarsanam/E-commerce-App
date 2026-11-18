import 'package:flutter/material.dart';

class Category {
  const Category(this.id, this.name, this.icon, this.colors);
  final String id;
  final String name;
  final IconData icon;
  final List<Color> colors;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.categoryId,
    required this.price,
    required this.icon,
    required this.colors,
    required this.description,
    this.oldPrice,
    this.rating = 4.6,
    this.reviews = 120,
    this.stock = 24,
    this.sizes = const [],
    this.swatches = const [],
    this.tag,
    this.vendor = 'Lumière Studio',
    this.images = const [],
    this.focus = (0.5, 0.5),
  });

  final String id;
  final String name;
  final String brand;
  final String categoryId;
  final double price;
  final double? oldPrice;
  final double rating;
  final int reviews;
  final int stock;
  final IconData icon;

  /// Two-stop gradient that gives each product its "studio lighting".
  final List<Color> colors;
  final String description;
  final List<String> sizes;
  final List<Color> swatches;
  final String? tag;
  final String vendor;

  /// Unsplash photo ids (the part after `photo-`). Replace with your CDN
  /// URLs when the backend is connected. With real catalogue photography,
  /// list one id per angle and the gallery will show them in order.
  final List<String> images;

  /// Where the product sits inside the hero photo (0..1 on each axis).
  /// Used to frame the close-up detail shots.
  final (double, double) focus;

  /// Gallery length: real photos when there are several, otherwise the hero
  /// shot plus two close-up details of the same photo, so every page shows
  /// the same product.
  int get photoCount => images.isEmpty ? 0 : (images.length > 1 ? images.length : 3);

  /// Sized, compressed photo URL. [width] is in logical pixels; we request
  /// 2x for sharp rendering on high-density screens.
  String imageUrl(int index, {int width = 600}) {
    final w = width * 2;
    if (images.length > 1) {
      return 'https://images.unsplash.com/photo-${images[index % images.length]}?w=$w&q=80&auto=format&fit=crop';
    }
    final base = 'https://images.unsplash.com/photo-${images.first}?w=$w&q=80&auto=format&fit=crop';
    final shot = index % 3;
    if (shot == 0) return base;
    // Detail shots: zoom into the product via the CDN's focal-point crop.
    final (fx, fy) = focus;
    final x = (shot == 1 ? fx : fx + 0.08).clamp(0.1, 0.9).toStringAsFixed(2);
    final y = (shot == 1 ? fy : fy + 0.1).clamp(0.1, 0.9).toStringAsFixed(2);
    final zoom = shot == 1 ? 1.7 : 2.6;
    return '$base&h=$w&crop=focalpoint&fp-x=$x&fp-y=$y&fp-z=$zoom';
  }

  int get discountPercent => oldPrice == null ? 0 : (((oldPrice! - price) / oldPrice!) * 100).round();
}

class CartItem {
  CartItem({required this.product, this.qty = 1, this.size, this.swatch});
  final Product product;
  int qty;
  final String? size;
  final Color? swatch;
  double get total => product.price * qty;
}

enum OrderStatus { placed, packed, shipped, outForDelivery, delivered }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
    OrderStatus.placed => 'Order placed',
    OrderStatus.packed => 'Packed',
    OrderStatus.shipped => 'Shipped',
    OrderStatus.outForDelivery => 'Out for delivery',
    OrderStatus.delivered => 'Delivered',
  };

  IconData get icon => switch (this) {
    OrderStatus.placed => Icons.receipt_long_rounded,
    OrderStatus.packed => Icons.inventory_2_rounded,
    OrderStatus.shipped => Icons.local_shipping_rounded,
    OrderStatus.outForDelivery => Icons.delivery_dining_rounded,
    OrderStatus.delivered => Icons.verified_rounded,
  };
}

class Order {
  Order({
    required this.id,
    required this.items,
    required this.date,
    required this.status,
    required this.total,
    this.customer = 'You',
  });
  final String id;
  final List<CartItem> items;
  final DateTime date;
  OrderStatus status;
  final double total;
  final String customer;
}

enum NotificationKind { offer, order, stock }

class AppNotification {
  AppNotification(this.kind, this.title, this.body, this.time, {this.read = false});
  final NotificationKind kind;
  final String title;
  final String body;
  final String time;
  bool read;
}
