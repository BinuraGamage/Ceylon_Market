import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import 'auth_provider.dart';
import 'product_provider.dart' show firestoreServiceProvider;

// ── User Orders Stream Provider ───────────────────────────────────────────
final userOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.value?.uid == null) {
    return Stream.value([]);
  }
  return ref.watch(firestoreServiceProvider).watchUserOrders(authState.value!.uid);
});

final shopOrdersProviderOrder = StreamProvider.family<List<OrderModel>, String>((ref, shopId) {
  return ref.watch(firestoreServiceProvider).watchShopOrders(shopId);
});

// ── Order Notifier — handles order operations ────────────────────────────
class OrderNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> createOrder(OrderModel order) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() =>
      ref.read(firestoreServiceProvider).createOrder(order),
    );
    state = result;
    return result.value ?? '';
  }

  Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(firestoreServiceProvider).updateOrderStatus(
        orderId: orderId,
        status: status,
      ),
    );
  }

  Future<void> updatePaymentStatus({
    required String orderId,
    required String paymentStatus,
    String? paymentRef,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(firestoreServiceProvider).updatePaymentStatus(
        orderId: orderId,
        paymentStatus: paymentStatus,
        paymentRef: paymentRef,
      ),
    );
  }
}

final orderNotifierProvider = AsyncNotifierProvider<OrderNotifier, void>(OrderNotifier.new);