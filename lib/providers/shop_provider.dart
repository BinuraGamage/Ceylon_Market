import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/shop_model.dart';
import '../models/shop_analytics_model.dart';
import '../services/shop_service.dart';
import '../../providers/auth_provider.dart'; // M1 owns this — coordinate before editing

// ─── Service Provider ─────────────────────────────────────────────────────

final shopServiceProvider = Provider<ShopService>((ref) => ShopService.instance);

// ─── Shop Analytics Service (M2 integration contract — AGENTS.md §9) ─────
// TODO: Coordinate with M2 — they call shopAnalyticsServiceProvider.recordProductView
final shopAnalyticsServiceProvider = Provider<ShopService>((ref) => ShopService.instance);

// ─── Current Seller's Shop ────────────────────────────────────────────────

/// Real-time stream of the current logged-in seller's shop.
final myShopProvider = StreamProvider<ShopModel?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.read(shopServiceProvider).watchShopByOwner(uid);
});

/// One-off fetch of a shop by shopId (for store room / public view).
final shopByIdProvider = FutureProvider.family<ShopModel?, String>((ref, shopId) async {
  return ref.read(shopServiceProvider).getShop(shopId);
});

// ─── Order Summary Stream ─────────────────────────────────────────────────

final orderSummaryProvider = StreamProvider<Map<String, int>>((ref) {
  final shopAsync = ref.watch(myShopProvider);
  return shopAsync.when(
    data: (shop) {
      if (shop == null) return Stream.value({'all': 0, 'pending': 0, 'shipped': 0, 'cancelled': 0});
      return ref.read(shopServiceProvider).watchOrderSummary(shop.shopId);
    },
    loading: () => Stream.value({'all': 0, 'pending': 0, 'shipped': 0, 'cancelled': 0}),
    error: (_, __) => Stream.value({'all': 0, 'pending': 0, 'shipped': 0, 'cancelled': 0}),
  );
});

// ─── Order List Stream ────────────────────────────────────────────────────

/// Currently selected order filter tab on the dashboard.
final orderFilterProvider = StateProvider<String>((ref) => 'all');

final shopOrdersProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final shopAsync = ref.watch(myShopProvider);
  final filter = ref.watch(orderFilterProvider);
  return shopAsync.when(
    data: (shop) {
      if (shop == null) return Stream.value([]);
      return ref.read(shopServiceProvider).watchShopOrders(shop.shopId, statusFilter: filter);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// ─── Analytics Provider ───────────────────────────────────────────────────

final analyticsRangeProvider = StateProvider<String>((ref) => 'weekly'); // 'weekly' | 'monthly'

final shopAnalyticsProvider = FutureProvider<ShopAnalyticsModel>((ref) async {
  final shopAsync = await ref.read(myShopProvider.future);
  if (shopAsync == null) return ShopAnalyticsModel.empty();
  return ref.read(shopServiceProvider).getShopAnalytics(shopAsync.shopId);
});

// ─── Seller Registration Notifier ────────────────────────────────────────

class SellerRegistrationState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const SellerRegistrationState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SellerRegistrationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) =>
      SellerRegistrationState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

class SellerRegistrationNotifier extends Notifier<SellerRegistrationState> {
  @override
  SellerRegistrationState build() => const SellerRegistrationState();

  Future<void> submit({
    required String shopName,
    required String story,
    required List<String> categories,
    required String address,
    required String city,
    required String? contactPhone,
    required String? contactEmail,
    File? logoFile,
    File? bannerFile,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) throw Exception('User not authenticated');

      // Create a placeholder shop doc first to get a shopId
      final shopId = await ref.read(shopServiceProvider).createShop(
            ShopModel(
              shopId: '', // Will be replaced by Firestore doc ID
              ownerId: uid,
              name: shopName,
              story: story,
              categories: categories,
              location: const GeoPoint(6.9271, 79.8612), // Default: Colombo
              address: address,
              city: city,
              contactPhone: contactPhone,
              contactEmail: contactEmail,
              avgRating: 0,
              reviewCount: 0,
              status: 'pending',
              createdAt: DateTime.now(),
            ),
          );

      // Upload images if provided
      if (logoFile != null) {
        final logoUrl =
            await ref.read(shopServiceProvider).uploadLogo(shopId, logoFile);
        await ref.read(shopServiceProvider).updateShop(shopId, {'logoUrl': logoUrl});
      }
      if (bannerFile != null) {
        final bannerUrl =
            await ref.read(shopServiceProvider).uploadBanner(shopId, bannerFile);
        await ref.read(shopServiceProvider).updateShop(shopId, {'bannerUrl': bannerUrl});
      }

      // Update user role to 'seller'
      // TODO: Coordinate with M1 — they own auth_service.dart and user role updates
      state = state.copyWith(isLoading: false, isSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final sellerRegistrationProvider =
    NotifierProvider<SellerRegistrationNotifier, SellerRegistrationState>(
  SellerRegistrationNotifier.new,
);