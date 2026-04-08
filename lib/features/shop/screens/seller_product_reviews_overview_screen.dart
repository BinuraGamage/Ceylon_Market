import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/product_model.dart';
import '../../../models/review_model.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

/// Product-wise customer reviews page for sellers.
class SellerProductReviewsOverviewScreen extends ConsumerWidget {
  const SellerProductReviewsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Product Reviews', style: AppTextStyles.heading2),
      ),
      body: productsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) => const LoadingShimmer(height: 120),
        ),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: error.toString(),
            onRetry: () => ref.invalidate(sellerProductsProvider),
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products found for your shop yet.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _ProductReviewSection(product: products[index]),
          );
        },
      ),
    );
  }
}

class _ProductReviewSection extends ConsumerWidget {
  const _ProductReviewSection({required this.product});

  final ProductModel product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(product.productId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: _ProductImage(url: product.thumbnailUrl),
        title: Text(
          product.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.heading3,
        ),
        subtitle: Text(
          'Avg ${product.avgRating.toStringAsFixed(1)} • ${product.reviewCount} reviews',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        children: [
          reviewsAsync.when(
            loading: () => const LoadingShimmer(height: 88),
            error: (error, _) => ErrorBanner(message: error.toString()),
            data: (reviews) {
              if (reviews.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No customer reviews for this product yet.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }

              final averageRating =
                  reviews
                      .map((review) => review.rating)
                      .fold<int>(0, (sum, rating) => sum + rating) /
                  reviews.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Average rating: ${averageRating.toStringAsFixed(1)} from ${reviews.length} customers',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...reviews.map((review) => _ReviewTile(review: review)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_outlined, color: AppColors.textSecondary),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        placeholder: (context, imageUrl) =>
            const LoadingShimmer(height: 44, width: 44),
        errorWidget: (context, imageUrl, error) => Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(review.customerName, style: AppTextStyles.label),
              ),
              Text(
                DateFormat('d MMM yyyy').format(review.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 16,
                color: AppColors.starColor,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            review.comment.isEmpty ? 'No written comment.' : review.comment,
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
