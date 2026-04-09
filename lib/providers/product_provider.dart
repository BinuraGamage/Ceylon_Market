import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/shop_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/image_search_service.dart';
import '../services/storage_service.dart';
import '../providers/shop_provider.dart';

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
final activeShopsProvider = FutureProvider<List<ShopModel>>((ref) async {
  final service = ref.read(firestoreServiceProvider);
  final shops = await service.getActiveShops();

  // Show newest shops first on the customer home page.
  shops.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final filtered = await Future.wait(
    shops.map((shop) async {
      final products = await service.getProductsByShop(shop.shopId, limit: 1);
      return products.isNotEmpty ? shop : null;
    }),
  );

  return filtered.whereType<ShopModel>().toList();
});

/// Shops used by the customer map view.
final shopMapShopsProvider = FutureProvider<List<ShopModel>>((ref) {
  return ref.read(firestoreServiceProvider).getActiveShops(limit: 200);
});

/// Products for a specific shop row — keyed by shopId.
final shopProductsProvider = FutureProvider.family<List<ProductModel>, String>((
  ref,
  shopId,
) {
  return ref.read(firestoreServiceProvider).getProductsByShop(shopId);
});

/// Seller-side catalog stream for a specific shop (includes all products).
/// Used where management screens must see the full inventory (e.g. offer form).
final sellerProductsByShopProvider = StreamProvider.autoDispose
    .family<List<ProductModel>, String>((ref, shopId) {
      return ref.read(firestoreServiceProvider).watchSellerProducts(shopId);
    });

// ═══════════════════════════════════════════════════════════════════════════
// M2 — Product Detail
// ═══════════════════════════════════════════════════════════════════════════

/// Single product fetch — keyed by productId.
final productProvider = FutureProvider.family<ProductModel, String>((
  ref,
  productId,
) {
  return ref.read(firestoreServiceProvider).getProduct(productId);
});

