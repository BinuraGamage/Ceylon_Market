import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../providers/shop_provider.dart';
import '../../../models/shop_model.dart';

/// Seller-only dashboard — shows order summary, order list, and shop controls.
/// M3 owns this file. Located at features/shop/screens/seller_dashboard_screen.dart
class SellerDashboardScreen extends ConsumerWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(myShopProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: shopAsync.when(
        loading: () => const Center(child: LoadingShimmer()),
        error: (e, _) => Center(
          child: ErrorBanner(
            message: e.toString(),
            onRetry: () => ref.invalidate(myShopProvider),
          ),
        ),
        data: (shop) {
          if (shop == null) {
            return const _NoShopState();
          }
          return _DashboardContent(shop: shop);
        },
      ),
      bottomNavigationBar: _SellerNavBar(),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.shop});
  final ShopModel shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(orderSummaryProvider);

    return CustomScrollView(
      slivers: [
        // ── App Bar ───────────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: AppColors.background,
          floating: true,
          pinned: false,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: CircleAvatar(
              backgroundImage: shop.logoUrl != null
                  ? CachedNetworkImageProvider(shop.logoUrl!)
                  : null,
              backgroundColor: AppColors.surface,
              child: shop.logoUrl == null
                  ? const Icon(Icons.person, color: AppColors.textSecondary)
                  : null,
            ),
          ),
          title: GestureDetector(
            onTap: () => context.goNamed('search'),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 8),
                  Text('Search Store',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.textPrimary),
              onPressed: () {},
            ),
          ],
        ),

        // ── Shop Header ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border:
                            Border.all(color: AppColors.primary, width: 3),
                      ),
                      child: ClipOval(
                        child: shop.logoUrl != null
                            ? CachedNetworkImage(
                                imageUrl: shop.logoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const LoadingShimmer(),
                                errorWidget: (_, __, ___) =>
                                    const Icon(Icons.store, size: 40),
                              )
                            : const Icon(Icons.store,
                                size: 40, color: AppColors.primary),
                      ),
                    ),
                    // Edit logo button
                    GestureDetector(
                      onTap: () => context.goNamed('edit-shop',
                          pathParameters: {'id': shop.shopId}),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.add,
                            size: 16, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(shop.name, style: AppTextStyles.heading1),
                const SizedBox(height: 4),
                Text(
                  shop.story,
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _OutlineButton(
                      label: 'About Us',
                      onTap: () => context.goNamed('shop-about',
                          pathParameters: {'id': shop.shopId}),
                    ),
                    const SizedBox(width: 12),
                    _OutlineButton(
                      label: 'My Insights',
                      onTap: () => context.goNamed('seller-insights'),
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Order Summary Cards ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order Summary', style: AppTextStyles.heading2),
                const SizedBox(height: 12),
                summaryAsync.when(
                  loading: () => const LoadingShimmer(),
                  error: (e, _) => ErrorBanner(message: e.toString()),
                  data: (summary) => Row(
                    children: [
                      _SummaryCard(
                          label: 'All Orders',
                          value: summary['all'] ?? 0),
                      const SizedBox(width: 8),
                      _SummaryCard(
                          label: 'Pending',
                          value: summary['pending'] ?? 0),
                      const SizedBox(width: 8),
                      _SummaryCard(
                          label: 'Shipped',
                          value: summary['shipped'] ?? 0),
                      const SizedBox(width: 8),
                      _SummaryCard(
                          label: 'Cancelled',
                          value: summary['cancelled'] ?? 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Order Filter Tabs ─────────────────────────────────────────
        SliverPersistentHeader(
          pinned: true,
          delegate: _OrderFilterTabDelegate(),
        ),

        // ── Order List ────────────────────────────────────────────────
        const _OrderList(),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ── Order Filter Tab Bar ──────────────────────────────────────────────────

class _OrderFilterTabDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Consumer(
      builder: (context, ref, _) {
        final current = ref.watch(orderFilterProvider);
        final filters = ['all', 'new', 'processing', 'pending'];
        final labels = ['All Orders', 'New Orders', 'Processing', 'Pending'];

        return Container(
          color: AppColors.background,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: List.generate(filters.length, (i) {
                final selected = current == filters[i];
                return GestureDetector(
                  onTap: () => ref
                      .read(orderFilterProvider.notifier)
                      .state = filters[i],
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          labels[i],
                          style: AppTextStyles.label.copyWith(
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (selected)
                          Container(
                            height: 2,
                            width: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}

// ── Order List ─────────────────────────────────────────────────────────────

class _OrderList extends ConsumerWidget {
  const _OrderList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(shopOrdersProvider);

    return ordersAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: LoadingShimmer(),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorBanner(message: e.toString()),
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyOrders(),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _OrderTile(order: orders[index]),
            childCount: orders.length,
          ),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final Map<String, dynamic> order;

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'processing':
        return AppColors.info;
      case 'shipped':
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statusLabel(String status) =>
      status[0].toUpperCase() + status.substring(1);

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final total = (order['totalLKR'] as num?)?.toDouble() ?? 0;
    final orderId = order['orderId'] as String? ?? '';
    final createdAt = order['createdAt'] != null
        ? (order['createdAt'] as dynamic).toDate() as DateTime
        : DateTime.now();

    // Get first item thumbnail from order snapshot
    final items = List<Map<String, dynamic>>.from(order['items'] as List? ?? []);
    final firstName = items.isNotEmpty
        ? items.first['name'] as String? ?? 'Product'
        : 'Product';
    final thumbUrl = items.isNotEmpty ? items.first['thumbnailUrl'] as String? : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          // Delete (soft) button
          GestureDetector(
            onTap: () {
              // Soft-delete: sets status to cancelled — never deletes the doc
              // TODO: confirm dialog before cancelling
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          // Product thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: thumbUrl != null
                ? CachedNetworkImage(
                    imageUrl: thumbUrl,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const LoadingShimmer(),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image, size: 32),
                  )
                : Container(
                    width: 64,
                    height: 64,
                    color: AppColors.surface,
                    child: const Icon(Icons.image_outlined,
                        color: AppColors.textSecondary),
                  ),
          ),
          const SizedBox(width: 12),
          // Order details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(firstName, style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(
                  '#${orderId.substring(0, 6).toUpperCase()}  –  '
                  '${DateFormat('d MMM yyyy').format(createdAt)}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LKR ${total.toStringAsFixed(0)}',
                      style: AppTextStyles.price,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: _statusColor(status), width: 1.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(status),
                        style: AppTextStyles.caption.copyWith(
                          color: _statusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(label,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('$value',
                style: AppTextStyles.heading2
                    .copyWith(color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: filled ? AppColors.primary : AppColors.primary),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
              color:
                  filled ? AppColors.textOnPrimary : AppColors.primary),
        ),
      ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined,
              size: 56, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text('No orders yet', style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(
            'Orders from your customers will appear here.',
            style:
                AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoShopState extends StatelessWidget {
  const _NoShopState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.store_mall_directory_outlined,
              size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          Text("You don't have a shop yet.",
              style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => context.goNamed('seller-register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: const Text('Create My Shop'),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Nav Bar ─────────────────────────────────────────────────────────

class _SellerNavBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            onTap: () => context.goNamed('seller-dashboard'),
          ),
          _NavItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add',
            onTap: () => context.goNamed('add-product'),
            // TODO: Coordinate with M4 — they own product upload screen
          ),
          _NavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Alerts',
            onTap: () => context.goNamed('notifications'),
            // TODO: Coordinate with M7 — they own notifications
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}