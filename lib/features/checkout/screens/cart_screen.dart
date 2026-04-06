import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/product_model.dart';
import '../../../providers/cart_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../widgets/cart_item_card.dart';
import '../../home/widgets/customer_bottom_nav_bar.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartWithProducts = ref.watch(cartWithProductsProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final itemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cart ($itemCount)'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      body: cartWithProducts.when(
        loading: () => const _CartLoadingView(),
        error: (error, stack) =>
            ErrorBanner(message: 'Failed to load cart: ${error.toString()}'),
        data: (items) => items.isEmpty
            ? const _EmptyCartView()
            : _CartContentView(items: items, total: cartTotal),
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 3),
    );
  }
}

class _CartLoadingView extends StatelessWidget {
  const _CartLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16),
        child: LoadingShimmer(height: 120),
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('Your cart is empty', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Add some products to get started',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Continue Shopping',
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/customer');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _CartContentView extends ConsumerWidget {
  const _CartContentView({required this.items, required this.total});

  final List<Map<String, dynamic>> items;
  final double total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartNotifier = ref.watch(cartNotifierProvider.notifier);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final cartItem = item['cartItem'] as CartItemModel;
              final product = item['product'] as ProductModel;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: CartItemCard(
                  cartItem: cartItem,
                  product: product,
                  onQuantityChanged: (quantity) => cartNotifier.updateQuantity(
                    cartItemId: cartItem.cartItemId,
                    quantity: quantity,
                  ),
                  onRemove: () => cartNotifier.removeItem(cartItem.cartItemId),
                ),
              );
            },
          ),
        ),
        _CartSummary(itemCount: items.length, total: total),
      ],
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.itemCount, required this.total});

  final int itemCount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ($itemCount items)',
                  style: AppTextStyles.bodyLarge,
                ),
                Text(
                  'LKR ${total.toStringAsFixed(2)}',
                  style: AppTextStyles.price,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Proceed to Checkout',
              onPressed: () => context.push('/checkout'),
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }
}
