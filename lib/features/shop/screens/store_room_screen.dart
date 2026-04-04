import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../models/shop_model.dart';
import '../widgets/video_player_widget.dart';

/// Public-facing store page — shows shop info, videos, and product grid.
/// M3 owns this file. Located at features/shop/screens/store_room_screen.dart
///
/// // TODO: Coordinate with M4 — product grid uses their ProductCard widget
class StoreRoomScreen extends ConsumerWidget {
  const StoreRoomScreen({super.key, required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopByIdProvider(shopId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: shopAsync.when(
        loading: () => const _StoreRoomShimmer(),
        error: (error, _) => Scaffold(
          body: Center(
            child: ErrorBanner(
              message: error.toString(),
              onRetry: () => ref.invalidate(shopByIdProvider(shopId)),
            ),
          ),
        ),
        data: (shop) {
          if (shop == null) {
            return const Scaffold(body: Center(child: Text('Shop not found.')));
          }
          return _StoreRoomContent(shop: shop);
        },
      ),
    );
  }
}

class _StoreRoomContent extends ConsumerWidget {
  const _StoreRoomContent({required this.shop});
  final ShopModel shop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── Top App Bar with Search ────────────────────────────────────
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
              onPressed: () {}, // Visual search placeholder — M7 feature
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
                // Logo
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.starColor,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      shop.avgRating.toStringAsFixed(1),
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () {
                      _showAboutPopup(context, shop);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    child: Text('About Us', style: AppTextStyles.button),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Video Strip ───────────────────────────────────────────────
        if (shop.videoUrls != null && shop.videoUrls!.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 240, // 9:16 scaled down
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: shop.videoUrls!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final videoUrl = shop.videoUrls![index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 140, // 9:16 scaled down
                      color: AppColors.surface,
                      child: VideoPlayerWidget(
                        videoUrl: videoUrl,
                        showFullScreenButton: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (shop.videoUrls != null && shop.videoUrls!.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(height: 32, color: AppColors.border),
            ),
          ),

        // ── Product Grid ──────────────────────────────────────────────
        // TODO: Coordinate with M4 — they own ProductCard widget
        _ShopProductGrid(shopId: shop.shopId),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

void _showAboutPopup(BuildContext context, ShopModel shop) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('About ${shop.name}', style: AppTextStyles.heading2),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (shop.story.isNotEmpty) ...[
                Text('Our Story', style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(shop.story, style: AppTextStyles.body),
                const SizedBox(height: 16),
              ],
              Text('Categories', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: shop.categories
                    .map(
                      (c) => Chip(
                        label: Text(
                          c,
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textOnPrimary,
                          ),
                        ),
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('Location', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${shop.address}\n${shop.city}',
                      style: AppTextStyles.body,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Contact', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              if (shop.contactPhone != null && shop.contactPhone!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.phone, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(shop.contactPhone!, style: AppTextStyles.body),
                  ],
                ),
              if (shop.contactEmail != null && shop.contactEmail!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(shop.contactEmail!, style: AppTextStyles.body),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      );
    },
  );
}

/// Sliver product grid for a specific shop.
class _ShopProductGrid extends ConsumerWidget {
  const _ShopProductGrid({required this.shopId});
  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shopId));

    return productsAsync.when(
      loading: () => SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const _ProductPlaceholderCard(),
            childCount: 4,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorBanner(message: e.toString()),
        ),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No products available in this shop yet.',
                  style: AppTextStyles.body,
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: products[index]),
              childCount: products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder until M4's ProductCard widget is integrated.
class _ProductPlaceholderCard extends StatelessWidget {
  const _ProductPlaceholderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: Container(
                color: AppColors.border,
                width: double.infinity,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textSecondary,
                  size: 40,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 80, color: AppColors.border),
                const SizedBox(height: 4),
                Container(height: 10, width: 50, color: AppColors.border),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(height: 14, width: 60, color: AppColors.border),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textOnPrimary,
                        size: 16,
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

/// Shimmer loading state for the store room.
class _StoreRoomShimmer extends StatelessWidget {
  const _StoreRoomShimmer();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Column(children: [SizedBox(height: 60), LoadingShimmer()]),
      ),
    );
  }
}
