import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/notification_model.dart';
import '../../../providers/notification_provider.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../home/widgets/customer_bottom_nav_bar.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Notifications'),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      backgroundColor: AppColors.background,
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 2),
      body: notificationsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _NotificationTile(
              notification: items[index],
              onMarkRead: items[index].isRead
                  ? null
                  : () => ref
                        .read(notificationNotifierProvider.notifier)
                        .markRead(items[index].notificationId),
            ),
          );
        },
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const LoadingShimmer(height: 72),
        ),
        error: (error, _) => ErrorBanner(
          message: error.toString(),
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onMarkRead;

  const _NotificationTile({required this.notification, this.onMarkRead});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, h:mm a');
    final timeLabel = formatter.format(notification.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.surface
            : AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            notification.isRead
                ? Icons.notifications_none_rounded
                : Icons.notifications_active_rounded,
            color: notification.isRead
                ? AppColors.textSecondary
                : AppColors.info,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.title, style: AppTextStyles.heading3),
                const SizedBox(height: 6),
                Text(notification.body, style: AppTextStyles.bodySecondary),
                const SizedBox(height: 8),
                Text(timeLabel, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (onMarkRead != null)
            IconButton(
              icon: const Icon(Icons.done_rounded),
              color: AppColors.success,
              onPressed: onMarkRead,
              tooltip: 'Mark as read',
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text('No notifications yet', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'When something important happens, it will appear here.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
