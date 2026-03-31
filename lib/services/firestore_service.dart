import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firestore_paths.dart';
import '../models/product_model.dart';
import '../models/shop_model.dart';

/// Firestore service wrapper — no UI imports, no business logic in widgets.
/// M2 owns: getProduct, searchProducts, getFeaturedProducts,
///           watchHomeProducts, getProductsByCategory, incrementViewCount.
///
/// Other members: add your own methods below the relevant section header.
/// Never remove or rename existing methods without coordinating with the team.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════════════════
  // M2 — Product Discovery & Search
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch a single product by ID.
  Future<ProductModel> getProduct(String productId) async {
    try {
      final doc = await _db
          .doc(FirestorePaths.productDoc(productId))
          .get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Product $productId not found');
      }
      return ProductModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreService] getProduct error: $e');
      rethrow;
    }
  }

  /// Stream all active products for the home feed, ordered by viewCount desc.
  /// Used by homeProductsProvider (StreamProvider).
  Stream<List<ProductModel>> watchHomeProducts({int limit = 30}) {
    return _db
        .collection(FirestorePaths.products)
        .where('isActive', isEqualTo: true)
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream products for a specific category, ordered by avgRating desc.
  Stream<List<ProductModel>> watchProductsByCategory(
    String category, {
    int limit = 20,
  }) {
    return _db
        .collection(FirestorePaths.products)
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('avgRating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Stream trending products (highest viewCount in last N docs).
  /// Used for the "Trending" horizontal row on the home screen.
  Stream<List<ProductModel>> watchTrendingProducts({int limit = 10}) {
    return _db
        .collection(FirestorePaths.products)
        .where('isActive', isEqualTo: true)
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Keyword search — Firestore prefix search on the 'name' field.
  /// For production, consider upgrading to Algolia (see pubspec.yaml).
  /// Returns products whose name starts with [query] (case-sensitive).
  Future<List<ProductModel>> searchProducts({
    required String query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit = 20,
  }) async {
    try {
      // Base query — active products only
      Query<Map<String, dynamic>> ref = _db
          .collection(FirestorePaths.products)
          .where('isActive', isEqualTo: true);

      // Category filter
      if (category != null && category.isNotEmpty) {
        ref = ref.where('category', isEqualTo: category);
      }

      // Price range filter
      if (minPrice != null) {
        ref = ref.where('price', isGreaterThanOrEqualTo: minPrice);
      }
      if (maxPrice != null) {
        ref = ref.where('price', isLessThanOrEqualTo: maxPrice);
      }

      // Prefix match on name — Firestore range query trick
      if (query.isNotEmpty) {
        final end = query.substring(0, query.length - 1) +
            String.fromCharCode(query.codeUnitAt(query.length - 1) + 1);
        ref = ref
            .where('name', isGreaterThanOrEqualTo: query)
            .where('name', isLessThan: end);
      }

      ref = ref.limit(limit);

      final snap = await ref.get();
      return snap.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] searchProducts error: $e');
      rethrow;
    }
  }

  /// Tag-based search — finds products containing any of [tags].
  Future<List<ProductModel>> searchByTags({
    required List<String> tags,
    int limit = 20,
  }) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.products)
          .where('isActive', isEqualTo: true)
          .where('tags', arrayContainsAny: tags)
          .limit(limit)
          .get();
      return snap.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] searchByTags error: $e');
      rethrow;
    }
  }

  /// Fetch products from a specific shop — used in shop product rows on home.
  Future<List<ProductModel>> getProductsByShop(
    String shopId, {
    int limit = 10,
  }) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.products)
          .where('shopId', isEqualTo: shopId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] getProductsByShop error: $e');
      rethrow;
    }
  }

  /// Increment viewCount on a product — called from ProductDetailScreen mount.
  /// Uses FieldValue.increment so it's atomic and offline-safe.
  /// M3 reads this field for their Shop Analytics Dashboard.
  Future<void> incrementViewCount(String productId) async {
    try {
      await _db.doc(FirestorePaths.productDoc(productId)).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Non-critical — log but do not rethrow; don't crash the screen.
      debugPrint('[FirestoreService] incrementViewCount error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // M2 — Shop Fetching (read-only; M3 owns shop writes)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetch a single shop by ID for display in product detail / home rows.
  Future<ShopModel> getShop(String shopId) async {
    try {
      final doc = await _db.doc(FirestorePaths.shopDoc(shopId)).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Shop $shopId not found');
      }
      return ShopModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('[FirestoreService] getShop error: $e');
      rethrow;
    }
  }

  /// Fetch all active shops — for building home screen shop rows.
  Future<List<ShopModel>> getActiveShops({int limit = 10}) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.shops)
          .where('status', isEqualTo: 'active')
          .limit(limit)
          .get();
      return snap.docs
          .map((doc) => ShopModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] getActiveShops error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Other members — add your methods below with a section header
  // ═══════════════════════════════════════════════════════════════════════════

  // TODO: M1 — auth-related user doc writes go here
  // TODO: M3 — shop analytics writes go here
  // TODO: M4 — product upload/edit methods go here
  // TODO: M5 — cart and order methods go here
  // TODO: M6 — custom request methods go here
  // TODO: M7 — notification queue writes go here
}