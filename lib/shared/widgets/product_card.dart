import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../features/customization/widgets/product_customization_widget.dart';
import '../../models/product_model.dart';
import '../../models/shop_model.dart';
import '../../providers/product_provider.dart';
import 'loading_shimmer.dart';

/// Reusable product card — used on home, search, and category screens.
/// Navigates to /product/:id on tap.
/// Never put business logic here — this is purely presentational.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double width;

  const ProductCard({super.key, required this.product, this.width = 160});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = width.isFinite
            ? width
            : (constraints.maxWidth.isFinite ? constraints.maxWidth : 160.0);
        final imageHeight = resolvedWidth * 0.85;

        return GestureDetector(
          onTap: () => context.pushNamed(
            'product-detail',
            pathParameters: {'id': product.productId},
            extra: product.customizable
                ? ProductCustomizationWidget(product: product)
                : null,
          ),
          child: Container(
            width: resolvedWidth,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.cardShadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Thumbnail ───────────────────────────────────────────────
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: product.thumbnailUrl,
                    height: imageHeight,
                    width: resolvedWidth,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        const LoadingShimmer(height: double.infinity),
                    errorWidget: (context, url, error) => Container(
                      height: imageHeight,
                      color: AppColors.background,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ),
                // ── Info ────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.priceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _ShopLogoRow(shopId: product.shopId),
                      const SizedBox(height: 6),
                      _RatingRow(product: product),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShopLogoRow extends ConsumerWidget {
  final String shopId;

  const _ShopLogoRow({required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopProvider(shopId));

    return shopAsync.maybeWhen(
      data: (ShopModel shop) => GestureDetector(
        onTap: () =>
            context.pushNamed('shop', pathParameters: {'id': shop.shopId}),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: shop.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: shop.logoUrl!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      'assets/icon.png',
                      height: 10,
                      width: 10,
                      fit: BoxFit.contain,
                    ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                shop.name,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      orElse: () => const SizedBox(height: 16),
    );
  }
}

class _RatingRow extends StatelessWidget {
  final ProductModel product;

  const _RatingRow({required this.product});

  @override
  Widget build(BuildContext context) {
    if (product.reviewCount == 0) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 12, color: AppColors.starColor),
        const SizedBox(width: 2),
        Text(
          product.avgRating.toStringAsFixed(1),
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 2),
        Text(
          '(${product.reviewCount})',
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }
}

/// Wide version of the card — used in search results list view.
class ProductListTile extends StatelessWidget {
  final ProductModel product;

  const ProductListTile({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed(
        'product-detail',
        pathParameters: {'id': product.productId},
        extra: product.customizable
            ? ProductCustomizationWidget(product: product)
            : null,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.thumbnailUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const LoadingShimmer(height: 72, width: 72),
                errorWidget: (context, url, error) => Container(
                  width: 72,
                  height: 72,
                  color: AppColors.background,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.formattedPrice,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.priceColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (product.reviewCount > 0) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppColors.starColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.avgRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  _ShopLogoRow(shopId: product.shopId),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
