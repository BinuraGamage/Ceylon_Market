import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/custom_request_model.dart';
import '../models/custom_request_message_model.dart';
import '../providers/product_provider.dart';

final customerCustomRequestsProvider =
    StreamProvider.family<List<CustomRequestModel>, String>((ref, customerId) {
      return ref
          .read(firestoreServiceProvider)
          .watchCustomRequestsForCustomer(customerId);
    });

final shopCustomRequestsProvider =
    StreamProvider.family<List<CustomRequestModel>, String>((ref, shopId) {
      return ref
          .read(firestoreServiceProvider)
          .watchCustomRequestsForShop(shopId);
    });

final designerCustomRequestsProvider =
    StreamProvider.family<List<CustomRequestModel>, String>((ref, designerId) {
      return ref
          .read(firestoreServiceProvider)
          .watchCustomRequestsForDesigner(designerId);
    });

final customRequestByIdProvider =
    StreamProvider.family<CustomRequestModel, String>((ref, requestId) {
      return ref
          .read(firestoreServiceProvider)
          .watchCustomRequestById(requestId);
    });

final customRequestMessagesProvider =
    StreamProvider.family<List<CustomRequestMessageModel>, String>((
      ref,
      requestId,
    ) {
      return ref
          .read(firestoreServiceProvider)
          .watchCustomRequestMessages(requestId);
    });

class CustomizationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    return;
  }

  Future<void> submitCustomizationRequest({
    required CustomRequestModel request,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(firestoreServiceProvider).createCustomRequest(request);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> submitInquiryRequest({
    required CustomRequestModel request,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(firestoreServiceProvider).createCustomRequest(request);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
    String? designerId,
    String? shopId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateCustomRequestStatus(
            requestId: requestId,
            status: status,
            designerId: designerId,
            shopId: shopId,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> sendRequestMessage({
    required String requestId,
    required CustomRequestMessageModel message,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(firestoreServiceProvider)
          .addCustomRequestMessage(requestId: requestId, message: message);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> attachArModelToProduct({
    required String productId,
    required String modelUrl,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateProduct(
            productId: productId,
            updates: {'isAREnabled': true, 'arModelUrl': modelUrl},
          );
      ref.invalidate(productProvider(productId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final customizationNotifierProvider =
    AsyncNotifierProvider<CustomizationNotifier, void>(
      CustomizationNotifier.new,
    );

final shopSuggestionsProvider =
    FutureProvider.family<List<dynamic>, List<String>>((ref, tags) async {
      return ref
          .read(firestoreServiceProvider)
          .suggestShopsForInquiry(productTags: tags);
    });
