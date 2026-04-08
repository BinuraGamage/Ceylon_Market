import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/order_model.dart';
import '../../../providers/order_provider.dart' as order_prov;
import '../../../providers/shop_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class SellerOrderManagementScreen extends ConsumerWidget {
  const SellerOrderManagementScreen({super.key});

  void _goBackToSellerDashboard(BuildContext context) {
    context.goNamed('seller-dashboard');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(myShopProvider);

    return shopAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: ErrorBanner(message: 'Failed to load shop: ${error.toString()}'),
      ),
      data: (shop) {
        if (shop == null) {
          return const Scaffold(
            body: Center(
              child: Text('No shop found. Please create a shop first.'),
            ),
          );
        }

        final ordersAsync = ref.watch(
          order_prov.shopOrdersProviderOrder(shop.shopId),
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _goBackToSellerDashboard(context);
          },
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => _goBackToSellerDashboard(context),
              ),
              title: AppLogoTitle(
                title: 'Order Management',
                textStyle: AppTextStyles.heading2.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              centerTitle: false,
            ),
            body: ordersAsync.when(
              loading: () => const _OrdersLoadingView(),
              error: (error, stack) => ErrorBanner(
                message: 'Failed to load orders: ${error.toString()}',
              ),
              data: (orders) => orders.isEmpty
                  ? const _EmptyOrdersView()
                  : _OrdersListView(orders: orders),
            ),
          ),
        );
      },
    );
  }
}

class _OrdersLoadingView extends StatelessWidget {
  const _OrdersLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LoadingShimmer(height: 200),
      ),
    );
  }
}

class _EmptyOrdersView extends StatelessWidget {
  const _EmptyOrdersView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.outline),
          const SizedBox(height: 16),
          Text('No orders yet', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Orders from customers will appear here',
            style: AppTextStyles.body.copyWith(color: AppColors.outline),
          ),
        ],
      ),
    );
  }
}

class _OrdersListView extends ConsumerWidget {
  const _OrdersListView({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderNotifier = ref.watch(order_prov.orderNotifierProvider.notifier);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _OrderCard(
            order: order,
            onStatusUpdate: (status) => orderNotifier.updateOrderStatus(
              orderId: order.orderId,
              status: status,
            ),
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onStatusUpdate});

  final OrderModel order;
  final ValueChanged<String> onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(order.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderId.substring(0, 8)}',
                  style: AppTextStyles.bodyLarge,
                ),
                Text(
                  _formatDate(order.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer: ${order.customerId.substring(0, 8)}',
                  style: AppTextStyles.body,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Items
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item['name']} x${item['quantity']}',
                        style: AppTextStyles.body,
                      ),
                    ),
                    Text(
                      'LKR ${(item['price'] * item['quantity']).toStringAsFixed(2)}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 24),

            // Total and Shipping
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.bodyLarge),
                Text(
                  'LKR ${order.totalLKR.toStringAsFixed(2)}',
                  style: AppTextStyles.price,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Shipping: ${order.shippingAddress['line1']}, ${order.shippingAddress['city']}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
            ),

            // Status Update Actions
            if (order.status != 'delivered' && order.status != 'cancelled') ...[
              const SizedBox(height: 16),
              _StatusUpdateActions(
                currentStatus: order.status,
                onStatusUpdate: onStatusUpdate,
              ),
            ],
          ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _StatusUpdateActions extends StatelessWidget {
  const _StatusUpdateActions({
    required this.currentStatus,
    required this.onStatusUpdate,
  });

  final String currentStatus;
  final ValueChanged<String> onStatusUpdate;

  @override
  Widget build(BuildContext context) {
    final nextStatuses = _getNextStatuses(currentStatus);

    if (nextStatuses.isEmpty) return const SizedBox.shrink();

    return Row(
      children: nextStatuses.map((status) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AppButton(
              label: status.toUpperCase(),
              onPressed: () => onStatusUpdate(status),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<String> _getNextStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return ['confirmed', 'cancelled'];
      case 'confirmed':
        return ['processing'];
      case 'processing':
        return ['shipped'];
      case 'shipped':
        return ['delivered'];
      default:
        return [];
    }
  }
}
