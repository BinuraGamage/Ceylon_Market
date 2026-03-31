import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../models/shop_model.dart';
import '../../../providers/product_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;

  /// M6 injects their customization widget via this parameter.
  /// Leave null until M6 passes it through the router.
  // TODO: Coordinate with M6 — they will pass this via GoRouter extras.
  final Widget? customizationWidget;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.customizationWidget,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Record product view for M3 Shop Analytics.
    // Using addPostFrameCallback so Riverpod reads happen after first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _recordView();
    });
  }

  Future<void> _recordView() async {
    try {
      // M3 contract — see AGENTS.md Section 9: M2 → M3 View Event Tracking.
      // TODO: Coordinate with M3 — replace with shopAnalyticsServiceProvider
      // when M3 has implemented it. For now we call incrementViewCount directly.
      await FirestoreService.instance
          .incrementViewCount(widget.productId);
    } catch (e) {
      // Non-critical — swallow silently.
      debugPrint('[ProductDetailScreen] recordView error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            backgroundColor: AppColors.background,
          ),
          body: ErrorBanner(
            message: 'Could not load product.',
            onRetry: () => ref.invalidate(productProvider(widget.productId)),
          ),
        ),
        data: (product) => _ProductDetailBody(
          product: product,
          currentImageIndex: _currentImageIndex,
          onImageChanged: (i) => setState(() => _currentImageIndex = i),
          customizationWidget: widget.customizationWidget,
        ),
      ),
    );
  }
}

// ── Main Body ─────────────────────────────────────────────────────────────────

class _ProductDetailBody extends ConsumerWidget {
  final ProductModel product;
  final int currentImageIndex;
  final ValueChanged<int> onImageChanged;
  final Widget? customizationWidget;

  const _ProductDetailBody({
    required this.product,
    required this.currentImageIndex,
    required this.onImageChanged,
    this.customizationWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── Image Gallery SliverAppBar ─────────────────────────────────
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: AppColors.background,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
            ),
          ),
          actions: [
            // Favourite button — M4 owns wishlist logic
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite_border_rounded,
                    color: AppColors.textPrimary, size: 20),
                onPressed: () {
                  // TODO: M4 — wishlist toggle
                },
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _ImageGallery(
              images: product.images,
              currentIndex: currentImageIndex,
              onPageChanged: onImageChanged,
            ),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & price
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      product.formattedPrice,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.priceColor,
                      ),
                    ),
                    const Spacer(),
                    if (product.reviewCount > 0) _RatingBadge(product: product),
                  ],
                ),
                const SizedBox(height: 12),

                // Category + stock status
                Row(
                  children: [
                    _Tag(label: ProductCategory.label(product.category)),
                    const SizedBox(width: 8),
                    _Tag(
                      label: product.isAvailable
                          ? 'In stock (${product.stock})'
                          : 'Out of stock',
                      isWarning: !product.isAvailable,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'About this product',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),

                // Materials / sizes / colors (if present)
                if (product.materials?.isNotEmpty == true)
                  _AttributeRow(
                    label: 'Materials',
                    values: product.materials!,
                  ),
                if (product.sizes?.isNotEmpty == true)
                  _AttributeRow(
                    label: 'Available sizes',
                    values: product.sizes!,
                  ),
                if (product.colors?.isNotEmpty == true)
                  _AttributeRow(
                    label: 'Available colors',
                    values: product.colors!,
                  ),

                // ── M7 AR Preview button slot ──────────────────────────
                // M7 owns ARPreviewButton — M2 conditionally renders it.
                if (product.isAREnabled && product.arModelUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      // TODO: M7 — Replace with ARPreviewButton widget:
                      // ARPreviewButton(
                      //   productId: product.productId,
                      //   modelUrl: product.arModelUrl!,
                      // )
                      child: const Row(
                        children: [
                          Icon(Icons.view_in_ar_rounded,
                              color: AppColors.primary),
                          SizedBox(width: 10),
                          Text(
                            'View in your space (AR)',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── M6 Customization widget slot ───────────────────────
                // M6 injects this via GoRouter extras when the product is customizable.
                if (product.customizable)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: customizationWidget ??
                        // Fallback placeholder until M6 delivers the widget.
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          // TODO: M6 — Replace placeholder with CustomizationWidget
                          child: const Row(
                            children: [
                              Icon(Icons.edit_rounded,
                                  color: AppColors.textSecondary, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Customization options coming soon',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                  ),

                // ── Shop preview ───────────────────────────────────────
                const SizedBox(height: 24),
                _ShopPreview(shopId: product.shopId),

                // Spacer for bottom bar
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Image Gallery ─────────────────────────────────────────────────────────────

class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _ImageGallery({
    required this.images,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return Container(
        color: AppColors.background,
        child: const Icon(Icons.image_not_supported_outlined,
            size: 64, color: AppColors.textHint),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          itemCount: images.length,
          onPageChanged: onPageChanged,
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: images[i],
            fit: BoxFit.cover,
            placeholder: (_, __) =>
                const LoadingShimmer(height: double.infinity),
            errorWidget: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: AppColors.textHint,
            ),
          ),
        ),
        // Page indicator
        if (images.length > 1)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == currentIndex ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == currentIndex
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Shop Preview ──────────────────────────────────────────────────────────────

class _ShopPreview extends ConsumerWidget {
  final String shopId;

  const _ShopPreview({required this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(shopProvider(shopId));

    return shopAsync.when(
      loading: () => const LoadingShimmer(height: 72),
      error: (_, __) => const SizedBox.shrink(),
      data: (ShopModel shop) => GestureDetector(
        onTap: () => context.goNamed(
          'shop',
          pathParameters: {'id': shop.shopId},
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              // Shop logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: shop.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: shop.logoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(Icons.storefront_rounded,
                        color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      shop.city,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Visit shop',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add to Cart Bottom Bar ────────────────────────────────────────────────────
// Displayed as a persistent bottom action bar via Scaffold.bottomNavigationBar.

class ProductDetailBottomBar extends ConsumerWidget {
  final ProductModel product;

  const ProductDetailBottomBar({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          // Price summary
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Price',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                product.formattedPrice,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.priceColor,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Add to cart button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: product.isAvailable
                  ? () {
                      // TODO: M5 — ref.read(cartNotifierProvider.notifier).addItem(...)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to cart'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: Text(
                  product.isAvailable ? 'Add to cart' : 'Out of stock'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _RatingBadge extends StatelessWidget {
  final ProductModel product;

  const _RatingBadge({required this.product});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: AppColors.starColor),
        const SizedBox(width: 2),
        Text(
          product.avgRating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          ' (${product.reviewCount})',
          style: const TextStyle(
              fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool isWarning;

  const _Tag({required this.label, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isWarning
            ? AppColors.error.withOpacity(0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isWarning
              ? AppColors.error.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isWarning ? AppColors.error : AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AttributeRow extends StatelessWidget {
  final String label;
  final List<String> values;

  const _AttributeRow({required this.label, required this.values});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: values
                .map((v) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        v,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const LoadingShimmer(height: 320, borderRadius: 0),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LoadingShimmer(height: 24, width: 240),
              const SizedBox(height: 10),
              const LoadingShimmer(height: 20, width: 100),
              const SizedBox(height: 20),
              LoadingShimmer(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.9),
              const SizedBox(height: 6),
              LoadingShimmer(
                  height: 14,
                  width: MediaQuery.of(context).size.width * 0.7),
            ],
          ),
        ),
      ],
    );
  }
}