import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../features/customization/widgets/product_customization_widget.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/app_logo.dart';

class SellerProductsScreen extends ConsumerWidget {
  const SellerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(sellerProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppLogoTitle(
          title: 'My Products',
          textStyle: AppTextStyles.heading2,
        ),
        backgroundColor: AppColors.background,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => context.pushNamed('seller-product-create'),
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppColors.primary,
            tooltip: 'Add product',
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingShimmer(height: 120),
        ),
        error: (e, _) => ErrorBanner(
          message: e.toString(),
          onRetry: () => ref.invalidate(sellerProductsProvider),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 46,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No products yet',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Start by creating your first listing with images, materials, sizes, and category.',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.pushNamed('seller-product-create'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Product'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return InkWell(
                onTap: () => context.pushNamed(
                  'product-detail',
                  pathParameters: {'id': product.productId},
                  extra: product.customizable
                      ? ProductCustomizationWidget(product: product)
                      : null,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: product.images.isNotEmpty
                            ? Image.network(
                                product.images.first,
                                width: 78,
                                height: 78,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 78,
                                height: 78,
                                color: AppColors.background,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.textHint,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.formattedPrice,
                              style: AppTextStyles.price,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.category,
                                    style: AppTextStyles.caption,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  product.isActive ? 'Active' : 'Inactive',
                                  style: AppTextStyles.caption.copyWith(
                                    color: product.isActive
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            context.pushNamed(
                              'seller-product-edit',
                              pathParameters: {'id': product.productId},
                            );
                            return;
                          }
                          if (value == 'reviews') {
                            context.pushNamed(
                              'product-reviews',
                              pathParameters: {'id': product.productId},
                            );
                            return;
                          }
                          if (value == 'delete') {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Product'),
                                content: const Text(
                                  'Are you sure you want to delete this product?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref
                                  .read(sellerProductFormProvider.notifier)
                                  .softDeleteProduct(product.productId);
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                            value: 'reviews',
                            child: Text('Reviews'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
