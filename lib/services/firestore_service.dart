import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firestore_paths.dart';
import '../models/product_model.dart';
import '../models/review_model.dart';
import '../models/shop_model.dart';
import '../models/offer_model.dart';

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
      final doc = await _db.doc(FirestorePaths.productDoc(productId)).get();
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
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid Firebase composite index requirements
          list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
          return list.take(limit).toList();
        });
  }

  /// Stream products for a specific category, ordered by avgRating desc.
  Stream<List<ProductModel>> watchProductsByCategory(
    String category, {
    int limit = 20,
  }) {
    return _db
        .collection(FirestorePaths.products)
        // .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid Firebase composite index requirements
          list.sort((a, b) => b.avgRating.compareTo(a.avgRating));
          return list.take(limit).toList();
        });
  }

  /// Stream trending products (highest viewCount in last N docs).
  /// Used for the "Trending" horizontal row on the home screen.
  Stream<List<ProductModel>> watchTrendingProducts({int limit = 10}) {
    return _db
        .collection(FirestorePaths.products)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList();
          // Sort client-side to avoid Firebase composite index requirements
          list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
          return list.take(limit).toList();
        });
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
      Query<Map<String, dynamic>> ref = _db.collection(FirestorePaths.products);
      // .where('isActive', isEqualTo: true);

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
        final end =
            query.substring(0, query.length - 1) +
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
          // .where('isActive', isEqualTo: true)
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
          // Relaxing constraints to ensure products show up even if missing fields
          // .where('isActive', isEqualTo: true)
          // .orderBy('createdAt', descending: true)
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
          // Temporarily removed to ensure newly created shops are visible
          // .where('status', isEqualTo: 'active')
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

  // ═══════════════════════════════════════════════════════════════════════════
  // M4 — Inventory & Content Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Creates a new product document and returns the generated productId.
  Future<String> createProduct(ProductModel product) async {
    try {
      final doc = _db.collection(FirestorePaths.products).doc();
      final payload = product.copyWith(
        productId: doc.id,
        createdAt: DateTime.now(),
      );
      await doc.set(payload.toMap());
      return doc.id;
    } catch (e) {
      debugPrint('[FirestoreService] createProduct error: $e');
      rethrow;
    }
  }

  /// Updates mutable seller fields for a product.
  Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _db.doc(FirestorePaths.productDoc(productId)).update(updates);
    } catch (e) {
      debugPrint('[FirestoreService] updateProduct error: $e');
      rethrow;
    }
  }

  /// Soft delete only - never removes a product document.
  Future<void> softDeleteProduct(String productId) async {
    try {
      await _db.doc(FirestorePaths.productDoc(productId)).update({
        'isActive': false,
      });
    } catch (e) {
      debugPrint('[FirestoreService] softDeleteProduct error: $e');
      rethrow;
    }
  }

  /// Watches seller products by shopId. Includes inactive by default so sellers
  /// can reactivate/edit old listings.
  Stream<List<ProductModel>> watchSellerProducts(
    String shopId, {
    bool includeInactive = true,
  }) {
    Query<Map<String, dynamic>> ref = _db
        .collection(FirestorePaths.products)
        .where('shopId', isEqualTo: shopId);

    if (!includeInactive) {
      ref = ref.where('isActive', isEqualTo: true);
    }

    return ref.snapshots().map((snap) {
      final list = snap.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
      // Sort locally to avoid Firebase composite index requirement for (shopId + createdAt)
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Watches review list for a given product.
  Stream<List<ReviewModel>> watchProductReviews(String productId) {
    return _db
        .collection(FirestorePaths.reviewsCollection(productId))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => ReviewModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Adds one review per customer per product and updates product/shop ratings.
  Future<void> submitProductReview({
    required String productId,
    required String customerId,
    required String customerName,
    required int rating,
    required String comment,
  }) async {
    try {
      final productRef = _db.doc(FirestorePaths.productDoc(productId));
      final reviewRef = _db
          .collection(FirestorePaths.reviewsCollection(productId))
          .doc(customerId);

      await _db.runTransaction((tx) async {
        // --- 1. Perform all reads first ---
        final productSnap = await tx.get(productRef);
        if (!productSnap.exists || productSnap.data() == null) {
          throw Exception('Product not found');
        }

        final reviewSnap = await tx.get(reviewRef);
        if (reviewSnap.exists) {
          throw Exception('You already reviewed this product');
        }

        final productData = productSnap.data()!;
        final shopId = productData['shopId'] as String? ?? '';

        DocumentSnapshot<Map<String, dynamic>>? shopSnap;
        DocumentReference<Map<String, dynamic>>? shopRef;
        if (shopId.isNotEmpty) {
          shopRef = _db.doc(FirestorePaths.shopDoc(shopId));
          shopSnap = await tx.get(shopRef);
        }

        // --- 2. Calculate new values ---
        final currentAvg =
            (productData['avgRating'] as num?)?.toDouble() ?? 0.0;
        final currentCount = (productData['reviewCount'] as num?)?.toInt() ?? 0;
        final nextCount = currentCount + 1;
        final nextAvg = ((currentAvg * currentCount) + rating) / nextCount;

        // --- 3. Perform all writes ---
        tx.set(reviewRef, {
          'reviewId': reviewRef.id,
          'productId': productId,
          'customerId': customerId,
          'customerName': customerName,
          'rating': rating,
          'comment': comment,
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.update(productRef, {'avgRating': nextAvg, 'reviewCount': nextCount});

        if (shopSnap != null &&
            shopSnap.exists &&
            shopSnap.data() != null &&
            shopRef != null) {
          final shopData = shopSnap.data()!;
          final shopAvg = (shopData['avgRating'] as num?)?.toDouble() ?? 0.0;
          final shopCount = (shopData['reviewCount'] as num?)?.toInt() ?? 0;
          final shopNextCount = shopCount + 1;
          final shopNextAvg = ((shopAvg * shopCount) + rating) / shopNextCount;

          tx.update(shopRef, {
            'avgRating': shopNextAvg,
            'reviewCount': shopNextCount,
          });
        }
      });
    } catch (e) {
      debugPrint('[FirestoreService] submitProductReview error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // M4 — Wishlist Logic
  // ═══════════════════════════════════════════════════════════════════════════

  /// Add or remove a product from the user's wishlist
  Future<void> toggleWishlist({
    required String uid,
    required String productId,
    required bool isAdding,
  }) async {
    try {
      final userRef = _db.doc(FirestorePaths.userDoc(uid));

      if (isAdding) {
        await userRef.update({
          'wishlist': FieldValue.arrayUnion([productId]),
        });
      } else {
        await userRef.update({
          'wishlist': FieldValue.arrayRemove([productId]),
        });
      }
    } catch (e) {
      debugPrint('[FirestoreService] toggleWishlist error: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // M3/M4 — Offers Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Fetches all offers for a shop
  Future<List<OfferModel>> getShopOffers(String shopId) async {
    try {
      final snap = await _db
          .collection(FirestorePaths.offers)
          .where('shopId', isEqualTo: shopId)
          .get();
      return snap.docs
          .map((doc) => OfferModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('[FirestoreService] getShopOffers error: $e');
      rethrow;
    }
  }

  /// Watches offers for a shop in real time.
  Stream<List<OfferModel>> watchShopOffers(String shopId) {
    return _db
        .collection(FirestorePaths.offers)
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => OfferModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  /// Creates a new offer and sets `activeOfferId` on its products
  Future<String> createOffer(OfferModel offer) async {
    try {
      final doc = _db.collection(FirestorePaths.offers).doc();
      final payload = OfferModel(
        id: doc.id,
        shopId: offer.shopId,
        title: offer.title,
        productIds: offer.productIds,
        isPercentage: offer.isPercentage,
        discountValue: offer.discountValue,
        startDate: offer.startDate,
        endDate: offer.endDate,
        minQty: offer.minQty,
      );

      final batch = _db.batch();
      batch.set(doc, payload.toMap());

      for (final productId in payload.productIds) {
        final productRef = _db.doc(FirestorePaths.productDoc(productId));
        final productSnap = await productRef.get();

        if (productSnap.exists && productSnap.data() != null) {
          final data = productSnap.data()!;
          final double currentPrice =
              (data['price'] as num?)?.toDouble() ?? 0.0;
          final double originalPrice =
              (data['originalPrice'] as num?)?.toDouble() ?? currentPrice;

          double newPrice = originalPrice;
          if (payload.isPercentage) {
            newPrice =
                originalPrice - (originalPrice * (payload.discountValue / 100));
          } else {
            newPrice = originalPrice - payload.discountValue;
          }
          if (newPrice < 0) newPrice = 0.0;

          final updates = <String, dynamic>{
            'activeOfferId': doc.id,
            'price': newPrice,
          };

          if (data['originalPrice'] == null) {
            updates['originalPrice'] = currentPrice;
          }

          batch.update(productRef, updates);
        }
      }

      await batch.commit();
      return doc.id;
    } catch (e) {
      debugPrint('[FirestoreService] createOffer error: $e');
      rethrow;
    }
  }

  /// Updates an offer and resyncs products
  Future<void> updateOffer(OfferModel offer) async {
    try {
      final oldOfferDoc = await _db
          .doc(FirestorePaths.offerDoc(offer.id))
          .get();
      if (!oldOfferDoc.exists) throw Exception('Offer not found');

      final oldOffer = OfferModel.fromMap(oldOfferDoc.data()!, oldOfferDoc.id);
      final batch = _db.batch();
      batch.update(_db.doc(FirestorePaths.offerDoc(offer.id)), offer.toMap());

      // Detach removed products
      final removedProductIds = oldOffer.productIds.where(
        (id) => !offer.productIds.contains(id),
      );
      for (final productId in removedProductIds) {
        final productRef = _db.doc(FirestorePaths.productDoc(productId));
        final productSnap = await productRef.get();
        if (productSnap.exists && productSnap.data() != null) {
          final data = productSnap.data()!;
          final double originalPrice =
              (data['originalPrice'] as num?)?.toDouble() ??
              (data['price'] as num?)?.toDouble() ??
              0.0;
          batch.update(productRef, {
            'activeOfferId': FieldValue.delete(),
            'price': originalPrice,
            'originalPrice': FieldValue.delete(),
          });
        }
      }

      // Attach new products and update existing products to reflect potentially changed discount
      for (final productId in offer.productIds) {
        final productRef = _db.doc(FirestorePaths.productDoc(productId));
        final productSnap = await productRef.get();
        if (productSnap.exists && productSnap.data() != null) {
          final data = productSnap.data()!;
          final double currentPrice =
              (data['price'] as num?)?.toDouble() ?? 0.0;
          final double originalPrice =
              (data['originalPrice'] as num?)?.toDouble() ?? currentPrice;

          double newPrice = originalPrice;
          if (offer.isPercentage) {
            newPrice =
                originalPrice - (originalPrice * (offer.discountValue / 100));
          } else {
            newPrice = originalPrice - offer.discountValue;
          }
          if (newPrice < 0) newPrice = 0.0;

          final updates = <String, dynamic>{
            'activeOfferId': offer.id,
            'price': newPrice,
          };

          if (data['originalPrice'] == null) {
            updates['originalPrice'] = currentPrice;
          }

          batch.update(productRef, updates);
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[FirestoreService] updateOffer error: $e');
      rethrow;
    }
  }

  /// Deletes an offer and clears `activeOfferId` from its products
  Future<void> deleteOffer(String offerId) async {
    try {
      final offerDoc = await _db.doc(FirestorePaths.offerDoc(offerId)).get();
      if (!offerDoc.exists) return;

      final offer = OfferModel.fromMap(offerDoc.data()!, offerDoc.id);
      final batch = _db.batch();
      batch.delete(offerDoc.reference);

      // Clear the associated activeOfferId in products and revert price
      for (final productId in offer.productIds) {
        final productRef = _db.doc(FirestorePaths.productDoc(productId));
        final productSnap = await productRef.get();
        if (productSnap.exists && productSnap.data() != null) {
          final data = productSnap.data()!;
          final double originalPrice =
              (data['originalPrice'] as num?)?.toDouble() ??
              (data['price'] as num?)?.toDouble() ??
              0.0;
          batch.update(productRef, {
            'activeOfferId': FieldValue.delete(),
            'price': originalPrice,
            'originalPrice': FieldValue.delete(),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('[FirestoreService] deleteOffer error: $e');
      rethrow;
    }
  }

  // TODO: M5 — cart and order methods go here
  // TODO: M6 — custom request methods go here
  // TODO: M7 — notification queue writes go here
}
