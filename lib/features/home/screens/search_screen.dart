import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../providers/search_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/product_card.dart';
import '../widgets/customer_bottom_nav_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final filters = ref.watch(activeSearchFiltersProvider);

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
        title: _SearchField(controller: _searchController),
        actions: [
          // Filter button — badge when filters are active
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => _showFilterDrawer(context),
              ),
              if (filters.hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          // Image search button
          IconButton(
            icon: const Icon(Icons.image_search_rounded,
                color: AppColors.textPrimary),
            onPressed: () => context.pushNamed('image-search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Active filter chips
          if (filters.hasActiveFilters) _ActiveFiltersRow(filters: filters),
          // Results
          Expanded(
            child: results.when(
              loading: () => const ShimmerListTiles(),
              error: (e, _) => ErrorBanner(
                message: 'Search failed. Please try again.',
                onRetry: () => ref.invalidate(searchResultsProvider),
              ),
              data: (products) {
                if (filters.query.isEmpty && !filters.hasActiveFilters) {
                  return const _SearchPrompt();
                }
                if (products.isEmpty) {
                  return const _EmptyResults();
                }
                return _ResultsList(products: products);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: 1),
    );
  }

  void _showFilterDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FilterSheet(),
    );
  }
}

// ── Search Field ──────────────────────────────────────────────────────────────

class _SearchField extends ConsumerWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: (value) =>
          ref.read(searchQueryProvider.notifier).state = value,
      style: const TextStyle(
          fontSize: 15, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search crafts, clothing, furniture…',
        hintStyle:
            const TextStyle(color: AppColors.textHint, fontSize: 14),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded,
                    color: AppColors.textHint, size: 18),
                onPressed: () {
                  controller.clear();
                  ref.read(searchQueryProvider.notifier).state = '';
                },
              )
            : null,
      ),
    );
  }
}

// ── Active Filters Row ────────────────────────────────────────────────────────

class _ActiveFiltersRow extends ConsumerWidget {
  final SearchFilters filters;

  const _ActiveFiltersRow({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (filters.category.isNotEmpty)
            _FilterChip(
              label: ProductCategory.label(filters.category),
              onRemove: () => ref
                  .read(searchCategoryFilterProvider.notifier)
                  .state = '',
            ),
          if (filters.minPrice != null)
            _FilterChip(
              label: 'Min LKR ${filters.minPrice!.toStringAsFixed(0)}',
              onRemove: () =>
                  ref.read(searchMinPriceProvider.notifier).state = null,
            ),
          if (filters.maxPrice != null)
            _FilterChip(
              label: 'Max LKR ${filters.maxPrice!.toStringAsFixed(0)}',
              onRemove: () =>
                  ref.read(searchMaxPriceProvider.notifier).state = null,
            ),
          TextButton(
            onPressed: () {
              ref.read(searchCategoryFilterProvider.notifier).state = '';
              ref.read(searchMinPriceProvider.notifier).state = null;
              ref.read(searchMaxPriceProvider.notifier).state = null;
            },
            child: const Text(
              'Clear all',
              style:
                  TextStyle(color: AppColors.primary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Results List ──────────────────────────────────────────────────────────────

class _ResultsList extends StatelessWidget {
  final List<ProductModel> products;

  const _ResultsList({required this.products});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemBuilder: (_, i) => ProductListTile(product: products[i]),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet();

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late String _selectedCategory;
  late double? _minPrice;
  late double? _maxPrice;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedCategory = ref.read(searchCategoryFilterProvider);
    _minPrice = ref.read(searchMinPriceProvider);
    _maxPrice = ref.read(searchMaxPriceProvider);
    if (_minPrice != null) {
      _minController.text = _minPrice!.toStringAsFixed(0);
    }
    if (_maxPrice != null) {
      _maxController.text = _maxPrice!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Category
          const Text(
            'Category',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryOption(
                label: 'All',
                isSelected: _selectedCategory.isEmpty,
                onTap: () => setState(() => _selectedCategory = ''),
              ),
              ...ProductCategory.all.map(
                (cat) => _CategoryOption(
                  label: ProductCategory.label(cat),
                  isSelected: _selectedCategory == cat,
                  onTap: () => setState(() => _selectedCategory = cat),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Price range
          const Text(
            'Price range (LKR)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Min',
                    prefixText: 'LKR ',
                  ),
                  onChanged: (v) =>
                      _minPrice = double.tryParse(v),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('—',
                    style: TextStyle(color: AppColors.textHint)),
              ),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Max',
                    prefixText: 'LKR ',
                  ),
                  onChanged: (v) =>
                      _maxPrice = double.tryParse(v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Apply button
          ElevatedButton(
            onPressed: () {
              ref.read(searchCategoryFilterProvider.notifier).state =
                  _selectedCategory;
              ref.read(searchMinPriceProvider.notifier).state = _minPrice;
              ref.read(searchMaxPriceProvider.notifier).state = _maxPrice;
              Navigator.of(context).pop();
            },
            child: const Text('Apply filters'),
          ),
        ],
      ),
    );
  }
}

class _CategoryOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Empty / Prompt States ─────────────────────────────────────────────────────

class _SearchPrompt extends StatelessWidget {
  const _SearchPrompt();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'Search for local products',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try "batik", "wooden mask", "honey"…',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: AppColors.textHint),
          SizedBox(height: 12),
          Text(
            'No products found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try different keywords or remove filters',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ],
      ),
    );
  }
}