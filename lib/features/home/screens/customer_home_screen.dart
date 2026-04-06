import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../models/shop_model.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/current_user_profile_button.dart';
import '../widgets/customer_bottom_nav_bar.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: ListView(
          children: [
            const _HomeAppBar(),
            const _SearchBar(),
            const _CategoryChips(),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Custom design service', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          Text('Request bespoke orders or submit an inquiry'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => context.goNamed('custom-inquiry'),
                      child: const Text('Start'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () => context.goNamed('my-requests'),
                child: const Text('View My Requests'),
              ),
            ),
            const _SectionHeader(
              title: 'Trending',
              // TODO: Implement search with filtering if needed, for now just navigates
              // onSeeAll: () => context.goNamed('search'),
            ),
            _TrendingRow(),
            const SizedBox(height: 12),
            _ShopRows(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── App Bar ─────────────────────────────────────────────────────────────────

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo / wordmark
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ceylon Market',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontFamily: 'Sora',
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.image_search_rounded, color: AppColors.primary),
            tooltip: 'Search by image',
            onPressed: () => context.goNamed('image-search'),
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.textPrimary),
            tooltip: 'Cart',
            onPressed: () => context.goNamed('cart'),
          ),
          const SizedBox(width: 8),
          const CurrentUserProfileButton(radius: 16),
        ],
      ),
    );
  }
}

// ── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => context.goNamed('search'),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider, width: 1),
          ),
          child: const Row(
            children: [
              SizedBox(width: 14),
              Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
              SizedBox(width: 10),
              Text(
                'Search crafts, clothing, furniture...',
                style: TextStyle(color: AppColors.textHint, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Chips ───────────────────────────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: ProductCategory.all.length + 1, // +1 for "All"
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? '' : ProductCategory.all[index - 1];
          final label = isAll ? 'All' : ProductCategory.label(category);

          return GestureDetector(
            onTap: () {
              if (category.isNotEmpty) {
                context.goNamed(
                  'category-browse',
                  pathParameters: {'name': category},
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isAll ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAll ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isAll ? AppColors.textOnPrimary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, /* this.onSeeAll */});

  final String title;
  // final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          /*
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          */
        ],
      ),
    );
  }
}

// ── Trending Row ─────────────────────────────────────────────────────────────

class _TrendingRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingProductsProvider);

    return trending.when(
      loading: () => const ShimmerProductRow(),
      error: (e, _) => ErrorBanner(
        message: 'Could not load trending products.',
        onRetry: () => ref.invalidate(trendingProductsProvider),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const _EmptyRow(message: 'No trending products yet.');
        }
        return SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => ProductCard(product: products[i]),
          ),
        );
      },
    );
  }
}

// ── Shop Rows ─────────────────────────────────────────────────────────────────

class _ShopRows extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(activeShopsProvider);

    return shopsAsync.when(
      loading: () => Column(
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: ShimmerProductRow(),
          ),
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: ShimmerProductRow(),
          ),
        ],
      ),
      error: (e, _) => ErrorBanner(
        message: 'Could not load shops.',
        onRetry: () => ref.invalidate(activeShopsProvider),
      ),
      data: (shops) {
        if (shops.isEmpty) {
          return const _EmptyRow(message: 'No shops available yet.');
        }
        return Column(
          children: [
            for (final shop in shops) _ShopProductRow(shop: shop),
          ],
        );
      },
    );
  }
}

class _ShopProductRow extends ConsumerWidget {
  final ShopModel shop;

  const _ShopProductRow({required this.shop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(shopProductsProvider(shop.shopId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shop.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.goNamed(
                  'shop',
                  pathParameters: {'id': shop.shopId},
                ),
                child: const Text(
                  'View shop',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Products horizontal scroll
        SizedBox(
          height: 230,
          child: productsAsync.when(
            loading: () => const ShimmerProductRow(),
            error: (e, _) =>
                ErrorBanner(message: 'Could not load ${shop.name} products.'),
            data: (products) {
              if (products.isEmpty) {
                return const _EmptyRow(
                  message: 'No products in this shop yet.',
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ProductCard(product: products[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyRow extends StatelessWidget {
  final String message;

  const _EmptyRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppColors.textHint, fontSize: 13),
        ),
      ),
    );
  }
}
