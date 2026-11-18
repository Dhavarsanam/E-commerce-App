import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/effects.dart';
import '../widgets/product_visual.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
  late final _orbit = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.of(context).pushReplacement(premiumRoute(const OnboardingScreen()));
    });
  }

  bool _warmed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmed) return;
    _warmed = true;
    // Use the splash time to download + decode the first photos the user
    // will see: onboarding / home banners (same size) and the first cards.
    for (final id in const ['p1', 'p3', 'p2']) {
      ProductPhoto.precache(context, MockData.byId(id), width: 420);
    }
    for (final p in MockData.products.take(6)) {
      ProductPhoto.precache(context, p, width: 200);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _orbit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: AuroraBackground(
        intensity: 1.2,
        child: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_intro, _orbit]),
            builder: (context, _) {
              final t = Motion.emphasized.transform(_intro.value);
              final logoIn = Curves.elasticOut.transform((_intro.value * 1.4).clamp(0, 1));
              final textIn = Curves.easeOut.transform(((_intro.value - 0.45) / 0.55).clamp(0, 1));
              final spin = (1 - t) * math.pi * 1.5 + math.sin(_orbit.value * 2 * math.pi) * 0.25;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Orbit rings in 3D
                        for (var i = 0; i < 2; i++)
                          Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.002)
                              ..rotateX(1.15)
                              ..rotateZ(_orbit.value * 2 * math.pi * (i == 0 ? 1 : -1)),
                            child: Opacity(
                              opacity: t * 0.8,
                              child: Container(
                                width: 200 - i * 36.0,
                                height: 200 - i * 36.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (i == 0 ? p.accent : p.accent2).withValues(alpha: 0.7),
                                    width: 1.6,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      boxShadow: [BoxShadow(color: p.accent2, blurRadius: 12)],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // 3D logo tile
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0018)
                            ..rotateY(spin)
                            ..rotateX(0.18)
                            ..scaleByDouble(logoIn, logoIn, 1, 1),
                          child: Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              gradient: p.auroraGradient,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: p.accent.withValues(alpha: 0.6),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Positioned.fill(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(32),
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.center,
                                        colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'L',
                                  style: context.text.displayMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    shadows: const [
                                      Shadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 6)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: textIn,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - textIn)),
                      child: Column(
                        children: [
                          Text(
                            'LUMIÈRE',
                            style: context.text.headlineMedium?.copyWith(
                              letterSpacing: 12 * textIn + 2,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Curated luxury, delivered.',
                            style: context.text.bodyMedium?.copyWith(color: p.textSecondary, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
