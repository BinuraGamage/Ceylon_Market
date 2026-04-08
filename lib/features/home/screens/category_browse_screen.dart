import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/product_card.dart';
import '../widgets/customer_bottom_nav_bar.dart';

class CategoryBrowseScreen extends ConsumerStatefulWidget {
  /// The category string — must match a value from [ProductCategory.all].
  final String category;

  const CategoryBrowseScreen({super.key, required this.category});

  @override
  ConsumerState<CategoryBrowseScreen> createState() =>
      _CategoryBrowseScreenState();
}

class _CategoryBrowseScreenState extends ConsumerState<CategoryBrowseScreen> {
  /// Sort options
  static const _sortOptions = [
    _SortOption('Popular', 'popular'),
    _SortOption('Top rated', 'rating'),
    _SortOption('Newest', 'newest'),
    _SortOption('Price: low → high', 'price_asc'),
    _SortOption('Price: high → low', 'price_desc'),
  ];

  String _selectedSort = 'popular';

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(categoryProductsProvider(widget.category));

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
        title: Text(
          ProductCategory.label(widget.category),
          style: AppTextStyles.heading3,
        ),
        actions: [
          // Sort button
          TextButton.icon(
            onPressed: () => _showSortSheet(context),
            icon: const Icon(
              Icons.sort_rounded,
              color: AppColors.primary,
              size: 18,
            ),
            label: Text(
              _sortOptions.firstWhere((s) => s.value == _selectedSort).label,
              style: AppTextStyles.link,
            ),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const _CategoryGridSkeleton(),
        error: (e, _) => ErrorBanner(
          message:
              'Could not load ${ProductCategory.label(widget.category)} products.',
          onRetry: () =>
              ref.invalidate(categoryProductsProvider(widget.category)),
        ),
        data: (products) {
          if (products.isEmpty) {
            return _EmptyCategory(
              category: ProductCategory.label(widget.category),
            );
          }
          final sorted = _applySortOrder(products, _selectedSort);
          return _ProductGrid(products: sorted);
        },
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: -1),
    );
  }

  List<ProductModel> _applySortOrder(List<ProductModel> products, String sort) {
    final list = List<ProductModel>.from(products);
    switch (sort) {
      case 'rating':
        list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
        break;
      case 'newest':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'popular':
      default:
        list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
    }
    return list;
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Sort by', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 12),
            ..._sortOptions.map(
              (option) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.label, style: AppTextStyles.body),
                trailing: _selectedSort == option.value
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primary,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  setState(() => _selectedSort = option.value);
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Grid ──────────────────────────────────────────────────────────────

class _ProductGrid extends StatelessWidget {
  final List<ProductModel> products;

  const _ProductGrid({required this.products});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: products.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (_, i) =>
          ProductCard(product: products[i], width: double.infinity),
    );
  }
}

// ── Skeleton ──────────────────────────────────────────────────────────────────

class _CategoryGridSkeleton extends StatelessWidget {
  const _CategoryGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemBuilder: (_, __) => const LoadingShimmer(borderRadius: 12),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyCategory extends StatelessWidget {
  final String category;

  const _EmptyCategory({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No $category products yet',
              style: AppTextStyles.sectionTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back soon — local sellers are adding new products every day.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.goNamed('customer-home');
                }
              },
              child: const Text(
                '← Back to home',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sort Option helper ────────────────────────────────────────────────────────

class _SortOption {
  final String label;
  final String value;

  const _SortOption(this.label, this.value);
}