/// Single shop fetch — keyed by shopId. Used in product detail screen header.
final shopProvider = FutureProvider.family<ShopModel, String>((ref, shopId) {
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
final searchResultsProvider = FutureProvider.autoDispose<List<ProductModel>>((
  ref,
) async {
  final filters = ref.watch(activeSearchFiltersProvider);

  // Don't fire a query if there's nothing to search.
  if (filters.query.isEmpty && !filters.hasActiveFilters) {
    return [];
  }

  return ref
      .read(firestoreServiceProvider)
      .searchProducts(
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
/// 2. We send it to Gemini multimodal API → get labels/tags
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
      // Step 1 — get tags from the image via Gemini multimodal API
      final imageSearchService = ref.read(imageSearchServiceProvider);
      final tags = await imageSearchService.getLabelsFromImage(imageFile);

      if (tags.isEmpty) {
        final fallbackResults = await ref
            .read(firestoreServiceProvider)
            .searchProducts(query: '', limit: 20);

        state = AsyncValue.data(
          ImageSearchState(
            selectedImage: imageFile,
            suggestedTags: [],
            results: fallbackResults,
            error:
                'Image analysis unavailable. Showing popular products instead.',
          ),
        );
        return;
      }

      // Step 2 — search Firestore by those tags
      final results = await ref
          .read(firestoreServiceProvider)
          .searchByTags(tags: tags);

      state = AsyncValue.data(
        ImageSearchState(
          selectedImage: imageFile,
          suggestedTags: tags,
          results: results,
        ),
      );
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

// ═══════════════════════════════════════════════════════════════════════════
// M4 — Inventory & Content Management
// ═══════════════════════════════════════════════════════════════════════════

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService.instance;
});

/// Canonical product categories for dropdowns/chips.
final productCategoriesProvider = Provider<List<String>>((ref) {
  return ProductCategory.all;
});

/// Seller inventory stream (includes inactive products for management).
final sellerProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref
      .watch(myShopProvider)
      .when(
        data: (shop) {
          if (shop == null) return Stream.value(<ProductModel>[]);
          return ref
              .read(firestoreServiceProvider)
              .watchSellerProducts(shop.shopId);
        },
        loading: () => Stream.value(<ProductModel>[]),
        error: (error, stackTrace) => Stream.value(<ProductModel>[]),
      );
});

class SellerProductFormState {
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const SellerProductFormState({
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SellerProductFormState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SellerProductFormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SellerProductFormNotifier extends Notifier<SellerProductFormState> {
  @override
  SellerProductFormState build() => const SellerProductFormState();

  List<String> _normalizeTags(Iterable<String> tags) {
    final normalized = <String>{};
    for (final raw in tags) {
      final value = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      if (value.length < 2) continue;
      normalized.add(value);
    }
    return normalized.toList();
  }

  Future<List<String>> _extractGeminiTagsFromImages(
    List<File> imageFiles,
  ) async {
    if (imageFiles.isEmpty) return const [];

    final imageSearchService = ref.read(imageSearchServiceProvider);
    final extracted = <String>{};

    // Limit analysis count to keep submit latency and API cost predictable.
    for (final file in imageFiles.take(4)) {
      try {
        final labels = await imageSearchService.getGeminiLabelsFromImage(file);
        extracted.addAll(_normalizeTags(labels));
      } catch (e) {
        debugPrint(
          '[SellerProductFormNotifier] Gemini tag extraction error: $e',
        );
      }
    }

    return extracted.toList();
  }

  Future<List<String>> _buildFinalTags({
    required List<String> manualTags,
    required List<File> imageFiles,
    required String category,
  }) async {
    final combined = <String>{..._normalizeTags(manualTags)};
    combined.addAll(await _extractGeminiTagsFromImages(imageFiles));

    final normalizedCategory = ProductCategory.normalizeCategoryKey(category);
    if (normalizedCategory.isNotEmpty) {
      combined.add(normalizedCategory);
    }

    return combined.take(25).toList();
  }

  Future<void> createProduct({
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required List<String> tags,
    required List<String> materials,
    required List<String> sizes,
    required List<String> colors,
    required bool customizable,
    required bool isAREnabled,
    required List<File> imageFiles,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      final shop = await ref.read(myShopProvider.future);
      if (shop == null) {
        throw Exception(
          'Seller shop not found. Please complete shop registration.',
        );
      }

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Login required.');
      }

      final finalTags = await _buildFinalTags(
        manualTags: tags,
        imageFiles: imageFiles,
        category: category,
      );

      final draft = ProductModel(
        productId: '',
        shopId: shop.shopId,
        name: name,
        description: description,
        price: price,
        category: category,
        images: const [],
        tags: finalTags,
        materials: materials.isEmpty ? null : materials,
        sizes: sizes.isEmpty ? null : sizes,
        colors: colors.isEmpty ? null : colors,
        stock: stock,
        isActive: true,
        customizable: customizable,
        isAREnabled: isAREnabled,
        arModelUrl: null,
        avgRating: 0,
        reviewCount: 0,
        viewCount: 0,
        createdAt: DateTime.now(),
      );

      final productId = await ref
          .read(firestoreServiceProvider)
          .createProduct(draft);

      if (imageFiles.isNotEmpty) {
        final imageUrls = await ref
            .read(storageServiceProvider)
            .uploadProductImages(
              files: imageFiles,
              shopId: shop.shopId,
              productId: productId,
            );

        await ref
            .read(firestoreServiceProvider)
            .updateProduct(
              productId: productId,
              updates: {'images': imageUrls},
            );
      }

      if (isAREnabled) {
        try {
          await ref
              .read(firestoreServiceProvider)
              .ensureArModelTaskForProduct(
                productId: productId,
                productName: name,
                shopId: shop.shopId,
                sellerId: currentUser.uid,
              );
        } catch (e) {
          // Product creation must not fail if a designer is unavailable.
          debugPrint('[SellerProductFormNotifier] AR task skipped: $e');
        }
      }

      ref.invalidate(sellerProductsProvider);
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> updateProduct({
    required ProductModel existing,
    required String name,
    required String description,
    required double price,
    required String category,
    required int stock,
    required List<String> tags,
    required List<String> materials,
    required List<String> sizes,
    required List<String> colors,
    required bool customizable,
    required bool isAREnabled,
    required List<File> newImageFiles,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Login required.');
      }

      final finalTags = await _buildFinalTags(
        manualTags: tags,
        imageFiles: newImageFiles,
        category: category,
      );

      var finalImages = List<String>.from(existing.images);
      if (newImageFiles.isNotEmpty) {
        final uploaded = await ref
            .read(storageServiceProvider)
            .uploadProductImages(
              files: newImageFiles,
              shopId: existing.shopId,
              productId: existing.productId,
            );
        finalImages = [...finalImages, ...uploaded];
      }

      await ref
          .read(firestoreServiceProvider)
          .updateProduct(
            productId: existing.productId,
            updates: {
              'name': name,
              'description': description,
              'price': price,
              'category': category,
              'stock': stock,
              'tags': finalTags,
              'materials': materials,
              'sizes': sizes,
              'colors': colors,
              'customizable': customizable,
              'isAREnabled': isAREnabled,
              // Seller must not set/override the 3D model URL.
              // Designers upload and attach it later.
              'arModelUrl': existing.arModelUrl,
              'images': finalImages,
            },
          );

      final shouldCreateArTask =
          isAREnabled &&
          (existing.arModelUrl == null || existing.arModelUrl!.isEmpty);
      if (shouldCreateArTask) {
        try {
          await ref
              .read(firestoreServiceProvider)
              .ensureArModelTaskForProduct(
                productId: existing.productId,
                productName: name,
                shopId: existing.shopId,
                sellerId: currentUser.uid,
              );
        } catch (e) {
          debugPrint('[SellerProductFormNotifier] AR task skipped: $e');
        }
      }

      ref.invalidate(sellerProductsProvider);
      ref.invalidate(productProvider(existing.productId));
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }

  Future<void> softDeleteProduct(String productId) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      await ref.read(firestoreServiceProvider).softDeleteProduct(productId);
      ref.invalidate(sellerProductsProvider);
      ref.invalidate(productProvider(productId));
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }
}

final sellerProductFormProvider =
    NotifierProvider<SellerProductFormNotifier, SellerProductFormState>(
      SellerProductFormNotifier.new,
    );

/// Reviews stream for one product.
final productReviewsProvider = StreamProvider.family<List<ReviewModel>, String>(
  (ref, productId) {
    return ref.read(firestoreServiceProvider).watchProductReviews(productId);
  },
);

class ReviewSubmitState {
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  const ReviewSubmitState({
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ReviewSubmitState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ReviewSubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class ReviewSubmitNotifier extends Notifier<ReviewSubmitState> {
  @override
  ReviewSubmitState build() => const ReviewSubmitState();

  Future<void> submit({
    required String productId,
    required int rating,
    required String comment,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      isSuccess: false,
    );
    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('Please log in to submit a review.');
      }

      await ref
          .read(firestoreServiceProvider)
          .submitProductReview(
            productId: productId,
            customerId: user.uid,
            customerName: user.displayName,
            rating: rating,
            comment: comment,
          );

      ref.invalidate(productReviewsProvider(productId));
      ref.invalidate(productProvider(productId));
      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      debugPrint('[ReviewSubmitNotifier] error: $e');
      state = state.copyWith(isSubmitting: false, errorMessage: e.toString());
    }
  }
}

final reviewSubmitProvider =
    NotifierProvider<ReviewSubmitNotifier, ReviewSubmitState>(
      ReviewSubmitNotifier.new,
    );
final homeSelectedCategoryProvider = StateProvider<String>((ref) => '');
