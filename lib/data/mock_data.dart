import 'package:flutter/material.dart';

import 'models.dart';

/// Frontend-only catalogue. Swap this file for API calls when the backend lands.
abstract final class MockData {
  static const categories = [
    Category('all', 'For you', Icons.auto_awesome_rounded, [Color(0xFF7C5CFF), Color(0xFFFF5C8A)]),
    Category('tech', 'Tech', Icons.headphones_rounded, [Color(0xFF4F7CFF), Color(0xFF7C5CFF)]),
    Category('fashion', 'Fashion', Icons.checkroom_rounded, [Color(0xFFFF5C8A), Color(0xFFFFB36B)]),
    Category('shoes', 'Sneakers', Icons.ice_skating_rounded, [Color(0xFF00C2A8), Color(0xFF4F7CFF)]),
    Category('watch', 'Watches', Icons.watch_rounded, [Color(0xFFE8C77A), Color(0xFFB0753A)]),
    Category('home', 'Home', Icons.chair_rounded, [Color(0xFF8E6CFF), Color(0xFF00C2A8)]),
    Category('beauty', 'Beauty', Icons.spa_rounded, [Color(0xFFFF8FB1), Color(0xFFB05CFF)]),
  ];

  static const products = [
    Product(
      id: 'p1',
      images: ['1505740420928-5e560c06d30e'],
      focus: (0.6, 0.5),
      name: 'Aura Max Headphones',
      brand: 'SONIQ',
      categoryId: 'tech',
      price: 349,
      oldPrice: 429,
      rating: 4.9,
      reviews: 2841,
      icon: Icons.headphones_rounded,
      colors: [Color(0xFF6A5CFF), Color(0xFF1B1446)],
      tag: 'Bestseller',
      sizes: [],
      swatches: [Color(0xFF1E1E24), Color(0xFFE9E4DA), Color(0xFF6A5CFF)],
      description:
          'Studio-grade spatial audio with adaptive noise cancellation, 40-hour battery and '
          'memory-foam cushions wrapped in vegan leather. Tuned by Grammy-winning engineers.',
    ),
    Product(
      id: 'p2',
      images: ['1491553895911-0055eca6402d'],
      focus: (0.5, 0.5),
      name: 'Phantom Runner X',
      brand: 'STRYDE',
      categoryId: 'shoes',
      price: 189,
      oldPrice: 240,
      rating: 4.8,
      reviews: 1290,
      icon: Icons.directions_run_rounded,
      colors: [Color(0xFF00C2A8), Color(0xFF0B3B4F)],
      tag: 'New',
      sizes: ['7', '8', '9', '10', '11'],
      swatches: [Color(0xFF00C2A8), Color(0xFF111111), Color(0xFFF2F2F2)],
      description:
          'Carbon-plated propulsion, featherlight knit upper and a nitrogen-infused midsole '
          'that returns 87% of your energy on every stride.',
    ),
    Product(
      id: 'p3',
      images: ['1524592094714-0f0654e20314'],
      focus: (0.55, 0.45),
      name: 'Chrono Eclipse',
      brand: 'MERIDIAN',
      categoryId: 'watch',
      price: 1290,
      rating: 4.9,
      reviews: 412,
      stock: 6,
      icon: Icons.watch_rounded,
      colors: [Color(0xFFE8C77A), Color(0xFF3A2A12)],
      tag: 'Limited',
      swatches: [Color(0xFFE8C77A), Color(0xFFC0C0C8), Color(0xFF222222)],
      description:
          'Swiss automatic movement in a 41mm sapphire-crystal case. Hand-finished dial '
          'with lume indices and a 72-hour power reserve.',
    ),
    Product(
      id: 'p4',
      images: ['1586689311267-e88bb0509995'],
      focus: (0.5, 0.4),
      name: 'Cloud Knit Overshirt',
      brand: 'NORDE',
      categoryId: 'fashion',
      price: 129,
      oldPrice: 159,
      rating: 4.7,
      reviews: 830,
      icon: Icons.checkroom_rounded,
      colors: [Color(0xFFFF7A9C), Color(0xFF4A1530)],
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      swatches: [Color(0xFFFF7A9C), Color(0xFF2C2C34), Color(0xFFD9CFC1)],
      description:
          'Brushed merino blend with a relaxed drape. Breathable, temperature-regulating and '
          'made in a carbon-neutral mill in Portugal.',
    ),
    Product(
      id: 'p5',
      images: ['1517991104123-1d56a6e81ed9'],
      focus: (0.6, 0.35),
      name: 'Halo Smart Lamp',
      brand: 'LUMA',
      categoryId: 'home',
      price: 219,
      rating: 4.6,
      reviews: 512,
      icon: Icons.light_rounded,
      colors: [Color(0xFF8E6CFF), Color(0xFF0E2E3A)],
      swatches: [Color(0xFFF4F1EA), Color(0xFF1F1F1F)],
      description:
          'Circadian lighting that follows the sun. 16M colours, voice control and a '
          'hand-blown glass diffuser that glows like a moon.',
    ),
    Product(
      id: 'p6',
      images: ['1713768704571-6aeb0d0e5105'],
      focus: (0.5, 0.6),
      name: 'Velvet Glow Serum',
      brand: 'ÉTHER',
      categoryId: 'beauty',
      price: 78,
      oldPrice: 92,
      rating: 4.8,
      reviews: 3204,
      icon: Icons.water_drop_rounded,
      colors: [Color(0xFFFF8FB1), Color(0xFF4B1D5E)],
      tag: 'Trending',
      description:
          'Niacinamide, peptides and squalane in a weightless serum that leaves skin glassy, '
          'plump and luminous in seven days.',
    ),
    Product(
      id: 'p7',
      images: ['1512790182412-b19e6d62bc39'],
      focus: (0.5, 0.5),
      name: 'Vision Pro Lens 50mm',
      brand: 'OPTIKA',
      categoryId: 'tech',
      price: 899,
      rating: 4.9,
      reviews: 221,
      stock: 3,
      icon: Icons.camera_rounded,
      colors: [Color(0xFF4F7CFF), Color(0xFF0B1430)],
      description:
          'f/1.2 prime with nano-crystal coating, silent stepping motor and buttery bokeh '
          'for portraits that feel like cinema.',
    ),
    Product(
      id: 'p8',
      images: ['1580480055273-228ff5388ef8'],
      focus: (0.45, 0.5),
      name: 'Orbit Lounge Chair',
      brand: 'FORMA',
      categoryId: 'home',
      price: 640,
      oldPrice: 780,
      rating: 4.7,
      reviews: 96,
      icon: Icons.chair_rounded,
      colors: [Color(0xFF00C2A8), Color(0xFF203A2E)],
      swatches: [Color(0xFF6B8F71), Color(0xFFC9B79C), Color(0xFF2A2A2A)],
      description:
          'Sculpted oak frame, bouclé upholstery and a 12° recline engineered for long, '
          'slow Sunday mornings.',
    ),
    Product(
      id: 'p9',
      images: ['1590658268037-6bf12165a8df'],
      focus: (0.55, 0.6),
      name: 'Nova Earbuds Pro',
      brand: 'SONIQ',
      categoryId: 'tech',
      price: 199,
      oldPrice: 249,
      rating: 4.7,
      reviews: 4110,
      icon: Icons.earbuds_rounded,
      colors: [Color(0xFFFF5C8A), Color(0xFF2A0F2E)],
      swatches: [Color(0xFFF2F2F2), Color(0xFF1C1C1C)],
      description: 'Pocket-sized spatial audio with lossless codec and a wireless charging case.',
    ),
    Product(
      id: 'p10',
      images: ['1624687943971-e86af76d57de'],
      focus: (0.5, 0.45),
      name: 'Atlas Leather Tote',
      brand: 'NORDE',
      categoryId: 'fashion',
      price: 295,
      rating: 4.8,
      reviews: 640,
      icon: Icons.shopping_bag_rounded,
      colors: [Color(0xFFFFB36B), Color(0xFF4A2410)],
      swatches: [Color(0xFF8B5A2B), Color(0xFF111111), Color(0xFFD2B48C)],
      description: 'Full-grain Italian leather that ages beautifully. Fits a 16" laptop.',
    ),
  ];

