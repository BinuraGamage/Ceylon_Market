import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../providers/shop_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../models/shop_model.dart';
import '../../../providers/product_provider.dart';
import '../widgets/video_player_widget.dart';
import '../../../models/offer_model.dart';

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

void _showLogoutDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Log Out', style: AppTextStyles.heading2),
      content: const Text(
        'Are you sure you want to log out of Ceylon Market?',
        style: AppTextStyles.body,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: AppTextStyles.button.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context); // Close dialog
            await ref.read(authNotifierProvider.notifier).signOut();
            if (context.mounted) {
              context.goNamed('login');
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.surface,
            elevation: 0,
          ),
          child: const Text('Log Out', style: AppTextStyles.button),
        ),
      ],
    ),
  );
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
            child: GestureDetector(
              onTap: () => _showLogoutDialog(context, ref),
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
                  const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Search Store',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.textPrimary,
              ),
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
                        border: Border.all(color: AppColors.primary, width: 3),
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
                            : const Icon(
                                Icons.store,
                                size: 40,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                    // Edit logo button
                    GestureDetector(
                      onTap: () => context.goNamed(
                        'edit-shop',
                        pathParameters: {'id': shop.shopId},
                      ),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(shop.name, style: AppTextStyles.heading1),
                const SizedBox(height: 4),
                Text(
                  shop.story,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _OutlineButton(
                      label: 'About Us',
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              _EditShopDetailsDialog(shop: shop),
                        );
                      },
                    ),
                    _OutlineButton(
                      label: 'My Insights',
                      onTap: () => context.goNamed('seller-insights'),
                      filled: true,
                    ),
                    _OutlineButton(
                      label: 'Create Offer',
                      onTap: () {
                        ref.invalidate(
                          sellerProductsByShopProvider(shop.shopId),
                        );
                        showDialog(
                          context: context,
                          builder: (context) => _CreateOfferDialog(shop: shop),
                        );
                      },
                      filled: false,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Upload Video Button & Video ScrollView ────────────
                _ShopVideosList(shop: shop),
                const SizedBox(height: 20),

                // ── Shop Offers ───────────────────────────────────────
                _OffersList(shop: shop),
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
                        value: summary['all'] ?? 0,
                      ),
                      const SizedBox(width: 8),
                      _SummaryCard(
                        label: 'Pending',
                        value: summary['pending'] ?? 0,
                      ),
                      const SizedBox(width: 8),
                      _SummaryCard(
                        label: 'Shipped',
                        value: summary['shipped'] ?? 0,
                      ),
                      const SizedBox(width: 8),
                      _SummaryCard(
                        label: 'Cancelled',
                        value: summary['cancelled'] ?? 0,
                      ),
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
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
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
                  onTap: () =>
                      ref.read(orderFilterProvider.notifier).state = filters[i],
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
        child: Padding(padding: EdgeInsets.all(20), child: LoadingShimmer()),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ErrorBanner(message: e.toString()),
        ),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return SliverToBoxAdapter(child: _EmptyOrders());
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
    final items = List<Map<String, dynamic>>.from(
      order['items'] as List? ?? [],
    );
    final firstName = items.isNotEmpty
        ? items.first['name'] as String? ?? 'Product'
        : 'Product';
    final thumbUrl = items.isNotEmpty
        ? items.first['thumbnailUrl'] as String?
        : null;

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
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 18,
              ),
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
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.textSecondary,
                    ),
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
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _statusColor(status),
                          width: 1.5,
                        ),
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
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: filled ? AppColors.primary : AppColors.primary,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(
            color: filled ? AppColors.textOnPrimary : AppColors.primary,
          ),
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
          const Icon(
            Icons.inbox_outlined,
            size: 56,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text('No orders yet', style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(
            'Orders from your customers will appear here.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
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
          const Icon(
            Icons.store_mall_directory_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text("You don't have a shop yet.", style: AppTextStyles.heading2),
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
            icon: Icons.inventory_2_outlined,
            label: 'Products',
            onTap: () => context.pushNamed('seller-products'),
          ),
          _NavItem(
            icon: Icons.receipt_long_outlined,
            label: 'Orders',
            onTap: () => context.goNamed('seller-orders'),
          ),
          _NavItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add',
            onTap: () => context.pushNamed('seller-product-create'),
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
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
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
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Edit Shop Details Dialog ───────────────────────────────────────────────

class _EditShopDetailsDialog extends ConsumerStatefulWidget {
  final ShopModel shop;
  const _EditShopDetailsDialog({required this.shop});

  @override
  ConsumerState<_EditShopDetailsDialog> createState() =>
      _EditShopDetailsDialogState();
}

class _EditShopDetailsDialogState
    extends ConsumerState<_EditShopDetailsDialog> {
  late final TextEditingController _storyController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _storyController = TextEditingController(text: widget.shop.story);
    _addressController = TextEditingController(text: widget.shop.address);
    _phoneController = TextEditingController(
      text: widget.shop.contactPhone ?? '',
    );
    _emailController = TextEditingController(
      text: widget.shop.contactEmail ?? '',
    );
  }

  @override
  void dispose() {
    _storyController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(shopServiceProvider).updateShop(widget.shop.shopId, {
        'story': _storyController.text.trim(),
        'address': _addressController.text.trim(),
        'contactPhone': _phoneController.text.trim(),
        'contactEmail': _emailController.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop details updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit Shop Details', style: AppTextStyles.heading2),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                controller: _storyController,
                label: 'Story',
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              AppTextField(controller: _addressController, label: 'Address'),
              const SizedBox(height: 12),
              AppTextField(
                controller: _phoneController,
                label: 'Contact Phone',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _emailController,
                label: 'Contact Email',
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// ── Shop Videos Section ────────────────────────────────────────────────────

class _ShopVideosList extends ConsumerStatefulWidget {
  final ShopModel shop;
  const _ShopVideosList({required this.shop});

  @override
  ConsumerState<_ShopVideosList> createState() => _ShopVideosListState();
}

class _ShopVideosListState extends ConsumerState<_ShopVideosList> {
  bool _isUploading = false;

  Future<void> _deleteVideo(String videoUrl) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref
          .read(shopServiceProvider)
          .deleteShopVideo(widget.shop.shopId, videoUrl);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Video deleted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete video: $e')));
      }
    }
  }

  Future<void> _uploadVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    try {
      final file = File(pickedFile.path);
      await ref
          .read(shopServiceProvider)
          .uploadShopVideo(widget.shop.shopId, file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload video: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final videos = widget.shop.videoUrls ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Shop Shorts', style: AppTextStyles.heading2),
            if (_isUploading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              GestureDetector(
                onTap: _uploadVideo,
                child: Row(
                  children: [
                    const Icon(
                      Icons.video_call_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Upload',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (videos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'No videos uploaded yet.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final videoUrl = videos[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 140, // roughly 9:16 scaled down
                          color: AppColors.surface,
                          child: VideoPlayerWidget(
                            videoUrl: videoUrl,
                            showFullScreenButton: true,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _deleteVideo(videoUrl),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Shop Offers ──────────────────────────────────────────────────────────

class _OffersList extends ConsumerWidget {
  final ShopModel shop;
  const _OffersList({required this.shop});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active':
        return AppColors.success;
      case 'Scheduled':
        return AppColors.info;
      case 'Expired':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _deleteOffer(
    BuildContext context,
    WidgetRef ref,
    OfferModel offer,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Offer'),
        content: const Text('Are you sure you want to delete this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(firestoreServiceProvider).deleteOffer(offer.id);
        ref.invalidate(shopOffersProvider(offer.shopId));
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Offer deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(shopOffersProvider(shop.shopId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Offers', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        offersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
          data: (offers) {
            if (offers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No offers created yet.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: offers.length,
              itemBuilder: (context, index) {
                final offer = offers[index];
                final discountDisplay = offer.isPercentage
                    ? '${offer.discountValue.toStringAsFixed(0)}% OFF'
                    : 'LKR ${offer.discountValue.toStringAsFixed(0)} OFF';
                final duration =
                    '${DateFormat('MMM d').format(offer.startDate)} - ${DateFormat('MMM d').format(offer.endDate)}';
                final status = offer.status;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(offer.title, style: AppTextStyles.label),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      status,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    status,
                                    style: AppTextStyles.caption.copyWith(
                                      color: _getStatusColor(status),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              discountDisplay,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Duration: $duration',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Products: ${offer.productIds.length} products applied',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: AppColors.textPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              ref.invalidate(
                                sellerProductsByShopProvider(shop.shopId),
                              );
                              showDialog(
                                context: context,
                                builder: (context) => _CreateOfferDialog(
                                  shop: shop,
                                  offerToEdit: offer,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppColors.error,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _deleteOffer(context, ref, offer),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ── Create Offer Dialog ───────────────────────────────────────────────────

class _CreateOfferDialog extends ConsumerStatefulWidget {
  final ShopModel shop;
  final OfferModel? offerToEdit;
  const _CreateOfferDialog({required this.shop, this.offerToEdit});

  @override
  ConsumerState<_CreateOfferDialog> createState() => _CreateOfferDialogState();
}

class _CreateOfferDialogState extends ConsumerState<_CreateOfferDialog> {
  final _titleController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minQtyController = TextEditingController();

  List<String> _selectedProductIds = [];
  bool _isPercentage = true;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.offerToEdit != null) {
      final o = widget.offerToEdit!;
      _titleController.text = o.title;
      _discountValueController.text = o.discountValue.toString();
      _minQtyController.text = o.minQty?.toString() ?? '';
      _selectedProductIds = List.from(o.productIds);
      _isPercentage = o.isPercentage;
      _startDate = o.startDate;
      _endDate = o.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _discountValueController.dispose();
    _minQtyController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          if (isStart) {
            _startDate = picked;
          } else {
            _endDate = picked;
          }
        });
      }
    }
  }

  void _saveOffer() async {
    if (_titleController.text.trim().isEmpty ||
        _selectedProductIds.isEmpty ||
        _discountValueController.text.trim().isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final val = double.tryParse(_discountValueController.text.trim()) ?? 0;
      final minQ = int.tryParse(_minQtyController.text.trim());

      final offer = OfferModel(
        id: widget.offerToEdit?.id ?? '',
        shopId: widget.shop.shopId,
        title: _titleController.text.trim(),
        productIds: _selectedProductIds,
        isPercentage: _isPercentage,
        discountValue: val,
        startDate: _startDate!,
        endDate: _endDate!,
        minQty: minQ,
      );

      final service = ref.read(firestoreServiceProvider);
      if (widget.offerToEdit != null) {
        await service.updateOffer(offer);
      } else {
        await service.createOffer(offer);
      }

      ref.invalidate(shopOffersProvider(widget.shop.shopId));

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.offerToEdit != null
                  ? 'Offer updated successfully!'
                  : 'Offer created successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      sellerProductsByShopProvider(widget.shop.shopId),
    );
    final val = double.tryParse(_discountValueController.text.trim()) ?? 0;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Create Offer', style: AppTextStyles.heading2),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                controller: _titleController,
                label: 'Offer Title (e.g., New Year Sale)',
              ),
              const SizedBox(height: 16),
              const Text('Select Products', style: AppTextStyles.label),
              const SizedBox(height: 8),

              // Products list (Multi-Select)
              productsAsync.when(
                loading: () => const LoadingShimmer(),
                error: (e, _) => ErrorBanner(message: e.toString()),
                data: (products) {
                  if (products.isEmpty) {
                    return const Text('No products available.');
                  }
                  return Container(
                    height: 120,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final isSelected = _selectedProductIds.contains(
                          product.productId,
                        );
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(product.name, style: AppTextStyles.body),
                          activeColor: AppColors.primary,
                          dense: true,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedProductIds.add(product.productId);
                              } else {
                                _selectedProductIds.remove(product.productId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Discount Type
              const Text('Discount Type', style: AppTextStyles.label),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      value: true,
                      groupValue: _isPercentage,
                      title: const Text('%', style: AppTextStyles.body),
                      onChanged: (v) => setState(() => _isPercentage = v!),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      value: false,
                      groupValue: _isPercentage,
                      title: const Text('Fixed', style: AppTextStyles.body),
                      onChanged: (v) => setState(() => _isPercentage = v!),
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              AppTextField(
                controller: _discountValueController,
                label: _isPercentage ? 'Discount (%)' : 'Discount (LKR)',
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() {}),
              ),

              Builder(
                builder: (context) {
                  final selectedList =
                      productsAsync.valueOrNull
                          ?.where(
                            (p) => _selectedProductIds.contains(p.productId),
                          )
                          .toList() ??
                      [];
                  if (selectedList.isNotEmpty && val > 0) {
                    final oldPrice = selectedList.first.price;
                    final newPrice = _isPercentage
                        ? oldPrice - (oldPrice * val / 100)
                        : oldPrice - val;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Preview (${selectedList.first.name}):',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'LKR ${oldPrice.toStringAsFixed(0)} ➔ LKR ${newPrice < 0 ? 0 : newPrice.toStringAsFixed(0)}',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              const SizedBox(height: 16),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _startDate == null
                              ? 'Start Date'
                              : DateFormat('MMM d, yyyy').format(_startDate!),
                          style: AppTextStyles.body,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _endDate == null
                              ? 'End Date'
                              : DateFormat('MMM d, yyyy').format(_endDate!),
                          style: AppTextStyles.body,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              AppTextField(
                controller: _minQtyController,
                label: 'Minimum Quantity (Optional)',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveOffer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
