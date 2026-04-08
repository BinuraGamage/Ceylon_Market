import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/order_provider.dart';
import '../../../shared/widgets/app_button.dart'
    show AppButton, AppButtonVariant;
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../home/widgets/customer_bottom_nav_bar.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  const OrderConfirmationScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(
          title: 'Order Confirmation',
          textStyle: AppTextStyles.heading2.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        centerTitle: false,
      ),
      body: ordersAsync.when(
        loading: () => const _LoadingView(),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(userOrdersProvider),
        ),
        data: (orders) {
          final order = orders.where((o) => o.orderId == orderId).firstOrNull;
          if (order == null) {
            return _ErrorView(
              message: 'Order not found',
              onRetry: () => ref.invalidate(userOrdersProvider),
            );
          }
          return _ConfirmationView(orderId: orderId, order: order);
        },
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 3),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: LoadingShimmer(height: 300));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ErrorBanner(message: message, onRetry: onRetry),
          const SizedBox(height: 16),
          AppButton(
            label: 'Go to Orders',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/order-history');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ConfirmationView extends StatelessWidget {
  const _ConfirmationView({required this.orderId, required this.order});

  final String orderId;
  final dynamic order;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success Icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text('Order Placed!', style: AppTextStyles.heading1),
            const SizedBox(height: 8),

            Text(
              'Your order has been successfully placed.',
              style: AppTextStyles.body.copyWith(color: AppColors.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Order ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Order ID: ', style: AppTextStyles.body),
                  Text(
                    '#${orderId.substring(0, 8)}',
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Total
            Text(
              'Total: LKR ${order.totalLKR.toStringAsFixed(2)}',
              style: AppTextStyles.price.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),

            // Payment Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: order.paymentStatus == 'paid'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                order.paymentStatus == 'paid'
                    ? 'Payment Complete'
                    : 'Awaiting Payment',
                style: AppTextStyles.bodySmall.copyWith(
                  color: order.paymentStatus == 'paid'
                      ? Colors.green
                      : Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Actions
            AppButton(
              label: 'View Order Details',
              onPressed: () => context.push('/order-detail/$orderId'),
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Continue Shopping',
              onPressed: () => context.go('/customer'),
              variant: AppButtonVariant.outline,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.push('/order-history'),
              child: Text(
                'View All Orders',
                style: AppTextStyles.body.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