  static Product byId(String id) => products.firstWhere((p) => p.id == id);

  static List<AppNotification> notifications() => [
    AppNotification(
      NotificationKind.offer,
      'Midnight Drop · 40% off',
      'The Aura collection is live for the next 6 hours only.',
      '2m',
    ),
    AppNotification(
      NotificationKind.order,
      'Your order is out for delivery',
      'LUM-48213 arrives today between 2–4 PM.',
      '1h',
    ),
    AppNotification(
      NotificationKind.stock,
      'Back in stock',
      'Chrono Eclipse in Champagne Gold is available again.',
      '3h',
      read: true,
    ),
    AppNotification(
      NotificationKind.offer,
      'You unlocked Gold tier ✨',
      'Enjoy free express shipping on every order.',
      '1d',
      read: true,
    ),
  ];

  static List<Order> orders() => [
    Order(
      id: 'LUM-48213',
      items: [
        CartItem(product: products[0]),
        CartItem(product: products[5], qty: 2),
      ],
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: OrderStatus.outForDelivery,
      total: 505,
    ),
    Order(
      id: 'LUM-47790',
      items: [CartItem(product: products[1])],
      date: DateTime.now().subtract(const Duration(days: 9)),
      status: OrderStatus.delivered,
      total: 189,
    ),
  ];

  static final adminOrders = [
    Order(
      id: 'LUM-48290',
      items: [CartItem(product: products[2])],
      date: DateTime.now(),
      status: OrderStatus.placed,
      total: 1290,
      customer: 'Ava Laurent',
    ),
    Order(
      id: 'LUM-48288',
      items: [CartItem(product: products[0])],
      date: DateTime.now(),
      status: OrderStatus.packed,
      total: 349,
      customer: 'Noah Kim',
    ),
    Order(
      id: 'LUM-48281',
      items: [CartItem(product: products[3], qty: 2)],
      date: DateTime.now(),
      status: OrderStatus.shipped,
      total: 258,
      customer: 'Mia Rossi',
    ),
    Order(
      id: 'LUM-48275',
      items: [CartItem(product: products[7])],
      date: DateTime.now(),
      status: OrderStatus.outForDelivery,
      total: 640,
      customer: 'Liam Chen',
    ),
    Order(
      id: 'LUM-48262',
      items: [CartItem(product: products[5], qty: 3)],
      date: DateTime.now(),
      status: OrderStatus.delivered,
      total: 234,
      customer: 'Zara Patel',
    ),
  ];

  /// Revenue for the last 12 weeks (in thousands).
  static const revenue = [18.2, 21.4, 19.8, 26.1, 24.3, 29.8, 31.2, 28.7, 35.4, 38.9, 36.2, 44.6];
  static const List<double> weekdaySales = [42, 58, 51, 66, 72, 91, 84];
}
