import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import '../widgets/product_visual.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  double _page = 0;

  static const _pages = [
    ('Discover the\nextraordinary', 'Hand-picked pieces from 2,000+ independent studios around the world.', 'p1'),
    ('See every\ndetail up close', 'Swipe, zoom and explore every product in rich detail before you buy.', 'p3'),
    (
      'Delivered with\ncare, tracked live',
      'Secure checkout, express shipping and real-time tracking to your door.',
      'p2',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pc.addListener(() => setState(() => _page = _pc.page ?? 0));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    if (_page.round() == _pages.length - 1) {
      Navigator.of(context).pushReplacement(premiumRoute(const AuthScreen()));
    } else {
      _pc.nextPage(duration: Motion.slow, curve: Motion.emphasized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final last = _page.round() == _pages.length - 1;
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'LUMIÈRE',
                      style: context.text.titleMedium?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w300),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(premiumRoute(const AuthScreen())),
                      child: Text('Skip', style: TextStyle(color: p.textSecondary)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: _pages.length,
                  itemBuilder: (context, i) {
                    final delta = (_page - i).clamp(-1.0, 1.0);
                    final (title, body, pid) = _pages[i];
                    return Transform(
                      alignment: delta > 0 ? Alignment.centerRight : Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(-delta * math.pi / 5),
                      child: Opacity(
                        opacity: (1 - delta.abs() * 0.7).clamp(0, 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              Expanded(
                                child: TiltCard(
                                  radius: Radii.xl,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Radii.xl),
                                      boxShadow: [
                                        BoxShadow(
                                          color: MockData.byId(pid).colors.first.withValues(alpha: 0.45),
                                          blurRadius: 50,
                                          offset: const Offset(0, 24),
                                        ),
                                      ],
                                    ),
                                    child: ProductPhoto(
                                      product: MockData.byId(pid),
                                      width: 420,
                                      radius: Radii.xl,
                                      alignment: Alignment(delta * 1.5, 0),
                                      kenBurns: true,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36),
                              Transform.translate(
                                offset: Offset(delta * 120, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: context.text.displaySmall?.copyWith(height: 1.05)),
                                    const SizedBox(height: 14),
                                    Text(
                                      body,
                                      style: context.text.bodyLarge?.copyWith(color: p.textSecondary, height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Row(
                  children: [
                    // Liquid page indicator
                    Row(
                      children: List.generate(_pages.length, (i) {
                        final f = (1 - (_page - i).abs()).clamp(0.0, 1.0);
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          width: 8 + 22 * f,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: f > 0.05 ? p.brandGradient : null,
                            color: f > 0.05 ? null : p.textMuted.withValues(alpha: 0.4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    AnimatedContainer(
                      duration: Motion.slow,
                      curve: Motion.emphasized,
                      width: last ? 180 : 64,
                      child: GradientButton(
                        label: last ? 'Get started' : '',
                        icon: last ? null : Icons.arrow_forward_rounded,
                        height: 64,
                        onTap: _next,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
