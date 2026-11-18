import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';
import 'admin/admin_shell.dart';
import 'auth_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    final name = state.userName ?? 'Guest';
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 16, 16, 130),
      children: [
        Reveal(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: p.auroraGradient),
                child: CircleAvatar(
                  radius: 34,
                  backgroundColor: p.surfaceHigh,
                  child: Text(name[0], style: context.text.headlineSmall),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: context.text.headlineSmall),
                    Text(
                      '${name.toLowerCase()}@lumiere.app',
                      style: context.text.bodySmall?.copyWith(color: p.textMuted),
                    ),
                  ],
                ),
              ),
              IconBubble(
                icon: context.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                onTap: AppScope.read(context).toggleTheme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Reveal(delay: Reveal.stagger(1), child: const _MembershipCard()),
        const SizedBox(height: 20),
        Reveal(
          delay: Reveal.stagger(2),
          child: Row(
            children: [
              _Stat(value: state.orders.length.toDouble(), label: 'Orders'),
              const SizedBox(width: 12),
              _Stat(value: state.wishlist.length.toDouble(), label: 'Saved'),
              const SizedBox(width: 12),
              const _Stat(value: 2480, label: 'Points'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (final (i, (icon, label, onTap)) in [
          (
            Icons.receipt_long_rounded,
            'My orders',
            () => Navigator.of(context).push(premiumRoute(const OrdersScreen())),
          ),
          (
            Icons.notifications_none_rounded,
            'Notifications',
            () => Navigator.of(context).push(premiumRoute(const NotificationsScreen())),
          ),
          (
            Icons.location_on_outlined,
            'Addresses',
            () => showComingSoon(
              context,
              title: 'Saved addresses',
              icon: Icons.location_on_rounded,
              body: 'Manage delivery addresses here once your account syncs with our servers.',
            ),
          ),
          (
            Icons.credit_card_rounded,
            'Payment methods',
            () => showComingSoon(
              context,
              title: 'Payment methods',
              icon: Icons.credit_card_rounded,
              body: 'Securely saved cards and wallets will appear here, tokenised by our payment partner.',
            ),
          ),
          (
            Icons.storefront_rounded,
            'Vendor dashboard',
            () => Navigator.of(context).push(premiumRoute(const AdminShell())),
          ),
          (
            Icons.help_outline_rounded,
            'Help & support',
            () => showComingSoon(
              context,
              title: 'Concierge support',
              icon: Icons.support_agent_rounded,
              body: 'Live chat with a Lumière stylist, 7 days a week. Arriving soon.',
            ),
          ),
        ].indexed)
          Reveal(
            delay: Reveal.stagger(i + 3, ms: 50),
            child: _MenuTile(
              icon: icon,
              label: label,
              onTap: onTap,
              badge: label == 'Notifications' ? state.unread : 0,
            ),
          ),
        const SizedBox(height: 10),
        Pressable(
          onTap: () {
            AppScope.read(context).signOut();
            Navigator.of(context).pushAndRemoveUntil(premiumRoute(const AuthScreen()), (_) => false);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: p.danger.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: p.danger),
                const SizedBox(width: 8),
                Text('Sign out', style: context.text.labelLarge?.copyWith(color: p.danger)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Metallic membership card with 3D tilt and holographic sheen.
class _MembershipCard extends StatefulWidget {
  const _MembershipCard();

  @override
  State<_MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends State<_MembershipCard> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TiltCard(
      radius: Radii.lg,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          height: 180,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.lg),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _c.value, -1),
              end: Alignment(1 + 2 * _c.value, 1),
              tileMode: TileMode.mirror,
              colors: const [
                Color(0xFF3A2A12),
                Color(0xFFE8C77A),
                Color(0xFFFFF1C9),
                Color(0xFFB8913F),
                Color(0xFF3A2A12),
              ],
            ),
            boxShadow: [BoxShadow(color: p.gold.withValues(alpha: 0.35), blurRadius: 30, offset: const Offset(0, 14))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.diamond_rounded, color: Color(0xFF2A1E0A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'GOLD MEMBER',
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelLarge?.copyWith(color: const Color(0xFF2A1E0A), letterSpacing: 2),
                    ),
                  ),
                  Text(
                    'LUMIÈRE',
                    style: context.text.labelMedium?.copyWith(color: const Color(0xFF2A1E0A), letterSpacing: 4),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '2,480 pts',
                style: context.text.headlineMedium?.copyWith(
                  color: const Color(0xFF1C1405),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0.62,
                  minHeight: 6,
                  backgroundColor: Colors.black.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2A1E0A)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '520 pts to Platinum · free express + early drops',
                style: context.text.labelSmall?.copyWith(color: const Color(0xFF3A2A12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: p.stroke),
        ),
        child: Column(
          children: [
            AnimatedCount(value: value, style: context.text.headlineSmall),
            Text(label, style: context.text.labelSmall?.copyWith(color: p.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, required this.onTap, this.badge = 0});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(color: p.stroke),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: p.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: context.text.titleSmall)),
            if (badge > 0) ...[Pill('$badge new', color: p.accent2), const SizedBox(width: 8)],
            Icon(Icons.chevron_right_rounded, color: p.textMuted),
          ],
        ),
      ),
    );
  }
}
