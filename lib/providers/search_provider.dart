import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import 'product_provider.dart' show firestoreServiceProvider;

// ═══════════════════════════════════════════════════════════════════════════
// Search query & filter state
// ═══════════════════════════════════════════════════════════════════════════

/// The live keyword search string typed by the user.
/// StateProvider so it updates on every keystroke.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Active category filter. Empty string = "all categories".
final searchCategoryFilterProvider = StateProvider<String>((ref) => '');

/// Minimum price bound. Null = no lower limit.
final searchMinPriceProvider = StateProvider<double?>((ref) => null);

/// Maximum price bound. Null = no upper limit.
final searchMaxPriceProvider = StateProvider<double?>((ref) => null);

// ═══════════════════════════════════════════════════════════════════════════
// SearchFilters value object
// ═══════════════════════════════════════════════════════════════════════════

/// Immutable snapshot of all active search constraints.
/// Passed to [searchResultsProvider] and exposed to UI filter chips.
class SearchFilters {
  final String query;
  final String category;
  final double? minPrice;
  final double? maxPrice;

  const SearchFilters({
    required this.query,
    required this.category,
    this.minPrice,
    this.maxPrice,
  });

  /// True when at least one non-query filter is active.
  bool get hasActiveFilters =>
      category.isNotEmpty || minPrice != null || maxPrice != null;

  /// True when neither query nor filters are set — show empty prompt state.
  bool get isEmpty => query.isEmpty && !hasActiveFilters;
}

/// Derives a single [SearchFilters] from the four individual state providers.
/// Widgets watch this instead of watching all four separately.
final activeSearchFiltersProvider = Provider<SearchFilters>((ref) {
  return SearchFilters(
    query: ref.watch(searchQueryProvider),
    category: ref.watch(searchCategoryFilterProvider),
    minPrice: ref.watch(searchMinPriceProvider),
    maxPrice: ref.watch(searchMaxPriceProvider),
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// Search results
// ═══════════════════════════════════════════════════════════════════════════

/// Fires a Firestore query whenever any filter changes.
/// autoDispose cancels the query when SearchScreen is popped.
final searchResultsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final filters = ref.watch(activeSearchFiltersProvider);

  // Guard: nothing to search yet — return empty list immediately.
  if (filters.isEmpty) return [];

  final service = ref.read(firestoreServiceProvider);
  return service.searchProducts(
    query: filters.query,
    category: filters.category.isEmpty ? null : filters.category,
    minPrice: filters.minPrice,
    maxPrice: filters.maxPrice,
  );
});

// ═══════════════════════════════════════════════════════════════════════════
// Filter reset helper — call when the user taps "Clear all"
// ═══════════════════════════════════════════════════════════════════════════

/// Convenience function — resets all four filter providers to their defaults.
/// Call via: ref.read(resetSearchFilters)(ref)
///   or just inline the four writes in the widget.
void resetAllSearchFilters(WidgetRef ref) {
  ref.read(searchQueryProvider.notifier).state = '';
  ref.read(searchCategoryFilterProvider.notifier).state = '';
  ref.read(searchMinPriceProvider.notifier).state = null;
  ref.read(searchMaxPriceProvider.notifier).state = null;
}