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

/// Read-only shop fetch for M2's product detail preview card.
/// Named shopPreviewProvider to avoid collision with M3's shopProvider
/// in providers/shop_provider.dart (which owns full shop state).
/// M2 only needs name, city, logo — not the full seller dashboard state.
final shopPreviewProvider =
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

// Search state (searchQueryProvider, SearchFilters, searchResultsProvider, etc.)
// lives exclusively in providers/search_provider.dart — do not redeclare here.

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