import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart';
import '../../../shared/widgets/app_button.dart' show AppButton, AppButtonVariant;
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../home/widgets/customer_bottom_nav_bar.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: LoadingShimmer(height: 300)),
        error: (error, stack) => ErrorBanner(
          message: error.toString(),
          onRetry: () => ref.invalidate(userOrdersProvider),
        ),
        data: (orders) {
          final order = orders.where((o) => o.orderId == orderId).firstOrNull;
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }
          return _OrderDetailView(order: order);
        },
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 4),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Order Header
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order #${order.orderId.substring(0, 8)}', style: AppTextStyles.heading3),
                  _StatusBadge(status: order.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Placed on ${_formatDate(order.createdAt)}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Order Items
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'] ?? 'Product', style: AppTextStyles.bodyLarge),
                          if (item['selectedColor'] != null || item['selectedSize'] != null)
                            Text(
                              [item['selectedColor'], item['selectedSize']]
                                  .where((e) => e != null)
                                  .join(' • '),
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                            ),
                          Text('Qty: ${item['quantity']}', style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    Text(
                      'LKR ${((item['price'] as num) * (item['quantity'] as int)).toStringAsFixed(2)}',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Shipping Address
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shipping Address', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Text(order.shippingAddress['line1'] ?? '', style: AppTextStyles.body),
              if (order.shippingAddress['city'] != null)
                Text(
                  '${order.shippingAddress['city']}${order.shippingAddress['district'] != null ? ', ${order.shippingAddress['district']}' : ''}',
                  style: AppTextStyles.body,
                ),
              if (order.shippingAddress['postalCode'] != null)
                Text('Postal Code: ${order.shippingAddress['postalCode']}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Info
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Payment', style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text('LKR ${order.totalLKR.toStringAsFixed(2)}'),
                ],
              ),
              if (order.discountLKR > 0) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Discount${order.promoCode != null ? ' (${order.promoCode})' : ''}'),
                    Text('-LKR ${order.discountLKR.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: AppTextStyles.heading3),
                  Text(
                    'LKR ${(order.totalLKR + order.discountLKR).toStringAsFixed(2)}',
                    style: AppTextStyles.price,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    order.paymentStatus == 'paid' ? Icons.check_circle : Icons.pending,
                    color: order.paymentStatus == 'paid' ? Colors.green : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.paymentStatus == 'paid' ? 'Payment Complete' : 'Awaiting Payment',
                    style: AppTextStyles.body.copyWith(
                      color: order.paymentStatus == 'paid' ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              if (order.paymentRef != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Ref: ${order.paymentRef}',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Back Button
        AppButton(
          label: 'Back to Orders',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/order-history');
            }
          },
          variant: AppButtonVariant.outline,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTextStyles.bodySmall.copyWith(
          color: _getStatusColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'shipped':
        return Colors.indigo;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return AppColors.outline;
    }
  }
}
