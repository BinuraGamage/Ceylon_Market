import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../home/widgets/customer_bottom_nav_bar.dart';

class ProductReviewsScreen extends ConsumerStatefulWidget {
  const ProductReviewsScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductReviewsScreen> createState() =>
      _ProductReviewsScreenState();
}

class _ProductReviewsScreenState extends ConsumerState<ProductReviewsScreen> {
  final _commentController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    final comment = _commentController.text.trim();
    if (comment.isEmpty) return;

    await ref
        .read(reviewSubmitProvider.notifier)
        .submit(productId: widget.productId, rating: _rating, comment: comment);

    final state = ref.read(reviewSubmitProvider);
    if (state.isSuccess && mounted) {
      _commentController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review submitted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productProvider(widget.productId));
    final reviewsAsync = ref.watch(productReviewsProvider(widget.productId));
    final submitState = ref.watch(reviewSubmitProvider);
    final currentUser = ref.watch(currentUserProvider);
    final canReview = currentUser != null && currentUser.role == 'customer';
    final showCustomerNavBar = currentUser?.role == 'customer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reviews', style: AppTextStyles.heading2),
        backgroundColor: AppColors.background,
      ),
      body: productAsync.when(
        loading: () =>
            const Center(child: LoadingShimmer(height: 80, width: 120)),
        error: (e, _) => ErrorBanner(message: e.toString()),
        data: (product) {
          return Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: AppTextStyles.heading3),
                          const SizedBox(height: 4),
                          Text(
                            '${product.avgRating.toStringAsFixed(1)} (${product.reviewCount} reviews)',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: AppColors.starColor),
                  ],
                ),
              ),
              Expanded(
                child: reviewsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingShimmer(height: 120),
                  ),
                  error: (e, _) => ErrorBanner(message: e.toString()),
                  data: (reviews) {
                    if (reviews.isEmpty) {
                      return const Center(
                        child: Text(
                          'No reviews yet',
                          style: AppTextStyles.body,
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: reviews.length,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final review = reviews[index];
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      review.customerName,
                                      style: AppTextStyles.label,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (i) => Icon(
                                        i < review.rating
                                            ? Icons.star_rounded
                                            : Icons.star_border_rounded,
                                        size: 16,
                                        color: AppColors.starColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(review.comment, style: AppTextStyles.body),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (canReview)
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Your rating', style: AppTextStyles.label),
                          const SizedBox(width: 10),
                          ...List.generate(
                            5,
                            (i) => IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => setState(() => _rating = i + 1),
                              icon: Icon(
                                i < _rating
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                color: AppColors.starColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Write your review',
                        ),
                      ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Submit Review',
                        isLoading: submitState.isSubmitting,
                        onPressed: _submitReview,
                      ),
                      if (submitState.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            submitState.errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: showCustomerNavBar
          ? const CustomerBottomNavBar(currentIndex: 0)
          : null,
    );
  }
}
