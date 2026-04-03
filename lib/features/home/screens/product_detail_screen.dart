import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  final Widget? customizationWidget;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.customizationWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('customer-home');
            }
          },
        ),
      ),
      body: productAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (_, __) => ErrorBanner(
          message: 'Could not load product.',
          onRetry: () => ref.invalidate(productProvider(productId)),
        ),
        data: (product) => _ProductContent(
          product: product,
          customizationWidget: customizationWidget,
        ),
      ),
    );
  }
}

class _ProductContent extends StatelessWidget {
  final ProductModel product;
  final Widget? customizationWidget;

  const _ProductContent({
    required this.product,
    this.customizationWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: product.images.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: product.images.first,
                  fit: BoxFit.cover,
                  height: 280,
                  placeholder: (_, __) => const LoadingShimmer(height: 280),
                  errorWidget: (_, __, ___) => const SizedBox(
                    height: 280,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                )
              : const SizedBox(
                  height: 280,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: AppColors.textHint,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16),
        Text(
          product.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.formattedPrice,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.priceColor,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          product.description,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
        if (product.customizable) ...[
          const SizedBox(height: 18),
          customizationWidget ??
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
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
        ],
      ],
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: const [
        LoadingShimmer(height: 280, borderRadius: 14),
        SizedBox(height: 16),
        LoadingShimmer(height: 24, width: 220),
        SizedBox(height: 10),
        LoadingShimmer(height: 20, width: 120),
        SizedBox(height: 14),
        LoadingShimmer(height: 14),
        SizedBox(height: 8),
        LoadingShimmer(height: 14),
      ],
    );
  }
}
