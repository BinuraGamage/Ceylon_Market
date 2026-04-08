import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../features/customization/widgets/product_customization_widget.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/product_card.dart';
import '../widgets/customer_bottom_nav_bar.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('My Wishlist', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Please log in first.'))
          : user.wishlist.isEmpty
          ? _buildEmptyState(context)
          : _buildWishlistGrid(user.wishlist),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Your wishlist is empty', style: AppTextStyles.heading3),
            const SizedBox(height: 8),
            Text(
              'Find items you love and save them here.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Explore Products',
              onPressed: () => context.goNamed('customer-home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWishlistGrid(List<String> wishlist) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: wishlist.length,
      itemBuilder: (context, index) {
        final productId = wishlist[index];
        return _WishlistGridItem(productId: productId);
      },
    );
  }
}

class _WishlistGridItem extends ConsumerWidget {
  final String productId;

  const _WishlistGridItem({required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));

    return productAsync.when(
      loading: () => const LoadingShimmer(height: 200, width: double.infinity),
      error: (e, _) => const Center(child: Text('Error loading product')),
      data: (product) => GestureDetector(
        onTap: () => context.pushNamed(
          'product-detail',
          pathParameters: {'id': productId},
          extra: product.customizable
              ? ProductCustomizationWidget(product: product)
              : null,
        ),
        child: ProductCard(product: product),
      ),
    );
  }
}
