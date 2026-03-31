import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';
import '../services/firestore_service.dart';
import '../services/image_search_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Service provider
// ═══════════════════════════════════════════════════════════════════════════

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService.instance;
});

// ═══════════════════════════════════════════════════════════════════════════
// M2 — Home Feed
// ═══════════════════════════════════════════════════════════════════════════

/// Real-time stream of active products for the home feed (ordered by viewCount).
final homeProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.read(firestoreServiceProvider).watchHomeProducts();
});

/// Real-time stream of trending products (top viewCount).
final trendingProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.read(firestoreServiceProvider).watchTrendingProducts();
});

/// All active shops — for building shop rows on the home screen.
final activeShopsProvider = FutureProvider<List<ShopModel>>((ref) {
  return ref.read(firestoreServiceProvider).getActiveShops();
});

/// Products for a specific shop row — keyed by shopId.
final shopProductsProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, shopId) {
  return ref.read(firestoreServiceProvider).getProductsByShop(shopId);
});

// ═══════════════════════════════════════════════════════════════════════════
// M2 — Product Detail
// ═══════════════════════════════════════════════════════════════════════════

/// Single product fetch — keyed by productId.
final productProvider =
    FutureProvider.family<ProductModel, String>((ref, productId) {
  return ref.read(firestoreServiceProvider).getProduct(productId);
});

/// Single shop fetch — keyed by shopId. Used in product detail screen header.
final shopProvider =
    FutureProvider.family<ShopModel, String>((ref, shopId) {
  return ref.read(firestoreServiceProvider).getShop(shopId);
});

// ═══════════════════════════════════════════════════════════════════════════
// M2 — Category Browse
// ═══════════════════════════════════════════════════════════════════════════

/// Real-time product stream for a selected category.
final categoryProductsProvider =
    StreamProvider.family<List<ProductModel>, String>((ref, category) {
  return ref
      .read(firestoreServiceProvider)
      .watchProductsByCategory(category);
});

// ═══════════════════════════════════════════════════════════════════════════
// M2 — Search State
// ═══════════════════════════════════════════════════════════════════════════

/// The live search query string — drives the search results provider.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Active category filter — empty string means "all categories".
final searchCategoryFilterProvider = StateProvider<String>((ref) => '');

/// Price range filter — null means no bound.
final searchMinPriceProvider = StateProvider<double?>((ref) => null);
final searchMaxPriceProvider = StateProvider<double?>((ref) => null);

/// Encapsulates all search filter state for convenient passing.
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

  bool get hasActiveFilters =>
      category.isNotEmpty || minPrice != null || maxPrice != null;
}

/// Derived provider — builds SearchFilters from individual state providers.
final activeSearchFiltersProvider = Provider<SearchFilters>((ref) {
  return SearchFilters(
    query: ref.watch(searchQueryProvider),
    category: ref.watch(searchCategoryFilterProvider),
    minPrice: ref.watch(searchMinPriceProvider),
    maxPrice: ref.watch(searchMaxPriceProvider),
  );
});

/// Runs the Firestore search query whenever any filter changes.
/// Uses autoDispose so the query is cancelled when the search screen is left.
final searchResultsProvider =
    FutureProvider.autoDispose<List<ProductModel>>((ref) async {
  final filters = ref.watch(activeSearchFiltersProvider);

  // Don't fire a query if there's nothing to search.
  if (filters.query.isEmpty && !filters.hasActiveFilters) {
    return [];
  }

  return ref.read(firestoreServiceProvider).searchProducts(
        query: filters.query,
        category: filters.category.isEmpty ? null : filters.category,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
      );
});

// ═══════════════════════════════════════════════════════════════════════════
// M2 — Image-Based Search
// ═══════════════════════════════════════════════════════════════════════════

/// State for the image search flow.
class ImageSearchState {
  final File? selectedImage;
  final List<String> suggestedTags;
  final List<ProductModel> results;
  final bool isLoading;
  final String? error;

  const ImageSearchState({
    this.selectedImage,
    this.suggestedTags = const [],
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  ImageSearchState copyWith({
    File? selectedImage,
    List<String>? suggestedTags,
    List<ProductModel>? results,
    bool? isLoading,
    String? error,
  }) {
    return ImageSearchState(
      selectedImage: selectedImage ?? this.selectedImage,
      suggestedTags: suggestedTags ?? this.suggestedTags,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// AsyncNotifier managing the full image search flow:
/// 1. User picks an image
/// 2. We send it to Google Vision API → get labels/tags
/// 3. We search Firestore products by those tags
/// 4. We return matching products
class ImageSearchNotifier extends AsyncNotifier<ImageSearchState> {
  @override
  Future<ImageSearchState> build() async {
    return const ImageSearchState();
  }

  Future<void> searchWithImage(File imageFile) async {
    state = const AsyncValue.loading();
    try {
      // Step 1 — get tags from the image via Vision API
      final imageSearchService = ref.read(imageSearchServiceProvider);
      final tags = await imageSearchService.getLabelsFromImage(imageFile);

      if (tags.isEmpty) {
        state = AsyncValue.data(ImageSearchState(
          selectedImage: imageFile,
          suggestedTags: [],
          results: [],
          error: 'No recognisable features found in image. Try another photo.',
        ));
        return;
      }

      // Step 2 — search Firestore by those tags
      final results = await ref
          .read(firestoreServiceProvider)
          .searchByTags(tags: tags);

      state = AsyncValue.data(ImageSearchState(
        selectedImage: imageFile,
        suggestedTags: tags,
        results: results,
      ));
    } catch (e, st) {
      debugPrint('[ImageSearchNotifier] error: $e');
      state = AsyncValue.error(e, st);
    }
  }

  void clearSearch() {
    state = const AsyncValue.data(ImageSearchState());
  }
}

final imageSearchProvider =
    AsyncNotifierProvider<ImageSearchNotifier, ImageSearchState>(
  ImageSearchNotifier.new,
);