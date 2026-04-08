import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/shop_model.dart';
import '../models/shop_analytics_model.dart';
import '../models/notification_model.dart';
import 'firestore_service.dart';
import 'cloudinary_service.dart';

// NOTE: firebase_storage import removed — images now go through Cloudinary.
// FirebaseStorage is no longer a dependency of this file.

/// M3 owns this service. Others must not modify without coordination.
/// All Firestore operations for shops and shop analytics live here.
/// Image uploads are handled by [CloudinaryService].
class ShopService {
  ShopService._();
  static final ShopService instance = ShopService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ─── Shop CRUD ────────────────────────────────────────────────────────────

  /// Creates a new shop doc with status 'pending'.
  /// Called from seller registration. Returns the new shopId.
  Future<String> createShop(ShopModel shop) async {
    try {
      final shopId = _uuid.v4();
      await _db.collection(FirestorePaths.shops).doc(shopId).set(shop.toMap());

      await _notifyAdminsForNewShop(shopId: shopId, shopName: shop.name);
      return shopId;
    } on FirebaseException catch (e) {
      debugPrint('[ShopService.createShop] FirebaseException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[ShopService.createShop] Unexpected error: $e');
      rethrow;
    }
  }

  Future<void> _notifyAdminsForNewShop({
    required String shopId,
    required String shopName,
  }) async {
    try {
      final adminSnap = await _db
          .collection(FirestorePaths.users)
          .where('role', isEqualTo: 'admin')
          .get();

      for (final doc in adminSnap.docs) {
        await FirestoreService.instance.createNotification(
          NotificationModel(
            notificationId: '',
            recipientId: doc.id,
            title: 'New shop pending approval',
            body: '$shopName submitted by a seller.',
            type: 'shop_created',
            data: {'shopId': shopId},
            isRead: false,
            createdAt: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ShopService] notifyAdminsForNewShop error: $e');
      rethrow;
    }
  }

  /// Fetches a single shop by ID. Returns null if not found.
  Future<ShopModel?> getShop(String shopId) async {
    try {
      final doc = await _db.collection(FirestorePaths.shops).doc(shopId).get();
      if (!doc.exists || doc.data() == null) return null;
      return ShopModel.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      debugPrint('[ShopService.getShop] FirebaseException: ${e.message}');
      rethrow;
    }
  }

  /// Real-time stream of a shop document.
  Stream<ShopModel?> watchShop(String shopId) {
    return _db.collection(FirestorePaths.shops).doc(shopId).snapshots().map((
      doc,
    ) {
      if (!doc.exists || doc.data() == null) return null;
      return ShopModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Fetches the shop owned by a specific user. Returns null if not a seller.
  Future<ShopModel?> getShopByOwner(String ownerId) async {
    try {
      final query = await _db
          .collection(FirestorePaths.shops)
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      final doc = query.docs.first;
      return ShopModel.fromMap(doc.data(), doc.id);
    } on FirebaseException catch (e) {
      debugPrint(
        '[ShopService.getShopByOwner] FirebaseException: ${e.message}',
      );
      rethrow;
    }
  }

  /// Real-time stream of a shop by ownerId.
  Stream<ShopModel?> watchShopByOwner(String ownerId) {
    return _db
        .collection(FirestorePaths.shops)
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .snapshots()
        .map((query) {
          if (query.docs.isEmpty) return null;
          final doc = query.docs.first;
          return ShopModel.fromMap(doc.data(), doc.id);
        });
  }

  /// Updates specific fields on a shop doc. Seller-owned fields only.
  Future<void> updateShop(String shopId, Map<String, dynamic> fields) async {
    try {
      await _db.collection(FirestorePaths.shops).doc(shopId).update(fields);
    } on FirebaseException catch (e) {
      debugPrint('[ShopService.updateShop] FirebaseException: ${e.message}');
      rethrow;
    }
  }

  /// Soft-delete: sets status to 'suspended'. Never calls .delete().
  Future<void> suspendShop(String shopId) async {
    try {
      await _db.collection(FirestorePaths.shops).doc(shopId).update({
        'status': 'suspended',
      });
    } on FirebaseException catch (e) {
      debugPrint('[ShopService.suspendShop] FirebaseException: ${e.message}');
      rethrow;
    }
  }

  // ─── Image Uploads (Cloudinary) ───────────────────────────────────────────

  /// Uploads a shop logo via Cloudinary and returns the secure HTTPS URL.
  /// The URL is then saved to the shop document's [logoUrl] field in Firestore.
  Future<String> uploadLogo(String shopId, File file) async {
    try {
      return await CloudinaryService.instance.uploadLogo(shopId, file);
    } on CloudinaryException catch (e) {
      debugPrint('[ShopService.uploadLogo] CloudinaryException: $e');
      rethrow;
    } catch (e) {
      debugPrint('[ShopService.uploadLogo] Unexpected error: $e');
      rethrow;
    }
  }

  /// Uploads a shop banner via Cloudinary and returns the secure HTTPS URL.
  Future<String> uploadBanner(String shopId, File file) async {
    try {
      return await CloudinaryService.instance.uploadBanner(shopId, file);
    } on CloudinaryException catch (e) {
      debugPrint('[ShopService.uploadBanner] CloudinaryException: $e');
      rethrow;
    } catch (e) {
      debugPrint('[ShopService.uploadBanner] Unexpected error: $e');
      rethrow;
    }
  }

  /// Uploads a shop video via Cloudinary and adds its URL to the shop document.
  Future<void> uploadShopVideo(String shopId, File file) async {
    try {
      final secureUrl = await CloudinaryService.instance.uploadVideo(
        shopId,
        file,
      );
      await _db.collection(FirestorePaths.shops).doc(shopId).update({
        'videoUrls': FieldValue.arrayUnion([secureUrl]),
      });
    } on FirebaseException catch (e) {
      debugPrint(
        '[ShopService.uploadShopVideo] FirebaseException: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[ShopService.uploadShopVideo] Unexpected error: $e');
      rethrow;
    }
  }

  /// Removes a shop video from the shop document.
  Future<void> deleteShopVideo(String shopId, String videoUrl) async {
    try {
      await _db.collection(FirestorePaths.shops).doc(shopId).update({
        'videoUrls': FieldValue.arrayRemove([videoUrl]),
      });
    } on FirebaseException catch (e) {
      debugPrint(
        '[ShopService.deleteShopVideo] FirebaseException: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[ShopService.deleteShopVideo] Unexpected error: $e');
      rethrow;
    }
  }

  // ─── Analytics ────────────────────────────────────────────────────────────

  /// Records a product view for analytics.
  /// Called by M2 via shopAnalyticsServiceProvider (see AGENTS.md §9 M2→M3).
  /// // TODO: Coordinate with M2 — they call this on ProductDetailScreen mount.
  Future<void> recordProductView({
    required String productId,
    required String shopId,
  }) async {
    try {
      await _db.collection(FirestorePaths.products).doc(productId).update({
        'viewCount': FieldValue.increment(1),
      });
    } on FirebaseException catch (e) {
      debugPrint(
        '[ShopService.recordProductView] FirebaseException: ${e.message}',
      );
      rethrow;
    }
  }

  /// Fetches aggregated analytics for the Selling Insights screen.
  /// Computes stats from orders and products collections for this shop.
  Future<ShopAnalyticsModel> getShopAnalytics(String shopId) async {
    try {
      // Fetch shop's products
      final productsQuery = await _db
          .collection(FirestorePaths.products)
          .where('shopId', isEqualTo: shopId)
          .where('isActive', isEqualTo: true)
          .get();

      // Fetch shop's orders
      final ordersQuery = await _db
          .collection(FirestorePaths.orders)
          .where('shopId', isEqualTo: shopId)
          .get();

      int totalViews = 0;
      final List<TopProduct> allProducts = [];

      for (final doc in productsQuery.docs) {
        final data = doc.data();
        final views = (data['viewCount'] as int? ?? 0);
        totalViews += views;

        // Count sales from orders for this product
        int sales = 0;
        double revenue = 0;
        for (final order in ordersQuery.docs) {
          final items = List<Map<String, dynamic>>.from(
            order.data()['items'] as List? ?? [],
          );
          for (final item in items) {
            if (item['productId'] == doc.id) {
              sales += (item['quantity'] as int? ?? 1);
              revenue +=
                  ((item['price'] as num?)?.toDouble() ?? 0) *
                  (item['quantity'] as int? ?? 1);
            }
          }
        }

        allProducts.add(
          TopProduct(
            productId: doc.id,
            name: data['name'] as String? ?? '',
            thumbnailUrl: (data['images'] as List?)?.isNotEmpty == true
                ? (data['images'] as List).first as String
                : null,
            revenueLKR: revenue,
            sales: sales,
            views: views,
            hasWarning: views > 50 && sales < 3,
          ),
        );
      }

      // Sort for top/low
      final sorted = List<TopProduct>.from(allProducts)
        ..sort((a, b) => b.revenueLKR.compareTo(a.revenueLKR));
      final topProducts = sorted.take(3).toList();
      final lowProducts = allProducts
          .where((p) => p.hasWarning)
          .take(3)
          .toList();

      // Revenue over last 7 days
      final now = DateTime.now();
      final salesMap = <DateTime, double>{};
      for (var i = 6; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day - i);
        salesMap[day] = 0;
      }
      double totalRevenue = 0;
      for (final order in ordersQuery.docs) {
        final data = order.data();
        final ts = data['createdAt'] as Timestamp?;
        if (ts == null) continue;
        final date = ts.toDate();
        final day = DateTime(date.year, date.month, date.day);
        final amount = (data['totalLKR'] as num?)?.toDouble() ?? 0;
        totalRevenue += amount;
        if (salesMap.containsKey(day)) {
          salesMap[day] = salesMap[day]! + amount;
        }
      }

      final salesOverTime = salesMap.entries
          .map((e) => DailySales(date: e.key, revenueLKR: e.value))
          .toList();

      // Fetch shop avg rating
      final shopDoc = await _db
          .collection(FirestorePaths.shops)
          .doc(shopId)
          .get();
      final avgRating = shopDoc.exists
          ? (shopDoc.data()!['avgRating'] as num?)?.toDouble() ?? 0.0
          : 0.0;

      // Customer behavior: active hours
      final activeByHour = <String, int>{};
      final Set<String> uniqueCustomers = {};
      final customerOrderCount = <String, int>{};
      for (final order in ordersQuery.docs) {
        final data = order.data();
        final ts = data['createdAt'] as Timestamp?;
        final customerId = data['customerId'] as String? ?? '';
        if (ts != null) {
          final hour = ts.toDate().hour.toString();
          activeByHour[hour] = (activeByHour[hour] ?? 0) + 1;
        }
        if (customerId.isNotEmpty) {
          customerOrderCount[customerId] =
              (customerOrderCount[customerId] ?? 0) + 1;
          uniqueCustomers.add(customerId);
        }
      }
      final repeatCustomers = customerOrderCount.entries
          .where((e) => e.value > 1)
          .map((e) => e.key)
          .toSet();
      final repeatRate = uniqueCustomers.isEmpty
          ? 0.0
          : repeatCustomers.length / uniqueCustomers.length;

      // Top category from products
      final categoryCount = <String, int>{};
      for (final doc in productsQuery.docs) {
        final cat = doc.data()['category'] as String? ?? 'other';
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      }
      final topCategory = categoryCount.isEmpty
          ? 'furniture'
          : (categoryCount.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value)))
                .first
                .key;

      // AI-powered insights (rule-based, no external call)
      final insights = _generateInsights(topProducts, lowProducts, repeatRate);

      return ShopAnalyticsModel(
        totalViews: totalViews,
        totalOrders: ordersQuery.docs.length,
        totalRevenueLKR: totalRevenue,
        avgRating: avgRating,
        salesOverTime: salesOverTime,
        topProducts: topProducts,
        lowProducts: lowProducts,
        customerBehavior: CustomerBehavior(
          activeByHour: activeByHour,
          topViewedCategory: topCategory,
          repeatCustomerRate: repeatRate,
        ),
        aiInsights: insights,
      );
    } on FirebaseException catch (e) {
      debugPrint(
        '[ShopService.getShopAnalytics] FirebaseException: ${e.message}',
      );
      rethrow;
    } catch (e) {
      debugPrint('[ShopService.getShopAnalytics] Unexpected error: $e');
      rethrow;
    }
  }

  List<String> _generateInsights(
    List<TopProduct> top,
    List<TopProduct> low,
    double repeatRate,
  ) {
    final insights = <String>[];
    if (top.isNotEmpty) {
      insights.add(
        '"${top.first.name}" is your top seller - consider restocking soon.',
      );
    }
    if (low.isNotEmpty) {
      insights.add(
        'Lowering the price on "${low.first.name}" could improve sales.',
      );
    }
    if (repeatRate > 0.3) {
      insights.add(
        'Great repeat customer rate! Reward loyal buyers with a promo code.',
      );
    }
    insights.add('Post new products around 8 PM for maximum visibility.');
    return insights;
  }

  // ─── Orders Summary ───────────────────────────────────────────────────────

  /// Streams real-time order counts for the seller dashboard summary widget.
  Stream<Map<String, int>> watchOrderSummary(String shopId) {
    return _db
        .collection(FirestorePaths.orders)
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((query) {
          int all = 0, pending = 0, shipped = 0, cancelled = 0;
          for (final doc in query.docs) {
            all++;
            final status = doc.data()['status'] as String? ?? '';
            if (status == 'pending' || status == 'confirmed') pending++;
            if (status == 'shipped' || status == 'delivered') shipped++;
            if (status == 'cancelled') cancelled++;
          }
          return {
            'all': all,
            'pending': pending,
            'shipped': shipped,
            'cancelled': cancelled,
          };
        });
  }

  /// Streams a real-time list of orders for this shop, newest first.
  Stream<List<Map<String, dynamic>>> watchShopOrders(
    String shopId, {
    String? statusFilter,
  }) {
    Query query = _db
        .collection(FirestorePaths.orders)
        .where('shopId', isEqualTo: shopId);
    if (statusFilter != null && statusFilter != 'all') {
      query = query.where('status', isEqualTo: statusFilter);
    }
    return query.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => {...d.data() as Map<String, dynamic>, 'orderId': d.id})
          .toList();

      // Sort in-memory instead of orderBy to bypass index requirements
      list.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }
}
