import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/models.dart';
import '../state/app_state.dart';
import '../widgets/components.dart';
import '../widgets/effects.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final p = context.palette;
    return Scaffold(
      body: AuroraBackground(
        intensity: 0.5,
        child: Column(
          children: [
            TopBar(
              title: 'Notifications',
              subtitle: state.unread == 0 ? 'You\'re all caught up' : '${state.unread} unread',
              actions: [
                if (state.unread > 0)
                  TextButton(
                    onPressed: AppScope.read(context).markAllRead,
                    child: Text('Mark all read', style: TextStyle(color: p.accent)),
                  ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                itemCount: state.notifications.length,
                itemBuilder: (context, i) {
                  final n = state.notifications[i];
                  final (color, icon) = switch (n.kind) {
                    NotificationKind.offer => (p.accent2, Icons.local_offer_rounded),
                    NotificationKind.order => (p.accent, Icons.local_shipping_rounded),
                    NotificationKind.stock => (p.success, Icons.inventory_rounded),
                  };
                  return Reveal(
                    delay: Reveal.stagger(i),
                    axis: Axis.horizontal,
                    child: AnimatedContainer(
                      duration: Motion.medium,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: n.read ? p.surface : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(Radii.lg),
                        border: Border.all(color: n.read ? p.stroke : color.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(icon, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(n.title, style: context.text.titleSmall)),
                                    Text(n.time, style: context.text.labelSmall?.copyWith(color: p.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n.body,
                                  style: context.text.bodySmall?.copyWith(color: p.textSecondary, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                          if (!n.read)
                            Container(
                              margin: const EdgeInsets.only(left: 8, top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (state.notifications.isEmpty)
              const EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'No notifications',
                body: 'We\'ll let you know when something happens.',
              ),
          ],
        ),
      ),
    );
  }
}
